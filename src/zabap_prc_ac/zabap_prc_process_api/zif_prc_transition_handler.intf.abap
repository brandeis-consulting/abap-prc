"! <p class="shorttext synchronized">Executes one transition as a unit of work</p>
"!
"! A transition groups everything that has to succeed or fail together. The
"! processing engine creates one instance per transition of one object, hands
"! it a fresh message handler and reports the outcome only through that
"! handler.
"!
"! Committing, rolling back and simulating the save stay with the engine. A
"! transition never issues COMMIT ENTITIES, COMMIT WORK, ROLLBACK ENTITIES or
"! ROLLBACK WORK itself.
"!
"! Implement it by inheriting from ZCL_PRC_TRANSITION_HANDLR_BASE rather than
"! implementing this interface directly.
INTERFACE zif_prc_transition_handler PUBLIC.

  "! Called by the engine right after creation.
  "!
  "! The lifetime of the instance is one transition of one object.
  "!
  "! @parameter i_process_name              | Name of the process.
  "! @parameter i_processed_object_ext_id   | External ID of the processed object.
  "! @parameter i_processed_object_ext_uuid | External UUID of the processed object.
  "! @parameter i_message_handler           | Fresh message handler for this transition.
  METHODS initialize IMPORTING i_process_name                TYPE zprc_process_name
                               i_processed_object_ext_id   TYPE ZI_PRC_ProcessedObject-ExternalProcessedObjectID
                               i_processed_object_ext_uuid TYPE ZI_PRC_ProcessedObject-ExternalProcessedObjectUUID
                               i_message_handler           TYPE REF TO zif_prc_message_handler.

  "! Runs the transition.
  "!
  "! Every operation is fed into the message handler; a failure raises out of
  "! the handler. On failure the payload changes are discarded by the engine.
  "!
  "! @parameter i_start_state               | Start state of the transition.
  "! @parameter c_payload_json              | Payload of the processed object; may be changed.
  "! @parameter r_new_state                 | End state; only needed if the start state has more
  "!                                          than one transition (fork).
  "! @raising   zcx_prc_unit_of_work_failed | The transition failed; details are in the handler.
  METHODS perform_transition IMPORTING i_start_state      TYPE zif_prc_process=>ty_state
                             CHANGING  c_payload_json     TYPE zprc_payload_json
                             RETURNING VALUE(r_new_state) TYPE zif_prc_process=>ty_state
                             RAISING   zcx_prc_unit_of_work_failed.

  "! Step header if the transition succeeded.
  "!
  "! Called only after PERFORM_TRANSITION and the save simulation passed, so it
  "! may refer to results of the run - a document number, an assigned key.
  "!
  "! @parameter r_message | Success message.
  METHODS get_success_message RETURNING VALUE(r_message) TYPE symsg.

  "! Step header if the transition failed.
  "!
  "! May be called at any time - also if the failure happened outside the
  "! transition (simulation, commit) - so it must not depend on the run.
  "!
  "! @parameter r_message | Failure message; initial if none is declared.
  METHODS get_failure_message RETURNING VALUE(r_message) TYPE symsg.

  "! Prefix of every message of this transition in the application log, so a
  "! log entry names its object.
  "!
  "! Called after INITIALIZE only, in a session of its own and without the
  "! transition having run, so it must depend on the processed object only.
  "! Initial: the engine uses process, object and states.
  "!
  "! @parameter r_message | Prefix message; initial for the default prefix.
  METHODS get_message_prefix_for_log RETURNING VALUE(r_message) TYPE symsg.

ENDINTERFACE.
