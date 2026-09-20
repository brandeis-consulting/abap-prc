"! <p class="shorttext synchronized">Executes one transition as a unit of work</p>
"!
"! A transition groups everything that has to succeed or fail together. It is
"! handed a fresh message handler by the orchestrating layer and reports its
"! outcome exclusively through that handler.
"!
"! Committing and rolling back stay with the transaction owner. A transition
"! never issues COMMIT ENTITIES, COMMIT WORK, ROLLBACK ENTITIES or
"! ROLLBACK WORK itself.
INTERFACE zif_prc_transition_handler PUBLIC.

  "! Initialization called by the process center after creation to set processed object and message handler.
  "!
  "! This implies that the lifetime of the transition handler is bound to one transition of one object.
  "!
  "! @parameter i_processed_object_ext_id | Key of the object to be processed.
  "! @parameter i_processed_object_ext_uuid |
  "! @parameter i_message_handler         | Fresh handler for this transition.
  METHODS initialize IMPORTING i_processed_object_ext_id   TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectID
                               i_processed_object_ext_uuid TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectUUID
                               i_message_handler           TYPE REF TO zif_prc_message_handler.

  "! Runs the transition and closes the handler.
  "!
  "! On return the handler is sealed and carries the header message plus all
  "! collected details. On failure the handler is sealed as well - the raised
  "! exception is a pure signal and carries no data.
  "!
  "! @parameter i_start_state               | Start state for current transition
  "! @parameter c_payload_json              | If process requires a payload, it is passed in and may be modified by the transition.
  "! @parameter r_new_state                 | New state from transition, to be indicated if not unique
  "! @raising   zcx_prc_unit_of_work_failed | The transition failed. Details are
  "!                                         in the handler.
  METHODS perform_transition IMPORTING i_start_state      TYPE zif_prc_process=>ty_state
                             CHANGING  c_payload_json     TYPE zprc_payload_json
                             RETURNING VALUE(r_new_state) TYPE zif_prc_process=>ty_state
                             RAISING   zcx_prc_unit_of_work_failed.



ENDINTERFACE.
