"! <p class="shorttext synchronized">ABAP-PRC: Object level - one object</p>
"!
"! Decides how far one object is driven in this run.
INTERFACE zif_prc_processing_object PUBLIC.

  "! @parameter i_state | State before the run.
  "! @parameter r_state | State after the last step of this run.
  METHODS process IMPORTING i_state        TYPE zif_prc_processing_engine=>ty_state
                  RETURNING VALUE(r_state) TYPE zif_prc_processing_engine=>ty_state.

ENDINTERFACE.
