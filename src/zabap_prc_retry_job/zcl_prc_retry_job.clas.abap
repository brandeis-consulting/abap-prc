CLASS zcl_prc_retry_job DEFINITION
  PUBLIC
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_apj_rt_exec_object.
    INTERFACES if_apj_dt_exec_object.
*    interfaces if_apj_jt_check_20.


    CONSTANTS c_apj_template_name TYPE cl_apj_rt_api=>ty_template_name VALUE 'ZAJT_PRC_RETRY_JOB'.

    CONSTANTS c_process_name   TYPE zif_prc_run=>ty_run_parameter VALUE 'S_PROC'.
    CONSTANTS p_ignore_restart TYPE zif_prc_run=>ty_run_parameter VALUE 'P_IGNR'.
    CONSTANTS s_uuid           TYPE zif_prc_run=>ty_run_parameter VALUE 'S_UUID'.
  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_prc_retry_job IMPLEMENTATION.
  METHOD if_apj_dt_exec_object~get_parameters.
    et_parameter_def = VALUE #(
        datatype = 'C'
        ( selname = c_process_name   kind = if_apj_dt_exec_object=>select_option length = 30  param_text = 'Process Name' )
        ( selname = p_ignore_restart kind = if_apj_dt_exec_object=>parameter     length = 1   param_text = 'Overrule Resume Scheduling' )
        ( selname = s_uuid           kind = if_apj_dt_exec_object=>select_option length = 32  param_text = 'Processed Object UUID' ) ).
  ENDMETHOD.

  METHOD if_apj_rt_exec_object~execute.
    zcl_prc_processing_engine=>get_instance( )->execute_synchronously( it_parameters ).
*  ENDMETHOD.
*
*  method i>f_apj_jt_check_20~check_and_adjust.

*    DATA lv_process_name TYPE zprc_process_name.
*
*    check line_exists( ct_value[ parameter_name = c_process_name ] ).
*
*    ct_value[ parameter_name = c_process_name ]-low.
*
*    " 1. select all processes from the value help cds view matching the select option
*    " 2. check if all processes are authorized for the user
*
*    LOOP AT ct_value INTO DATA(ls_parameter).
*      IF to_upper( ls_parameter-name ) = 'PROCESSNAME'.
*        lv_process_name = ls_parameter-t_value[ 1 ].
*        EXIT.
*      ENDIF.
*    ENDLOOP.
*
*    IF lv_process_name IS INITIAL.
*      RAISE EXCEPTION TYPE cx_apj_rt_content
*        EXPORTING
*          textid = cx_apj_rt_content=>parameter_missing.
*    ENDIF.
*
*    AUTHORITY-CHECK OBJECT 'ZPRC_PROC'
*             ID 'ZPRC_PNAME' FIELD lv_process_name
*             ID 'ACTVT'      FIELD '16'.
*    IF sy-subrc <> 0.
*      RAISE EXCEPTION TYPE cx_apj_rt_content
*        EXPORTING
*          textid = cx_apj_rt_content=>not_authorized.
*    ENDIF.
  ENDMETHOD.

ENDCLASS.
