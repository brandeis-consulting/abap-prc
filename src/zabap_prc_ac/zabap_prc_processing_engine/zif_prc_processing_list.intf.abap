"! <p class="shorttext synchronized">ABAP-PRC: List level - list of objects</p>
"!
"! Decides which objects, grouped how, in which order. The outermost layer
"! (selection) ignores its input and provides the list itself.
INTERFACE zif_prc_processing_list PUBLIC.

  "! @parameter i_states | States before the run.
  "! @parameter r_states | States after the run.
  METHODS process IMPORTING i_states        TYPE zif_prc_processing_engine=>tt_state
                  RETURNING VALUE(r_states) TYPE zif_prc_processing_engine=>tt_state.

ENDINTERFACE.
