"! <p class="shorttext synchronized">ABAP-PRC: Retry job</p>
"! Application job that processes the due objects: new ones and those whose retry time
"! has come. Also scheduled by the processing API for asynchronous processing.
CLASS zcl_prc_retry_job DEFINITION
  PUBLIC
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_apj_rt_exec_object.
    INTERFACES if_apj_dt_exec_object.

    CONSTANTS co_apj_template_name TYPE cl_apj_rt_api=>ty_template_name VALUE 'ZAJT_PRC_RETRY_JOB'.

    " Selection names of the job parameters. The values are stored in job templates
    " and scheduled jobs - do not change them.
    CONSTANTS:
      BEGIN OF co_parameter,
        "! Select option: process names
        process_name   TYPE zif_prc_run=>ty_run_parameter VALUE 'S_PROC',
        "! Parameter: process also objects whose retry time has not come yet
        ignore_restart TYPE zif_prc_run=>ty_run_parameter VALUE 'P_IGNR',
        "! Select option: UUIDs of the processed objects
        uuid           TYPE zif_prc_run=>ty_run_parameter VALUE 'S_UUID',
      END OF co_parameter.

  PROTECTED SECTION.

  PRIVATE SECTION.
    "! Restricts the process names (S_PROC) to the processes the job user may
    "! resume (ZPRC_PROC, ZPRCNAME, activity 16). Returns an empty table if no
    "! process is authorized, because an empty S_PROC would mean all processes.
    METHODS restrict_to_authorized
      IMPORTING i_parameters        TYPE if_apj_rt_exec_object=>tt_templ_val
      RETURNING VALUE(r_parameters) TYPE if_apj_rt_exec_object=>tt_templ_val.
ENDCLASS.


CLASS zcl_prc_retry_job IMPLEMENTATION.
  METHOD if_apj_dt_exec_object~get_parameters.
    CLEAR: et_parameter_def,
           et_parameter_val.

    et_parameter_def = VALUE #(
        datatype = 'C' changeable_ind = abap_true
        ( selname    = co_parameter-process_name
          kind       = if_apj_dt_exec_object=>select_option
          length     = 30
          param_text = 'Process Name' )
        ( selname    = co_parameter-ignore_restart
          kind       = if_apj_dt_exec_object=>parameter
          length     = 1
          param_text = 'Overrule Resume Scheduling' )
        ( selname    = co_parameter-uuid
          kind       = if_apj_dt_exec_object=>select_option
          length     = 32
          param_text = 'Processed Object UUID' ) ).
  ENDMETHOD.

  METHOD if_apj_rt_exec_object~execute.
    " A job is an own runtime: it only processes the processes the job user is
    " authorized for. This also applies when the processing API schedules the job.
    DATA(parameters) = restrict_to_authorized( it_parameters ).
    IF parameters IS INITIAL.
      RETURN.
    ENDIF.

    zcl_prc_processing_engine=>get_instance( )->execute_synchronously( parameters ).
  ENDMETHOD.

  METHOD restrict_to_authorized.
    DATA process_names TYPE RANGE OF zprc_process_name.

    process_names = VALUE #( FOR p IN i_parameters WHERE ( selname = co_parameter-process_name )
                             ( sign = p-sign option = p-option low = p-low high = p-high ) ).

    " All known processes matching S_PROC (empty S_PROC = all processes)
    SELECT DISTINCT ProcessName FROM ZI_PRC_ProcessNameVH WITH PRIVILEGED ACCESS
      WHERE ProcessName IN @process_names
      INTO TABLE @DATA(known_processes).

    " Keep all other parameters, replace S_PROC by the authorized processes
    r_parameters = VALUE #( FOR p IN i_parameters WHERE ( selname <> co_parameter-process_name )
                            ( p ) ).

    DATA(authorized_found) = abap_false.
    LOOP AT known_processes INTO DATA(process).
      IF zcl_prc_auth_process=>is_authorized( i_process_name = process-ProcessName
                                              i_activity     = zcl_prc_auth_process=>co_activity-execute ) = abap_true.
        APPEND VALUE #( selname = co_parameter-process_name
                        kind    = if_apj_dt_exec_object=>select_option
                        sign    = 'I'
                        option  = 'EQ'
                        low     = process-ProcessName ) TO r_parameters.
        authorized_found = abap_true.
      ENDIF.
    ENDLOOP.

    IF authorized_found = abap_false.
      CLEAR r_parameters.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
