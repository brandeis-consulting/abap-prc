CLASS lhc_Run DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PUBLIC SECTION.
    CLASS-DATA: gt_trigger_se_events_for TYPE STANDARD TABLE OF sysuuid_x16 WITH DEFAULT KEY.

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

CLASS zbp_prc_run DEFINITION LOCAL FRIENDS lhc_run.

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

    LOOP AT keys INTO DATA(key).
      CLEAR lt_parameter.
      /ui2/cl_json=>deserialize( EXPORTING json = key-%param-selectOptionString
                                 CHANGING  data = lt_parameter ).

      " Check before the run exists (Nr. 40.9): the save phase can no longer change the run,
      " so a run whose job cannot be scheduled would stay "planned" forever
      DATA(ls_error) = VALUE symsg( ).
      TRY.
          IF cl_apj_rt_api=>can_schedule_job( iv_job_template_name = CONV #( key-%param-jobTemplateName ) ) = abap_false.
            " Job template &1 does not exist or you are not authorized to schedule it
            ls_error = VALUE #( msgid = 'ZPRC_RUN' msgno = '010' msgv1 = key-%param-jobTemplateName ).
          ELSE.
            DATA(lt_template_parameter) = cl_apj_rt_api=>get_template_param_values(
                                              iv_job_template_name = CONV #( key-%param-jobTemplateName ) ).
            " P_UUID is added by the framework below
            LOOP AT lt_parameter INTO DATA(ls_parameter) WHERE name <> zif_prc_run=>co_parameter-p_uuid.
              IF NOT line_exists( lt_template_parameter[ name = ls_parameter-name ] ).
                " Parameter &1 is not defined in job &2
                ls_error = VALUE #( msgid = 'ZPRC_RUN' msgno = '001'
                                    msgv1 = ls_parameter-name msgv2 = key-%param-jobTemplateName ).
                EXIT.
              ENDIF.
            ENDLOOP.
          ENDIF.
        CATCH cx_apj_rt.
          " Job template &1 does not exist or you are not authorized to schedule it
          ls_error = VALUE #( msgid = 'ZPRC_RUN' msgno = '010' msgv1 = key-%param-jobTemplateName ).
      ENDTRY.

      IF ls_error IS INITIAL.
        MODIFY ENTITIES OF zr_prc_runtp
               IN LOCAL MODE
               ENTITY Run
               CREATE FIELDS ( ExecutionStatus ApplicationName JobName )
               WITH VALUE #( ( %cid            = key-%cid
                               ExecutionStatus = zif_prc_run=>co_execution_status-planned
                               ApplicationName = key-%param-applicationName
                               JobName         = key-%param-jobName ) )
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
                      parameter         = lt_parameter ) TO zbp_prc_run=>gt_apj_parameters.
    ENDLOOP.
  ENDMETHOD.

  METHOD triggerChangedEvent.
    LOOP AT keys INTO DATA(key).
      APPEND key-uuid TO gt_trigger_se_events_for.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_saver DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save_modified    REDEFINITION.
    METHODS cleanup_finalize REDEFINITION.
ENDCLASS.

CLASS zbp_prc_run DEFINITION LOCAL FRIENDS lsc_saver.

CLASS lsc_saver IMPLEMENTATION.
  METHOD save_modified.
    LOOP AT zbp_prc_run=>gt_apj_parameters INTO DATA(ls_job_params).
      " Only for runs created in this save: entries of a rolled-back initiateRun are dropped
      " (no cleanup method in managed with additional save)
      IF NOT line_exists( create-run[ KEY id uuid = ls_job_params-run_uuid ] ).
        CONTINUE.
      ENDIF.
      TRY.
          " No commit inside: the job becomes visible to the scheduler with the commit
          " of this LUW, together with the run (no race with _initialize_run, Nr. 40.9)
          zcl_prc_job_scheduler=>get( )->schedule_immediately( i_template_name = CONV #( ls_job_params-job_template_name )
                                                               i_job_text      = CONV #( ls_job_params-job_name )
                                                               i_parameters    = ls_job_params-parameter ).
        CATCH cx_apj_rt INTO DATA(lo_exception).
          " Template, authorization and parameters are checked in initiateRun; what is left are
          " technical errors. The run cannot be changed here anymore (the managed save writes it
          " after this method), so it stays "planned" - the caller is told why (Nr. 40.9)
          DATA(lv_text) = lo_exception->get_text( ).
          DATA(lo_previous) = lo_exception->previous.
          WHILE lo_previous IS BOUND.
            lv_text = |{ lv_text } - { lo_previous->get_text( ) }|.
            lo_previous = lo_previous->previous.
          ENDWHILE.
          DATA lv_reason TYPE c LENGTH 150.
          lv_reason = lv_text.
          " Job template &1 could not be scheduled: &2&3&4
          APPEND new_message( id       = 'ZPRC_RUN'
                              number   = '009'
                              severity = if_abap_behv_message=>severity-error
                              v1       = ls_job_params-job_template_name
                              v2       = lv_reason(50)
                              v3       = lv_reason+50(50)
                              v4       = lv_reason+100(50) )
                 TO reported-%other.
      ENDTRY.
    ENDLOOP.
    CLEAR zbp_prc_run=>gt_apj_parameters.

    IF update-run IS NOT INITIAL OR lhc_run=>gt_trigger_se_events_for IS NOT INITIAL.
      TRY.
          DATA lt_run_uuid  TYPE STANDARD TABLE OF zr_prc_runtp-uuid.
          DATA lt_run_uuid2 TYPE STANDARD TABLE OF zr_prc_runtp-uuid.

          lt_run_uuid = VALUE #( FOR k IN update-run
                                 ( k-uuid ) ).
          lt_run_uuid2 = VALUE #( FOR uuid IN lhc_run=>gt_trigger_se_events_for
                                  ( uuid ) ).
          APPEND LINES OF lt_run_uuid2 TO lt_run_uuid.

          CALL METHOD ('ZBP_R_PRC_RUNEXT')=>('RAISE_RUN')
            EXPORTING it_run_uuid = lt_run_uuid.

        CATCH cx_sy_dyn_call_illegal_class
              cx_sy_dyn_call_illegal_method ##NO_HANDLER.
          " nothing to do, the event raiser class is not available in this installation
      ENDTRY.
    ENDIF.
    " Raised once per save: without this, every later save in the session raised them again
    CLEAR lhc_run=>gt_trigger_se_events_for.
  ENDMETHOD.

  METHOD cleanup_finalize.
    CLEAR zbp_prc_run=>gt_apj_parameters.
  ENDMETHOD.

ENDCLASS.
