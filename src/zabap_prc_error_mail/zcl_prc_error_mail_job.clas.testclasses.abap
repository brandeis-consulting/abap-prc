CLASS ltc_run DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS execute FOR TESTING raising cx_apj_rt_content.
ENDCLASS.

CLASS ltc_run IMPLEMENTATION.

  METHOD execute.
*    IF 1 = 2.
      NEW zcl_prc_error_mail_job( )->if_apj_rt_exec_object~execute( value #( ( selname = zcl_prc_error_mail_job=>c_process_name option = 'EQ' sign = 'I' low = zcl_prc_demo_create_equi_proc=>co_process_name ) ) ).
*    ENDIF.
  ENDMETHOD.

ENDCLASS.
