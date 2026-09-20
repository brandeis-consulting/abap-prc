CLASS zbp_r_prc_runext DEFINITION PUBLIC ABSTRACT FINAL FOR BEHAVIOR OF zr_prc_run.
  PUBLIC SECTION.
    TYPES tt_run_uuid TYPE STANDARD TABLE OF ZR_PRC_Run-uuid WITH DEFAULT KEY.
    CLASS-METHODS raise_run IMPORTING it_run_uuid TYPE tt_run_uuid.
ENDCLASS.

CLASS zbp_r_prc_runext IMPLEMENTATION.

  METHOD raise_run.
    RAISE ENTITY EVENT ZR_PRC_Run~zz_runChanged FROM VALUE #( FOR k IN it_run_uuid ( %key-uuid = k ) ).
  ENDMETHOD.

ENDCLASS.
