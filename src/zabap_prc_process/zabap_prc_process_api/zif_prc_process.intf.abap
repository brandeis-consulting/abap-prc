INTERFACE zif_prc_process
  PUBLIC.

  TYPES ty_state TYPE zprc_state.
  CONSTANTS co_start     TYPE ty_state VALUE 'START'.
  CONSTANTS co_finished  TYPE ty_state VALUE 'FINISHED'.
  CONSTANTS co_max_retry TYPE int4     VALUE 99999.

  METHODS get_url_for_processed_object IMPORTING iv_processed_object      TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectID
                                                 iv_processed_object_uuid TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectUUID
                                       RETURNING VALUE(rv_relative_url)   TYPE string.

  TYPES: BEGIN OF ty_transition,
           start_state TYPE zif_prc_process=>ty_state,
           end_state   TYPE zif_prc_process=>ty_state,
         END OF ty_transition,
         tt_transition TYPE HASHED TABLE OF ty_transition WITH UNIQUE KEY start_state end_state.

  METHODS get_transitions RETURNING VALUE(rt_transitions) TYPE tt_transition.

  METHODS get_transition_handler IMPORTING i_start_state                TYPE zif_prc_process=>ty_state
                                           i_processed_object           TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectID
                                 RETURNING VALUE(ro_transition_handler) TYPE REF TO zif_prc_transition_handler.

ENDINTERFACE.
