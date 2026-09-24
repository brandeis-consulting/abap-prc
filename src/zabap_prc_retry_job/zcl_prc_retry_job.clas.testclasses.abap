CLASS ltc_execute_process DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PUBLIC SECTION.
    METHODS execute FOR TESTING raising cx_apj_rt_content.
ENDCLASS.

CLASS ltc_execute_process IMPLEMENTATION.
  METHOD execute.
    NEW zcl_prc_retry_job( )->if_apj_rt_exec_object~execute(
        VALUE #(
            ( selname = zcl_prc_retry_job=>c_process_name option = 'EQ' low = zcl_prc_demo_create_equi_proc=>co_process_name sign = 'I' ) ) ).
  ENDMETHOD.

ENDCLASS.
