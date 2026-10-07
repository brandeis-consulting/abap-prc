CLASS ltc_execute DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    METHODS execute FOR TESTING RAISING cx_apj_rt_content.
ENDCLASS.


CLASS ltc_execute IMPLEMENTATION.
  METHOD execute.
    IF 1 = 2.
      NEW zcl_prc_demo_adjust_run_job( )->if_apj_rt_exec_object~execute( VALUE #( ) ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
