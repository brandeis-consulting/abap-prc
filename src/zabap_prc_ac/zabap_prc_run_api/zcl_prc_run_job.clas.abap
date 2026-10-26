"! <p class="shorttext synchronized">Job abstract class for Run pattern</p>
"!
"! An application job that creates and processes the objects of one process as
"! a run. A job implements SELECT (which objects), GET_PROCESS (which process)
"! and GET_APPLICATION_NAME; everything else is done here: run, total number,
"! creating the objects, synchronous processing, closing the run.
"!
"! The job is its own LUW: run, total number and result are committed on the way.
"! Entry point is IF_APJ_RT_EXEC_OBJECT~EXECUTE - for application jobs as well as
"! for tests and classruns.
"!
"! A run is finished when all its objects have been processed - successfully or
"! not. The result per object shows in the numbers of errors and successes.
"! If the run job itself cannot continue, ABORT_RUN stops it: the reason goes to
"! the application log (external ID = run UUID) and to the run (status aborted),
"! and the job ends with CX_APJ_RT_CONTENT.
"!
"! <h2>Selection</h2>
"! SELECT gets the select options and parameter values of the job. Read a
"! select option with GET_RANGE into a range typed like the field it selects,
"! so the selection is type-safe. Values are taken over by assignment, without
"! conversion exit: type the job parameter with its data element
"! (COMPONENT_TYPE in GET_PARAMETERS), so the application job converts the
"! input, e.g. ALPHA.
CLASS zcl_prc_run_job DEFINITION
  PUBLIC
  ABSTRACT
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_apj_dt_exec_object ALL METHODS ABSTRACT.
    INTERFACES if_apj_rt_exec_object.

    TYPES ty_string_range TYPE RANGE OF string.
    TYPES: BEGIN OF ty_select_option,
             name   TYPE zif_prc_run=>ty_run_parameter,
             ranges TYPE ty_string_range,
           END OF ty_select_option,
           tt_select_options TYPE SORTED TABLE OF ty_select_option WITH UNIQUE KEY name.
    TYPES: BEGIN OF ty_parameter_value,
             name  TYPE zif_prc_run=>ty_run_parameter,
             value TYPE string,
           END OF ty_parameter_value,
           tt_parameter_values TYPE SORTED TABLE OF ty_parameter_value WITH UNIQUE KEY name.
    TYPES: BEGIN OF ty_process,
             name          TYPE zprc_process_name,
             factory_class TYPE zprc_process_impl_class,
           END OF ty_process.
    " One object to process; run and process are added by the framework
    TYPES: BEGIN OF ty_object,
             id                    TYPE za_prc_createprocessedobject-processedobject,
             uuid                  TYPE za_prc_createprocessedobject-processedobjectuuid,
             payload_json          TYPE za_prc_createprocessedobject-payloadjson,
             queue_id              TYPE za_prc_createprocessedobject-queueid,
             queue_position        TYPE za_prc_createprocessedobject-queueposition,
             do_not_process_before TYPE za_prc_createprocessedobject-donotprocessbefore,
           END OF ty_object,
           tt_objects TYPE STANDARD TABLE OF ty_object WITH EMPTY KEY.

  PROTECTED SECTION.
    "! The objects of this run. Call ABORT_RUN to stop the run with a reason.
    "!
    "! @parameter i_select_options   | Select options of the job, by name.
    "! @parameter i_parameter_values | Parameter values of the job, by name.
    "! @parameter r_objects          | Objects to create and process.
    "! @raising   cx_apj_rt_content  | Run aborted (ABORT_RUN).
    METHODS select ABSTRACT IMPORTING i_select_options   TYPE tt_select_options
                                      i_parameter_values TYPE tt_parameter_values
                            RETURNING VALUE(r_objects)   TYPE tt_objects
                            RAISING   cx_apj_rt_content.

    "! The one process all objects of this job belong to.
    "!
    "! @parameter r_process | Process name and process class.
    METHODS get_process ABSTRACT RETURNING VALUE(r_process) TYPE ty_process.

    METHODS get_application_name ABSTRACT RETURNING VALUE(rv_application_name) TYPE zprc_run_app_name.

    "! Fills a typed range from a select option; empty (= all) if not supplied.
    "! Values are taken over by assignment, without conversion exit.
    "!
    "! @parameter i_select_options | Select options as passed to SELECT.
    "! @parameter i_name           | Name of the select option.
    "! @parameter e_range          | Range typed like the field it selects.
    CLASS-METHODS get_range IMPORTING i_select_options TYPE tt_select_options
                                      i_name           TYPE zif_prc_run=>ty_run_parameter
                            EXPORTING e_range          TYPE ANY TABLE.

    "! Send a notification when the run has ended (process PRC_RUN_COMPLETED).
    "! Default: always. Redefine to switch it off; later from the process configuration (Nr. 18).
    "!
    "! @parameter r_notify | ABAP_TRUE to notify the user who started the run.
    METHODS notify_on_completion RETURNING VALUE(r_notify) TYPE abap_bool.

    "! Stops the run job: discards open changes, writes the reason to the
    "! application log (external ID = run UUID, without run the application name)
    "! and to the run (status aborted), and raises CX_APJ_RT_CONTENT with it.
    "!
    "! @parameter i_message         | Reason, e.g. a message of class ZPRC_RUN.
    "! @raising   cx_apj_rt_content | Always.
    METHODS abort_run FINAL IMPORTING i_message TYPE symsg
                            RAISING   cx_apj_rt_content.

  PRIVATE SECTION.
    CONSTANTS co_message_class TYPE symsgid VALUE 'ZPRC_RUN'.

    DATA mv_current_run_uuid TYPE sysuuid_x16.
    DATA mt_parameter_values TYPE tt_parameter_values.
    DATA mt_select_options   TYPE tt_select_options.

    METHODS _execute                     IMPORTING it_parameters TYPE zif_prc_processing_engine=>tt_parameters
                                         RAISING   cx_apj_rt_content.
    METHODS _create_and_process          IMPORTING i_objects TYPE tt_objects
                                         RAISING   cx_apj_rt_content.
    METHODS _finalize_run                RAISING   cx_apj_rt_content.
    METHODS _initialize_parameter_values IMPORTING it_parameters TYPE zif_prc_processing_engine=>tt_parameters
                                         RAISING   cx_apj_rt_content.
    METHODS _initialize_run              IMPORTING it_parameters TYPE zif_prc_processing_engine=>tt_parameters
                                         RAISING   cx_apj_rt_content.
    METHODS _set_total_number            IMPORTING iv_number TYPE int8
                                         RAISING   cx_apj_rt_content.
    METHODS _notify_run_completed.

    "! Message of class ZPRC_RUN with the run UUID or other values as variables.
    METHODS _message IMPORTING i_number         TYPE symsgno
                               i_v1             TYPE simple OPTIONAL
                               i_v2             TYPE simple OPTIONAL
                               i_v3             TYPE simple OPTIONAL
                     RETURNING VALUE(r_message) TYPE symsg.
ENDCLASS.



CLASS zcl_prc_run_job IMPLEMENTATION.


  METHOD if_apj_rt_exec_object~execute.
    _execute( it_parameters ).
  ENDMETHOD.


  METHOD _execute.
    _initialize_parameter_values( it_parameters ).
    _initialize_run( it_parameters ).
    _create_and_process( select( i_select_options   = mt_select_options
                                 i_parameter_values = mt_parameter_values ) ).
    _finalize_run( ).
    IF notify_on_completion( ) = abap_true.
      _notify_run_completed( ).
    ENDIF.
  ENDMETHOD.


  METHOD _create_and_process.
    _set_total_number( lines( i_objects ) ).

    DATA(process) = get_process( ).
    zcl_prc_processing_api=>get_instance( )->create_processed_objects(
        i_create_processed_objects = VALUE #( FOR o IN i_objects
                                              ( processedObject     = o-id
                                                processedObjectUUID = o-uuid
                                                payloadJson         = o-payload_json
                                                queueID             = o-queue_id
                                                queuePosition       = o-queue_position
                                                doNotProcessBefore  = o-do_not_process_before
                                                runUUID             = mv_current_run_uuid
                                                processName         = process-name
                                                factoryClassName    = process-factory_class ) )
        i_perform_commit           = abap_true
        i_trigger_processing       = zcl_prc_processing_api=>execution_mode-direct_execution ).
  ENDMETHOD.


  METHOD get_range.
    CLEAR e_range.
    DATA(option) = VALUE #( i_select_options[ name = i_name ] OPTIONAL ).
    DATA line TYPE REF TO data.
    CREATE DATA line LIKE LINE OF e_range.
    ASSIGN line->* TO FIELD-SYMBOL(<line>).
    LOOP AT option-ranges INTO DATA(range_line).
      CLEAR <line>.
      MOVE-CORRESPONDING range_line TO <line>.
      INSERT <line> INTO TABLE e_range.
    ENDLOOP.
  ENDMETHOD.


  METHOD _initialize_parameter_values.
    if_apj_dt_exec_object~get_parameters( IMPORTING et_parameter_def = DATA(lt_parameter_def) ).
    LOOP AT it_parameters INTO DATA(ls_parameter).
      READ TABLE lt_parameter_def WITH KEY selname = ls_parameter-selname INTO DATA(ls_parameter_def).
      IF sy-subrc <> 0.
        " Parameter &1 is not defined in job &2
        abort_run( _message( i_number = '001' i_v1 = ls_parameter-selname i_v2 = get_application_name( ) ) ).
      ENDIF.
      IF ls_parameter_def-kind = 'S'.
        ASSIGN mt_select_options[ name = ls_parameter_def-selname ] TO FIELD-SYMBOL(<fs_select_option>).
        IF sy-subrc <> 0.
          INSERT VALUE #( name = ls_parameter_def-selname ) INTO TABLE mt_select_options ASSIGNING <fs_select_option>.
        ENDIF.
        APPEND INITIAL LINE TO <fs_select_option>-ranges ASSIGNING FIELD-SYMBOL(<fs_range>).
        MOVE-CORRESPONDING ls_parameter TO <fs_range>.
      ELSEIF ls_parameter_def-kind = 'P'.
        INSERT VALUE #( name  = ls_parameter-selname
                        value = ls_parameter-low ) INTO TABLE mt_parameter_values.
      ELSE.
        " Unexpected parameter kind &1 for parameter &2 in job &3
        abort_run( _message( i_number = '002' i_v1 = ls_parameter_def-kind i_v2 = ls_parameter-selname
                             i_v3 = get_application_name( ) ) ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD _finalize_run.
    GET TIME STAMP FIELD DATA(lv_timestamp).
    " Severity of the run is derived from its objects (ZR_PRC_RunProgress), not set here
    MODIFY ENTITIES OF ZR_PRC_RunTP PRIVILEGED
           ENTITY run
           UPDATE FIELDS ( ExecutionStatus JobEnd )
           WITH VALUE #( ( %key-uuid       = mv_current_run_uuid
                           ExecutionStatus = zif_prc_run=>co_execution_status-finished
                           JobEnd          = lv_timestamp ) )
           FAILED DATA(failed)
           REPORTED DATA(reported) ##NEEDED.
    IF failed IS NOT INITIAL.
      " Unexpected error while finishing run &1
      abort_run( _message( i_number = '007' i_v1 = mv_current_run_uuid ) ).
    ENDIF.
    " The run job is its own LUW (application job)
    COMMIT ENTITIES RESPONSES FAILED DATA(ls_failed) REPORTED DATA(ls_reported) ##NEEDED.
    IF sy-subrc <> 0 OR ls_failed IS NOT INITIAL.
      abort_run( _message( i_number = '007' i_v1 = mv_current_run_uuid ) ).
    ENDIF.
  ENDMETHOD.


  METHOD _initialize_run.
    DATA lv_param_counter TYPE i.

    TRY.
        cl_apj_rt_api=>get_job_runtime_info( IMPORTING ev_jobname  = DATA(lv_job_id)
                                                       ev_jobcount = DATA(lv_job_count) ).
        DATA(ls_job_details) = cl_apj_rt_api=>get_job_details( lv_job_id ).
      CATCH cx_apj_rt ##NO_HANDLER.
        " happens if run is called without application job (tests, classruns)
    ENDTRY.

    GET TIME STAMP FIELD DATA(lv_timestamp).

    DATA lt_parameter TYPE TABLE FOR CREATE ZR_PRC_RunTP\_Parameter.

    READ TABLE it_parameters INTO DATA(ls_uuid_parameter) WITH KEY selname = zif_prc_run=>co_parameter-p_uuid.
    IF sy-subrc = 0 AND ls_uuid_parameter-low IS NOT INITIAL.
      DATA(lv_update_Scenario) = abap_true.
      mv_current_run_uuid = ls_uuid_parameter-low.
    ELSE.
      DATA(lv_cid) = 'CID'.
    ENDIF.

    LOOP AT it_parameters INTO DATA(ls_parameter) WHERE selname <> zif_prc_run=>co_parameter-p_uuid.
      lv_param_counter += 1.
      APPEND VALUE #( %cid_ref = lv_cid
                      uuid     = mv_current_run_uuid
                      %target  = VALUE #( ( %cid          = |CID{ lv_param_counter }|
                                            ParameterName = ls_parameter-selname
                                            Operator      = ls_parameter-option
                                            Sign          = ls_parameter-sign
                                            Low           = ls_parameter-low
                                            High          = ls_parameter-high ) ) )
             TO lt_parameter.
    ENDLOOP.

    " The run is maintained technically by the framework: privileged access,
    " the job user does not need authorizations for ZPRC_RUN. The severity of the
    " run is derived from its objects (ZR_PRC_RunProgress), not set here.
    IF lv_update_Scenario = abap_true.

      " ApplicationName is readonly on update, it was already set by initiateRun
      MODIFY ENTITIES OF ZR_PRC_RunTP PRIVILEGED
             ENTITY Run
             UPDATE FIELDS ( JobName JobCount JobID JobStart ExecutionStatus CreatedBy )
             WITH VALUE #( ( uuid            = mv_current_run_uuid
                             JobID           = lv_job_id
                             JobCount        = lv_job_count
                             JobName         = ls_job_details-job_text
                             JobStart        = lv_timestamp
                             ExecutionStatus = zif_prc_run=>co_execution_status-started
                             CreatedBy       = sy-uname ) )
             CREATE BY \_Parameter FIELDS ( ParameterName Operator Sign Low High )
             WITH lt_parameter
             FAILED DATA(failed)
             REPORTED DATA(reported) ##NEEDED
             MAPPED DATA(mapped) ##NEEDED.
      IF failed IS NOT INITIAL.
        " Unexpected error while updating run &1
        abort_run( _message( i_number = '003' i_v1 = mv_current_run_uuid ) ).
      ENDIF.
    ELSE. " create new entry
      MODIFY ENTITIES OF ZR_PRC_RunTP PRIVILEGED
             ENTITY Run
             CREATE FIELDS ( ApplicationName JobName JobCount JobID JobStart ExecutionStatus CreatedBy )
             WITH VALUE #( ( %cid            = lv_cid
                             ApplicationName = get_application_name( )
                             JobID           = lv_job_id
                             JobCount        = lv_job_count
                             JobName         = ls_job_details-job_text
                             JobStart        = lv_timestamp
                             ExecutionStatus = zif_prc_run=>co_execution_status-started
                             CreatedBy       = sy-uname ) )
             CREATE BY \_Parameter FIELDS ( ParameterName Operator Sign Low High )
             WITH lt_parameter
             FAILED DATA(create_failed)
             REPORTED DATA(create_reported) ##NEEDED
             MAPPED DATA(create_mapped).
      IF create_failed IS NOT INITIAL.
        " Unexpected error while creating the run of job &1
        abort_run( _message( i_number = '004' i_v1 = get_application_name( ) ) ).
      ENDIF.
      mv_current_run_uuid = create_mapped-run[ 1 ]-uuid.
    ENDIF.
    " The run job is its own LUW (application job)
    COMMIT ENTITIES RESPONSES FAILED DATA(ls_failed).
    IF sy-subrc <> 0 OR ls_failed IS NOT INITIAL.
      " Unexpected error while saving run &1 (the run does not exist then)
      DATA(lv_run) = mv_current_run_uuid.
      CLEAR mv_current_run_uuid.
      abort_run( _message( i_number = '005' i_v1 = lv_run ) ).
    ENDIF.
    ROLLBACK ENTITIES.
  ENDMETHOD.

  METHOD _set_total_number.
    MODIFY ENTITIES OF ZR_PRC_RunTP PRIVILEGED
           ENTITY Run
           UPDATE FIELDS ( TotalNumber )
           WITH VALUE #( ( %key-uuid   = mv_current_run_uuid
                           TotalNumber = iv_number ) )
           FAILED DATA(update_failed)
           REPORTED DATA(update_reported) ##NEEDED.
    IF update_failed IS NOT INITIAL.
      " Unexpected error while saving the total number of run &1
      abort_run( _message( i_number = '006' i_v1 = mv_current_run_uuid ) ).
    ENDIF.

    COMMIT ENTITIES RESPONSES FAILED DATA(failed) REPORTED DATA(reported) ##NEEDED.
    IF sy-subrc <> 0 OR failed IS NOT INITIAL.
      abort_run( _message( i_number = '006' i_v1 = mv_current_run_uuid ) ).
    ENDIF.
    ROLLBACK ENTITIES.
  ENDMETHOD.

  METHOD notify_on_completion.
    r_notify = abap_true.
  ENDMETHOD.

  METHOD _notify_run_completed.
    " Own processed object (process PRC_RUN_COMPLETED): reading the result, the
    " mail address and sending run with log, retry and resume
    SELECT SINGLE FROM ZI_PRC_Run WITH PRIVILEGED ACCESS
      FIELDS ApplicationName, JobStart
      WHERE UUID = @mv_current_run_uuid
      INTO @DATA(ls_run).

    zcl_prc_processing_api=>get_instance( )->create_processed_objects(
        i_create_processed_objects = zcl_prc_notif_run_proc=>create_notification(
                                         i_run_uuid         = mv_current_run_uuid
                                         i_application_name = ls_run-ApplicationName
                                         i_job_start        = ls_run-JobStart )
        i_perform_commit           = abap_true
        i_trigger_processing       = zcl_prc_processing_api=>execution_mode-direct_execution ).
  ENDMETHOD.


  METHOD _message.
    r_message = VALUE #( msgid = co_message_class
                         msgno = i_number
                         msgv1 = |{ i_v1 }|
                         msgv2 = |{ i_v2 }|
                         msgv3 = |{ i_v3 }| ).
  ENDMETHOD.


  METHOD abort_run.
    " Nothing half-done is saved
    ROLLBACK ENTITIES.

    " Application log: own database connection, independent of the LUW;
    " same retention as the processed data (cleanup job)
    TRY.
        DATA(lv_expiry) = CONV d( cl_abap_context_info=>get_system_date( ) + zcl_prc_cleanup_job=>co_default_days ).
        DATA(lo_log) = cl_bali_log=>create_with_header(
                           cl_bali_header_setter=>create(
                               object      = zcl_prc_step_log=>co_log_object
                               subobject   = zcl_prc_step_log=>co_log_subobject
                               external_id = COND #( WHEN mv_current_run_uuid IS NOT INITIAL
                                                     THEN |{ mv_current_run_uuid }|
                                                     ELSE get_application_name( ) )
                             )->set_expiry( expiry_date = lv_expiry keep_until_expiry = abap_true ) ).
        lo_log->add_item( cl_bali_message_setter=>create( severity   = if_bali_constants=>c_severity_error
                                                          id         = i_message-msgid
                                                          number     = i_message-msgno
                                                          variable_1 = i_message-msgv1
                                                          variable_2 = i_message-msgv2
                                                          variable_3 = i_message-msgv3
                                                          variable_4 = i_message-msgv4 ) ).
        cl_bali_log_db=>get_instance( )->save_log_2nd_db_connection( log = lo_log ).
      CATCH cx_bali_runtime ##NO_HANDLER.
        " the reason still reaches the run and the job log
    ENDTRY.

    " Run: aborted, with the reason (shown in the logon language)
    IF mv_current_run_uuid IS NOT INITIAL.
      MESSAGE ID i_message-msgid TYPE 'E' NUMBER i_message-msgno
              WITH i_message-msgv1 i_message-msgv2 i_message-msgv3 i_message-msgv4
              INTO DATA(lv_text).
      GET TIME STAMP FIELD DATA(lv_timestamp).
      MODIFY ENTITIES OF ZR_PRC_RunTP PRIVILEGED
             ENTITY Run
             UPDATE FIELDS ( ExecutionStatus JobEnd MessageClass MessageNumber MessageVariable1
                             MessageVariable2 MessageVariable3 MessageVariable4 MessageText )
             WITH VALUE #( ( %key-uuid        = mv_current_run_uuid
                             ExecutionStatus  = zif_prc_run=>co_execution_status-aborted
                             JobEnd           = lv_timestamp
                             MessageClass     = i_message-msgid
                             MessageNumber    = i_message-msgno
                             MessageVariable1 = i_message-msgv1
                             MessageVariable2 = i_message-msgv2
                             MessageVariable3 = i_message-msgv3
                             MessageVariable4 = i_message-msgv4
                             MessageText      = lv_text ) )
             FAILED DATA(failed) ##NEEDED
             REPORTED DATA(reported) ##NEEDED.
      COMMIT ENTITIES.
    ENDIF.

    RAISE EXCEPTION TYPE cx_apj_rt_content
          MESSAGE ID i_message-msgid TYPE 'E' NUMBER i_message-msgno
          WITH i_message-msgv1 i_message-msgv2 i_message-msgv3 i_message-msgv4.
  ENDMETHOD.
ENDCLASS.
