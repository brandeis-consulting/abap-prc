CLASS zcl_prc_run_job DEFINITION
  PUBLIC
  ABSTRACT
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_apj_dt_exec_object ALL METHODS ABSTRACT.
    INTERFACES if_apj_rt_exec_object.
    METHODS execute_synchronously IMPORTING it_parameters TYPE if_apj_rt_exec_object=>tt_templ_val.

  PROTECTED SECTION.
    METHODS execute ABSTRACT IMPORTING it_parameters TYPE if_apj_rt_exec_object=>tt_templ_val.

    DATA mv_message_status   TYPE int8 VALUE 0.
    DATA mv_message_text     TYPE string.

    DATA mv_current_run_uuid TYPE sysuuid_x16.
    DATA mv_execution_type   TYPE int8.

    TYPES: BEGIN OF ty_select_options,
             selname TYPE c LENGTH 8,
             ranges  TYPE RANGE OF string,
           END OF ty_select_options.
    TYPES: BEGIN OF ty_parameter_values,
             parameter_name TYPE c LENGTH 8,
             value          TYPE string,
           END OF ty_parameter_values.

    DATA mt_parameter_values      TYPE SORTED TABLE OF ty_parameter_values WITH UNIQUE KEY parameter_name.
    DATA mt_select_options_values TYPE SORTED TABLE OF ty_select_options WITH UNIQUE KEY selname.

    DATA application_log          TYPE REF TO if_bali_log.

    TYPES: BEGIN OF ty_log_info,
             bal_object    TYPE cl_bali_header_setter=>ty_object,
             bal_subobject TYPE cl_bali_header_setter=>ty_subobject,
             external_id   TYPE cl_bali_header_setter=>ty_external_id,
           END OF ty_log_INFO.

    METHODS get_application_name ABSTRACT RETURNING VALUE(rv_application_name) TYPE zprc_run_app_name.
    METHODS set_total_number IMPORTING iv_number TYPE int8.

  PRIVATE SECTION.
    METHODS _execute                     IMPORTING it_parameters TYPE if_apj_rt_exec_object=>tt_templ_val.
    METHODS _finalize_run.
    METHODS _initialize_parameter_values IMPORTING it_parameters TYPE if_apj_rt_exec_object=>tt_templ_val.
    METHODS _initialize_run              IMPORTING it_parameters TYPE if_apj_rt_exec_object=>tt_templ_val.

    DATA mv_run_in_background   TYPE abap_bool VALUE abap_true.
ENDCLASS.



CLASS zcl_prc_run_job IMPLEMENTATION.


  METHOD if_apj_rt_exec_object~execute.
    _execute( it_parameters ).
  ENDMETHOD.


  METHOD _initialize_parameter_values.
    if_apj_dt_exec_object~get_parameters( IMPORTING et_parameter_def = DATA(lt_parameter_def) ).
    LOOP AT it_parameters INTO DATA(ls_parameter).
      READ TABLE lt_parameter_def WITH KEY selname = ls_parameter-selname INTO DATA(ls_parameter_def).
      ASSERT sy-subrc = 0. " provided selname at runtime not defined at design time?
      IF ls_parameter_def-kind = 'S'.
        ASSIGN mt_select_options_values[ selname = ls_parameter_def-selname ] TO FIELD-SYMBOL(<fs_select_option>).
        IF sy-subrc <> 0.
          INSERT VALUE #( selname = ls_parameter_def-selname ) INTO TABLE mt_select_options_values ASSIGNING <fs_select_option>.
        ENDIF.
        APPEND INITIAL LINE TO <fs_select_option>-ranges ASSIGNING FIELD-SYMBOL(<fs_range>).
        MOVE-CORRESPONDING ls_parameter TO <fs_range>.
      ELSE.
        ASSERT ls_parameter_def-kind = 'P'.
        INSERT VALUE #( parameter_name = ls_parameter-selname
                        value          = ls_parameter-low ) INTO TABLE mt_parameter_values.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD _finalize_run.
    GET TIME STAMP FIELD DATA(lv_timestamp).
    CONVERT TIME STAMP lv_timestamp TIME ZONE sy-zonlo INTO TIME DATA(lv_time) DATE DATA(lv_date).
    CONVERT TIME lv_time DATE lv_date INTO TIME STAMP lv_timestamp TIME ZONE sy-zonlo.
    MODIFY ENTITIES OF ZR_PRC_Run
           ENTITY run
           UPDATE FIELDS ( MessageSeverity ExecutionStatus JobEnd )
           WITH VALUE #( ( %key-uuid       = mv_current_run_uuid
                           ExecutionStatus = 'FI'
                           MessageSeverity = mv_message_status
                           JobEnd          = lv_timestamp ) )
           FAILED DATA(failed)
           " TODO: variable is assigned but never used (ABAP cleaner)
           REPORTED DATA(reported).
    ASSERT failed IS INITIAL.
    IF mv_run_in_background = abap_true.
      COMMIT ENTITIES RESPONSES FAILED DATA(ls_failed) REPORTED DATA(ls_reported).
    ENDIF.
  ENDMETHOD.


  METHOD _initialize_run.
    DATA lv_param_counter TYPE i.

    TRY.
        cl_apj_rt_api=>get_job_runtime_info( IMPORTING ev_jobname  = DATA(lv_job_id)
                                                       ev_jobcount = DATA(lv_job_count) ).
        DATA(ls_job_details) = cl_apj_rt_api=>get_job_details( lv_job_id ).
      CATCH cx_apj_rt INTO DATA(lo_exception).
        " happens if run is called without application job
        DATA(lv_text) = lo_exception.
    ENDTRY.

    GET TIME STAMP FIELD DATA(lv_timestamp).
    CONVERT TIME STAMP lv_timestamp TIME ZONE sy-zonlo INTO TIME DATA(lv_time) DATE DATA(lv_date).
    CONVERT TIME lv_time DATE lv_date INTO TIME STAMP lv_timestamp TIME ZONE sy-zonlo.

    DATA lt_parameter TYPE TABLE FOR CREATE ZR_PRC_Run\_Parameter.

    READ TABLE it_parameters INTO DATA(ls_uuid_parameter) WITH KEY selname = zif_prc_run=>co_parameter-p_uuid.
    IF sy-subrc = 0 AND ls_uuid_parameter-low IS NOT INITIAL.
      DATA(lv_update_Scenario) = abap_true.
      mv_current_run_uuid = ls_uuid_parameter-low.
    ELSE.
      DATA(lv_cid) = 'CID'.
    ENDIF.

    READ TABLE it_parameters INTO DATA(ls_parameter) WITH KEY selname = zif_prc_run=>co_parameter-p_exec_type.
    IF sy-subrc = 0 AND ls_parameter-low IS NOT INITIAL.
      ASSERT 1 = 0. " Execution type vs. test mode
      mv_execution_type = ls_parameter-low.
    ELSE.
      mv_execution_type = '666'.
    ENDIF.

    LOOP AT it_parameters INTO ls_parameter WHERE selname <> zif_prc_run=>co_parameter-p_uuid.
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

    IF lv_update_Scenario = abap_true.

      MODIFY ENTITIES OF ZR_PRC_Run
             ENTITY Run
             UPDATE FIELDS ( ApplicationName JobName JobCount JobID JobStart LogHandle ExecutionType MessageSeverity ExecutionStatus CreatedBy )
             WITH VALUE #( ( uuid            = mv_current_run_uuid
                             ApplicationName = get_application_name( )
                             JobID           = lv_job_id
                             JobCount        = lv_job_count
                             JobName         = ls_job_details-job_text
                             JobStart        = lv_timestamp
*                             LogHandle       = application_log->get_handle( )
                             ExecutionType   = mv_execution_type
                             MessageSeverity = zif_prc_run=>co_message_severity-neutral
                             ExecutionStatus = zif_prc_run=>co_execution_status-started
                             CreatedBy       = sy-uname ) )
             CREATE BY \_Parameter FIELDS ( ParameterName Operator Sign Low High )
             WITH lt_parameter
             FAILED DATA(failed)
             " TODO: variable is assigned but never used (ABAP cleaner)
             REPORTED DATA(reported)
             " TODO: variable is assigned but never used (ABAP cleaner)
             MAPPED DATA(mapped).
      ASSERT failed IS INITIAL.
    ELSE. " create new entry
      IF application_log IS BOUND.
        DATA(lv_bali_handle) = application_log->get_handle( ).
      ENDIF.
      MODIFY ENTITIES OF ZR_PRC_Run
             ENTITY Run
             CREATE FIELDS ( ApplicationName JobName JobCount JobID JobStart LogHandle ExecutionType MessageSeverity ExecutionStatus CreatedBy )
             WITH VALUE #( ( %cid            = lv_cid
                             ApplicationName = get_application_name( )
                             JobID           = lv_job_id
                             JobCount        = lv_job_count
                             JobName         = ls_job_details-job_text
                             JobStart        = lv_timestamp
                             LogHandle       = lv_bali_handle
                             ExecutionType   = mv_execution_type
                             MessageSeverity = zif_prc_run=>co_message_severity-neutral
                             ExecutionStatus = zif_prc_run=>co_execution_status-started
                             CreatedBy       = sy-uname ) )
             CREATE BY \_Parameter FIELDS ( ParameterName Operator Sign Low High )
             WITH lt_parameter
             FAILED DATA(create_failed)
             " TODO: variable is assigned but never used (ABAP cleaner)
             REPORTED DATA(create_reported)
             MAPPED DATA(create_mapped).
      ASSERT create_failed IS INITIAL.
      mv_current_run_uuid = create_mapped-run[ 1 ]-uuid.
    ENDIF.
    IF mv_run_in_background = abap_true.
      COMMIT ENTITIES RESPONSES FAILED DATA(ls_failed).
      ROLLBACK ENTITIES.
      ASSERT sy-subrc = 0 AND ls_failed IS INITIAL.
    ENDIF.
  ENDMETHOD.


  METHOD execute_synchronously.
    mv_run_in_background = abap_false.
    _execute( it_parameters ).
  ENDMETHOD.


  METHOD _execute.
    TRY.
        _initialize_parameter_values( it_parameters ).
        _initialize_run( it_parameters ).
        execute( it_parameters = it_parameters ).
        _finalize_run( ).
      CATCH cx_bali_runtime INTO DATA(lx_bali).
        ASSERT 1 = 2.
    ENDTRY.
  ENDMETHOD.


  METHOD set_total_number.
    MODIFY ENTITIES OF ZR_PRC_Run
           ENTITY Run
           UPDATE FIELDS ( TotalNumber )
           WITH VALUE #( ( %key-uuid   = mv_current_run_uuid
                           TotalNumber = iv_number ) )
           FAILED DATA(create_failed)
           REPORTED DATA(create_reported)
           MAPPED DATA(create_mapped).

    COMMIT ENTITIES RESPONSES FAILED DATA(failed) REPORTED DATA(reported).
    ROLLBACK ENTITIES.
  ENDMETHOD.
ENDCLASS.
