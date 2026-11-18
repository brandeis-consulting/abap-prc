"! Raises the events of the run (from 2025). Called dynamically by the saver of
"! ZBP_PRC_RUN - keep the signature in sync with that call.
CLASS zbp_r_prc_runext DEFINITION PUBLIC ABSTRACT FINAL FOR BEHAVIOR OF zr_prc_runtp.
  PUBLIC SECTION.
    TYPES tt_uuids TYPE STANDARD TABLE OF ZR_PRC_RunTP-uuid WITH EMPTY KEY.

    "! @parameter i_uuids | Runs whose changed event is raised
    CLASS-METHODS raise_run IMPORTING i_uuids TYPE tt_uuids.
ENDCLASS.

CLASS zbp_r_prc_runext IMPLEMENTATION.

  METHOD raise_run.
    RAISE ENTITY EVENT ZR_PRC_RunTP~zz_runChanged FROM VALUE #( FOR uuid IN i_uuids ( %key-uuid = uuid ) ).
  ENDMETHOD.

ENDCLASS.
