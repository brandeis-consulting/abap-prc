CLASS zcl_prc_retry_job DEFINITION
  PUBLIC
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_apj_rt_exec_object.
    INTERFACES if_apj_dt_exec_object.

    CONSTANTS c_apj_template_name TYPE cl_apj_rt_api=>ty_template_name VALUE 'ZAJT_PRC_RETRY_JOB'.

    CONSTANTS c_process_name   TYPE zif_prc_run=>ty_run_parameter VALUE 'S_PROC'.
    CONSTANTS p_ignore_restart TYPE zif_prc_run=>ty_run_parameter VALUE 'P_IGNR'.
    CONSTANTS s_uuid           TYPE zif_prc_run=>ty_run_parameter VALUE 'S_UUID'.

  PROTECTED SECTION.

  PRIVATE SECTION.
    "! Restricts the process names (S_PROC) to the processes the job user may
    "! resume (ZPRC_PROC, ZPRCNAME, activity 16). Returns an empty table if no
    "! process is authorized, because an empty S_PROC would mean all processes.
    METHODS _restrict_to_authorized
      IMPORTING it_parameters       TYPE if_apj_rt_exec_object=>tt_templ_val
      RETURNING VALUE(r_parameters) TYPE if_apj_rt_exec_object=>tt_templ_val.
ENDCLASS.


CLASS zcl_prc_retry_job IMPLEMENTATION.
  METHOD if_apj_dt_exec_object~get_parameters.
    CLEAR: et_parameter_def,
           et_parameter_val.

    et_parameter_def = VALUE #(
        datatype = 'C' changeable_ind = abap_true
        ( selname = c_process_name   kind = if_apj_dt_exec_object=>select_option length = 30  param_text = 'Process Name' )
        ( selname = p_ignore_restart kind = if_apj_dt_exec_object=>parameter     length = 1   param_text = 'Overrule Resume Scheduling' )
        ( selname = s_uuid           kind = if_apj_dt_exec_object=>select_option length = 32  param_text = 'Processed Object UUID' ) ).
  ENDMETHOD.

  METHOD if_apj_rt_exec_object~execute.
    " A job is an own runtime: it only processes the processes the job user is
    " authorized for. This also applies when the processing API schedules the job.
    DATA(lt_parameters) = _restrict_to_authorized( it_parameters ).
    IF lt_parameters IS INITIAL.
      RETURN.
    ENDIF.

    zcl_prc_processing_engine=>get_instance( )->execute_synchronously( lt_parameters ).
  ENDMETHOD.

  METHOD _restrict_to_authorized.
    DATA lt_process_range TYPE RANGE OF zprc_process_name.

    lt_process_range = VALUE #( FOR p IN it_parameters WHERE ( selname = c_process_name )
                                ( sign = p-sign option = p-option low = p-low high = p-high ) ).

    " All known processes matching S_PROC (empty S_PROC = all processes)
    SELECT DISTINCT ProcessName FROM ZI_PRC_ProcessNameVH WITH PRIVILEGED ACCESS
      WHERE ProcessName IN @lt_process_range
      INTO TABLE @DATA(lt_process_names).

    " Keep all other parameters, replace S_PROC by the authorized processes
    r_parameters = VALUE #( FOR p IN it_parameters WHERE ( selname <> c_process_name )
                            ( p ) ).

    DATA(lv_authorized_found) = abap_false.
    LOOP AT lt_process_names INTO DATA(ls_process).
      IF zcl_prc_auth_process=>is_authorized( i_process_name = ls_process-ProcessName
                                              i_activity     = zcl_prc_auth_process=>co_activity-execute ) = abap_true.
        APPEND VALUE #( selname = c_process_name
                        kind    = if_apj_dt_exec_object=>select_option
                        sign    = 'I'
                        option  = 'EQ'
                        low     = ls_process-ProcessName ) TO r_parameters.
        lv_authorized_found = abap_true.
      ENDIF.
    ENDLOOP.

    IF lv_authorized_found = abap_false.
      CLEAR r_parameters.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
