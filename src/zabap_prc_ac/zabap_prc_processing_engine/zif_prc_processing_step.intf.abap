"! <p class="shorttext synchronized">ABAP-PRC: Step level - one transition</p>
"!
"! Every layer of the step level implements this interface and calls the next
"! inner layer. Exceptions travel between the layers of this level only; the
"! outermost layer never raises.
INTERFACE zif_prc_processing_step PUBLIC.

  "! Executes one transition of one object.
  "!
  "! @parameter i_state                   | State before the step.
  "! @parameter i_message_handler         | Fresh handler for this step.
  "! @parameter e_transition              | Transition instantiated by the core, passed by
  "!                                        reference so outer layers see it on failure as
  "!                                        well. Unbound if instantiation failed.
  "! @parameter r_state                   | State after the step.
  "! @raising   zcx_prc_unit_of_work_failed | Between the layers of this level only.
  METHODS execute IMPORTING i_state           TYPE zif_prc_processing_engine=>ty_state
                            i_message_handler TYPE REF TO zif_prc_message_handler
                  EXPORTING e_transition      TYPE REF TO zif_prc_transition_handler
                  RETURNING VALUE(r_state)    TYPE zif_prc_processing_engine=>ty_state
                  RAISING   zcx_prc_unit_of_work_failed.

ENDINTERFACE.
