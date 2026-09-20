CLASS ltc_run DEFINITION FOR TESTING DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS execute FOR TESTING.
ENDCLASS.

CLASS ltc_run IMPLEMENTATION.

  METHOD execute.
*    IF 1 = 2.
      NEW zcl_prc_error_mail_job( )->execute_synchronously( ).
*    ENDIF.
  ENDMETHOD.

ENDCLASS.
