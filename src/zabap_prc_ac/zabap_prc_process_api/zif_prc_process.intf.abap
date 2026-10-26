"! <p class="shorttext synchronized">A process: its state graph and its transitions</p>
"!
"! Implemented by one class per process; the class name is registered with the
"! processed objects of the process. The class describes the process as a
"! state graph from START to FINISHED and hands out one transition handler per
"! start state. Metadata (graph) and runtime (handler) are kept apart on
"! purpose: a start state with several end states (fork) has one handler that
"! returns the end state.
"!
"! The processing engine checks at runtime that a handler exists for the start
"! state (ZPRC_PROCESS_MESSAGE/007), that the reached transition is part of the
"! graph (006) and that a fork returns an end state (008).
INTERFACE zif_prc_process
  PUBLIC.

  "! State of a processed object
  TYPES ty_state TYPE zprc_state.
  "! First state of every processed object
  CONSTANTS co_start     TYPE ty_state VALUE 'START'.
  "! Final state; a processed object in this state is not processed any more
  CONSTANTS co_finished  TYPE ty_state VALUE 'FINISHED'.
  "! Maximum number of automatic retries of a failed step
  CONSTANTS co_max_retry TYPE int4     VALUE 99999.

  "! Relative URL (FLP intent) to the business object behind a processed
  "! object - shown as link in the Processing Center and used in notifications.
  "!
  "! @parameter i_processed_object      | External ID of the processed object.
  "! @parameter i_processed_object_uuid | External UUID of the processed object.
  "! @parameter r_relative_url          | Relative URL, e.g. #Equipment-display?Equipment=4711; initial if none.
  METHODS get_url_for_processed_object IMPORTING i_processed_object      TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectID
                                                 i_processed_object_uuid TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectUUID
                                       RETURNING VALUE(r_relative_url)   TYPE string.

  " One edge of the state graph; the graph is the sorted table of all edges
  TYPES: BEGIN OF ty_transition,
           start_state TYPE zif_prc_process=>ty_state,
           end_state   TYPE zif_prc_process=>ty_state,
         END OF ty_transition,
         tt_transition TYPE SORTED TABLE OF ty_transition WITH UNIQUE KEY start_state end_state.

  "! Returns the state graph of the process: all transitions from START to
  "! FINISHED. Also used to calculate the remaining steps of an object.
  "!
  "! @parameter r_transitions | All transitions of the process.
  METHODS get_transitions RETURNING VALUE(r_transitions) TYPE tt_transition.

  "! Returns a new transition handler for the given start state.
  "!
  "! Called once per transition of one object; return a fresh instance every
  "! time (lifetime = one transition). Usually a CASE over the start state.
  "!
  "! @parameter i_start_state        | Start state of the transition to perform.
  "! @parameter i_processed_object   | External ID of the processed object.
  "! @parameter r_transition_handler | New handler; unbound if the state has none (error 007).
  METHODS get_transition_handler IMPORTING i_start_state               TYPE zif_prc_process=>ty_state
                                           i_processed_object          TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectID
                                 RETURNING VALUE(r_transition_handler) TYPE REF TO zif_prc_transition_handler.

ENDINTERFACE.
