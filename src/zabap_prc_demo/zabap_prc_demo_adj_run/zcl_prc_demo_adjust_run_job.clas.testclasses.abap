CLASS ltc_execute DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS: execute FOR TESTING RAISING cx_apj_rt_content.
ENDCLASS.

CLASS ltc_execute IMPLEMENTATION.
  METHOD execute.
    NEW zcl_prc_demo_adjust_run_job( )->if_apj_rt_exec_object~execute( value #( ) ).
  ENDMETHOD.

ENDCLASS.
