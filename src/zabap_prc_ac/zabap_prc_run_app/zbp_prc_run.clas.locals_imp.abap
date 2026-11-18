"! Work for the save, collected by the actions. Named like the action that fills it.
"! Cleared by the saver's CLEANUP - after every save and after ROLLBACK ENTITIES,
"! so nothing of a rolled-back LUW reaches a later save in the same session.
CLASS lcl_buffer DEFINITION FINAL.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_initiate_run,
             " Only scheduled if this run is created in the same save
             run_uuid          TYPE sysuuid_x16,
             job_name          TYPE c LENGTH 120,
             job_template_name TYPE zif_prc_run=>ty_job_template_name,
             parameter         TYPE cl_apj_rt_api=>tt_job_parameter_value,
           END OF ty_initiate_run,
           tt_initiate_run TYPE STANDARD TABLE OF ty_initiate_run WITH EMPTY KEY,
           tt_uuids        TYPE STANDARD TABLE OF sysuuid_x16 WITH DEFAULT KEY.

    "! Jobs to schedule in the save, one per run created by initiateRun
    CLASS-DATA initiate_run          TYPE tt_initiate_run.
    "! Runs whose changed event is raised in the save, without a change of their own
    CLASS-DATA trigger_changed_event TYPE tt_uuids.

    CLASS-METHODS clear.
ENDCLASS.


CLASS lcl_buffer IMPLEMENTATION.
  METHOD clear.
    CLEAR: initiate_run, trigger_changed_event.
  ENDMETHOD.
ENDCLASS.


CLASS lhc_Run DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Run RESULT result.
    METHODS precheck_create FOR PRECHECK
      IMPORTING entities FOR CREATE Run.
    METHODS precheck_initiaterun FOR PRECHECK
      IMPORTING keys FOR ACTION Run~initiateRun.
    METHODS initiaterun FOR MODIFY IMPORTING keys FOR ACTION run~initiaterun.
    METHODS triggerChangedEvent FOR MODIFY keys FOR ACTION Run~triggerChangedEvent.
ENDCLASS.

CLASS lhc_Run IMPLEMENTATION.

  METHOD get_instance_authorizations.
    " The framework (run job, processing engine) calls these operations
    " in privileged mode, so the checks only apply to direct callers (UI, EML)
    READ ENTITIES OF zr_prc_runtp IN LOCAL MODE
         ENTITY Run
         FIELDS ( ApplicationName )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_runs)
         FAILED failed.

    LOOP AT keys INTO DATA(key).
      ASSIGN lt_runs[ KEY id
                      uuid = key-uuid ] TO FIELD-SYMBOL(<ls_run>).
      IF sy-subrc <> 0.
        " Instance not readable: deny all requested operations
        APPEND VALUE #( %tky                        = key-%tky
                        %update                     = if_abap_behv=>auth-unauthorized
                        %delete                     = if_abap_behv=>auth-unauthorized
                        %action-triggerChangedEvent = if_abap_behv=>auth-unauthorized )
               TO result.
        CONTINUE.
      ENDIF.

      " Only requested operations are checked, the others stay initial
      APPEND VALUE #(
          %tky                        = key-%tky
          %update                     = COND #( WHEN requested_authorizations-%update = if_abap_behv=>mk-on
                                                THEN zcl_prc_auth_run=>get_behv_authorization(
                                                         i_application_name = <ls_run>-ApplicationName
                                                         i_activity         = zcl_prc_auth_run=>co_activity-change ) )
          %delete                     = COND #( WHEN requested_authorizations-%delete = if_abap_behv=>mk-on
                                                THEN zcl_prc_auth_run=>get_behv_authorization(
                                                         i_application_name = <ls_run>-ApplicationName
                                                         i_activity         = zcl_prc_auth_run=>co_activity-delete ) )
          %action-triggerChangedEvent = COND #( WHEN requested_authorizations-%action-triggerChangedEvent = if_abap_behv=>mk-on
                                                THEN zcl_prc_auth_run=>get_behv_authorization(
                                                         i_application_name = <ls_run>-ApplicationName
                                                         i_activity         = zcl_prc_auth_run=>co_activity-change ) ) )
             TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD precheck_create.
    " Everybody may call create, the application name decides (ZPRC_RUN, activity 01).
    " The framework calls in privileged mode, so the check only applies to direct callers.
    LOOP AT entities INTO DATA(entity).
      IF zcl_prc_auth_run=>is_authorized( i_application_name = entity-ApplicationName
                                          i_activity         = zcl_prc_auth_run=>co_activity-create ) = abap_false.
        APPEND VALUE #( %cid = entity-%cid ) TO failed-run.
        APPEND VALUE #( %cid = entity-%cid
                        %msg = new_message( id       = 'ZPRC_PROCESS_MESSAGE'
                                            number   = '003'
                                            severity = if_abap_behv_message=>severity-error
                                            v1       = entity-ApplicationName ) )
               TO reported-run.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD precheck_initiaterun.
    " Same check as for create, based on the application name of the parameter
    LOOP AT keys INTO DATA(key).
      IF zcl_prc_auth_run=>is_authorized( i_application_name = key-%param-applicationName
                                          i_activity         = zcl_prc_auth_run=>co_activity-create ) = abap_false.
        APPEND VALUE #( %cid = key-%cid ) TO failed-run.
        APPEND VALUE #( %cid = key-%cid
                        %msg = new_message( id       = 'ZPRC_PROCESS_MESSAGE'
                                            number   = '003'
                                            severity = if_abap_behv_message=>severity-error
                                            v1       = key-%param-applicationName ) )
               TO reported-run.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD initiateRun.
    DATA lt_parameter TYPE cl_apj_rt_api=>tt_job_parameter_value.
    DATA lr_template_parameter TYPE REF TO data.
    FIELD-SYMBOLS <lt_template_parameter> TYPE ANY TABLE.

    LOOP AT keys INTO DATA(key).
      CLEAR lt_parameter.
      /ui2/cl_json=>deserialize( EXPORTING json = key-%param-selectOptionString
                                 CHANGING  data = lt_parameter ).

      " Check before the run exists: the save phase can no longer change the run,
      " so a run whose job cannot be scheduled would stay "planned" forever
      DATA(ls_error) = VALUE symsg( ).
      DATA(lv_template_name) = CONV cl_apj_rt_api=>ty_template_name( key-%param-jobTemplateName ).
      TRY.
          IF cl_apj_rt_api=>can_schedule_job( iv_job_template_name = lv_template_name ) = abap_false.
            " Job template &1 does not exist or you are not authorized to schedule it
            ls_error = VALUE #( msgid = 'ZPRC_RUN' msgno = '010' msgv1 = key-%param-jobTemplateName ).
          ELSE.
            " Parameters of the template: GET_TEMPLATE_PARAM_VALUES and its result type do not
            " exist in S/4HANA 2023, so both are addressed dynamically. Without them the check is
            " skipped; an unknown parameter then only fails when the job is scheduled.
            TRY.
                CREATE DATA lr_template_parameter TYPE ('\CLASS=CL_APJ_RT_API\TYPE=TT_TEMPL_PARAM_VAL_MULTISTEP').
                ASSIGN lr_template_parameter->* TO <lt_template_parameter>.
                CALL METHOD ('CL_APJ_RT_API')=>('GET_TEMPLATE_PARAM_VALUES')
                  EXPORTING
                    iv_job_template_name = lv_template_name
                  RECEIVING
                    rt_parameters        = <lt_template_parameter>.

                " P_UUID is added by the framework below
                LOOP AT lt_parameter INTO DATA(ls_parameter) WHERE name <> zif_prc_run=>co_parameter-p_uuid.
                  READ TABLE <lt_template_parameter> WITH KEY ('NAME') = ls_parameter-name TRANSPORTING NO FIELDS.
                  IF sy-subrc <> 0.
                    " Parameter &1 is not defined in job &2
                    ls_error = VALUE #( msgid = 'ZPRC_RUN' msgno = '001'
                                        msgv1 = ls_parameter-name msgv2 = key-%param-jobTemplateName ).
                    EXIT.
                  ENDIF.
                ENDLOOP.
              CATCH cx_sy_create_data_error cx_sy_dyn_call_error ##NO_HANDLER.
                " S/4HANA 2023: no parameter check
            ENDTRY.
          ENDIF.
        CATCH cx_apj_rt.
          " Job template &1 does not exist or you are not authorized to schedule it
          ls_error = VALUE #( msgid = 'ZPRC_RUN' msgno = '010' msgv1 = key-%param-jobTemplateName ).
      ENDTRY.

      IF ls_error IS INITIAL.
        " Simulation is a property of the run: the run job and the processed objects read it
        MODIFY ENTITIES OF zr_prc_runtp
               IN LOCAL MODE
               ENTITY Run
               CREATE FIELDS ( ExecutionStatus ApplicationName JobName Simulation )
               WITH VALUE #( ( %cid            = key-%cid
                               ExecutionStatus = zif_prc_run=>co_execution_status-planned
                               ApplicationName = key-%param-applicationName
                               JobName         = key-%param-jobName
                               Simulation      = key-%param-simulation ) )
               FAILED DATA(ls_failed)
               REPORTED DATA(ls_reported)
               MAPPED DATA(ls_mapped).
        IF ls_failed IS NOT INITIAL OR ls_mapped-run IS INITIAL.
          " The run could not be created for application &1
          ls_error = VALUE #( msgid = 'ZPRC_RUN' msgno = '011' msgv1 = key-%param-applicationName ).
        ENDIF.
      ENDIF.

      IF ls_error IS NOT INITIAL.
        APPEND VALUE #( %cid        = key-%cid
                        %fail-cause = if_abap_behv=>cause-unspecific ) TO failed-run.
        APPEND VALUE #( %cid = key-%cid
                        %msg = new_message( id       = ls_error-msgid
                                            number   = ls_error-msgno
                                            severity = if_abap_behv_message=>severity-error
                                            v1       = ls_error-msgv1
                                            v2       = ls_error-msgv2 ) ) TO reported-run.
        " The cause from the create (e.g. a check), if there is one
        LOOP AT ls_reported-run INTO DATA(ls_cause) WHERE %msg IS BOUND.
          APPEND VALUE #( %cid = key-%cid %msg = ls_cause-%msg ) TO reported-run.
        ENDLOOP.
        CLEAR ls_reported.
        CONTINUE.
      ENDIF.

      " Mapped to the caller's %cid, so a caller can address the new run
      DATA(lv_run_uuid) = ls_mapped-run[ 1 ]-uuid.
      APPEND VALUE #( %cid = key-%cid
                      uuid = lv_run_uuid ) TO mapped-run.

      APPEND VALUE #( name    = zif_prc_run=>co_parameter-p_uuid
                      t_value = VALUE #( ( low = lv_run_uuid sign = 'I' option = 'EQ' ) ) ) TO lt_parameter.

      APPEND VALUE #( run_uuid          = lv_run_uuid
                      job_template_name = key-%param-jobTemplateName
                      job_name          = key-%param-jobName
                      parameter         = lt_parameter ) TO lcl_buffer=>initiate_run.
    ENDLOOP.
  ENDMETHOD.

  METHOD triggerChangedEvent.
    LOOP AT keys INTO DATA(key).
      APPEND key-uuid TO lcl_buffer=>trigger_changed_event.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_saver DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.
    METHODS cleanup       REDEFINITION.
ENDCLASS.

CLASS lsc_saver IMPLEMENTATION.
  METHOD save_modified.
    LOOP AT lcl_buffer=>initiate_run INTO DATA(job).
      " Only for runs created in this save - a second safeguard besides CLEANUP
      " against entries of a rolled-back initiateRun
      IF NOT line_exists( create-run[ KEY id uuid = job-run_uuid ] ).
        CONTINUE.
      ENDIF.
      TRY.
          " No commit inside: the job becomes visible to the scheduler with the commit
          " of this LUW, together with the run (no race with _initialize_run)
          zcl_prc_job_scheduler=>get( )->schedule_immediately( i_template_name = CONV #( job-job_template_name )
                                                               i_job_text      = job-job_name
                                                               i_parameters    = job-parameter ).
        CATCH cx_apj_rt INTO DATA(scheduling_error).
          " Template, authorization and parameters are checked in initiateRun; what is left are
          " technical errors. The run cannot be changed here anymore (the managed save writes it
          " after this method), so it stays "planned" - the caller is told why
          DATA(text) = scheduling_error->get_text( ).
          DATA(previous) = scheduling_error->previous.
          WHILE previous IS BOUND.
            text = |{ text } - { previous->get_text( ) }|.
            previous = previous->previous.
          ENDWHILE.
          DATA reason TYPE c LENGTH 150.
          reason = text.
          " Job template &1 could not be scheduled: &2&3&4
          APPEND new_message( id       = 'ZPRC_RUN'
                              number   = '009'
                              severity = if_abap_behv_message=>severity-error
                              v1       = job-job_template_name
                              v2       = reason(50)
                              v3       = reason+50(50)
                              v4       = reason+100(50) )
                 TO reported-%other.
      ENDTRY.
    ENDLOOP.

    IF update-run IS NOT INITIAL OR lcl_buffer=>trigger_changed_event IS NOT INITIAL.
      TRY.
          " Changed runs plus runs whose event was triggered explicitly.
          " Same type as ZBP_R_PRC_RUNEXT=>TT_UUIDS - the dynamic call needs a compatible table
          DATA event_uuids TYPE STANDARD TABLE OF sysuuid_x16 WITH EMPTY KEY.
          event_uuids = VALUE #( BASE VALUE #( FOR k IN update-run ( k-uuid ) )
                                 FOR uuid IN lcl_buffer=>trigger_changed_event ( uuid ) ).

          " Dynamic: the event raiser exists only from 2025 (package ZABAP_PRC_EVENTS_SE_2025).
          " The parameter name is not checked by the compiler - keep it in sync with the class.
          CALL METHOD ('ZBP_R_PRC_RUNEXT')=>('RAISE_RUN')
            EXPORTING i_uuids = event_uuids.

        CATCH cx_sy_dyn_call_illegal_class
              cx_sy_dyn_call_illegal_method ##NO_HANDLER.
          " nothing to do, the event raiser class is not available in this installation
      ENDTRY.
    ENDIF.
  ENDMETHOD.

  METHOD cleanup.
    " After every save and after ROLLBACK ENTITIES (BDEF: and cleanup). Not in
    " CLEANUP_FINALIZE: that runs after a failed check, although the LUW goes on and a
    " corrected save still needs the jobs of initiateRun.
    lcl_buffer=>clear( ).
  ENDMETHOD.

ENDCLASS.
