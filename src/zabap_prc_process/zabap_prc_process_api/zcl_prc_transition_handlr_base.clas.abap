"! <p class="shorttext synchronized">Base class for transition handlers</p>
"!
"! Owns the flow, the subclass owns the content. A subclass implements three
"! phases and never touches the handler's lifecycle methods: SET_FAILURE_HEADER,
"! SIMULATE_SAVE and CLOSE_OK are called here.
"!
"! Declare both messages with real MESSAGE statements followed by
"! CORRESPONDING #( sy ) to keep the where-used list of the messages intact.
CLASS zcl_prc_transition_handlr_base DEFINITION PUBLIC ABSTRACT CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_prc_transition_handler.

  PROTECTED SECTION.
    "! Returns the message handler of the current execution.
    "!
    "! Available in all three phase methods and in any private method called
    "! from them, so the handler does not have to be passed around. Do not keep
    "! the reference beyond the running execution.
    "!
    "! @parameter r_message | Handler of the running execution.
    METHODS get_message_handler FINAL RETURNING VALUE(r_message) TYPE REF TO zif_prc_message_handler.

    "! Returns the message reported if the transition fails.
    "!
    "! Called before any operation runs, so it must not depend on results of the
    "! run. Describe the intent of the transition - "equipment X could not be
    "! assigned to truck Y" - rather than the technical cause; the cause arrives
    "! as a detail message.
    "!
    "! @parameter r_message | Failure message. Must not be initial.
    METHODS get_failure_message RETURNING VALUE(r_message) TYPE symsg.

    "! Performs the actual work of the transition.
    "!
    "! Feed every operation into GET_MESSAGE_HANDLER( ) right after it ran -
    "! ADD_MODIFY_RESULT for EML, ADD_BAPI_RESULT for BAPIs, ADD_MESSAGE_FROM_SY
    "! for own messages. Any failure raises out of those methods, so no state has
    "! to be queried in between.
    "!
    "! Do not call SIMULATE_SAVE here - the base class does that afterwards.
    "! A transition that needs an intermediate checkpoint is really two
    "! transitions.
    "!
    "! @parameter i_start_state               | Start state of the transition, e.g. "A" for a transition from A to B.
    "! @parameter i_processed_object_ext_id   | External ID of the processed object, e.g. 70000678 for an equipment.
    "! @parameter i_processed_object_ext_uuid | External UUID of the processed object.
    "! @parameter c_payload_json              | If process requires a payload, it is passed in and may be modified by the transition.
    "! @parameter r_new_state                 | New state to be returned only if not unique (fork of transitions).
    "! @raising   zcx_prc_unit_of_work_failed | Raised by the handler on failure.
    METHODS perform_transition ABSTRACT IMPORTING i_start_state               TYPE zif_prc_process=>ty_state
                                                  i_processed_object_ext_id   TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectID
                                                  i_processed_object_ext_uuid TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectUUID
                                        CHANGING  c_payload_json              TYPE zprc_payload_json
                                        RETURNING VALUE(r_new_state)          TYPE zif_prc_process=>ty_state
                                        RAISING   zcx_prc_unit_of_work_failed.

    "! Returns the message reported if the transition succeeded.
    "!
    "! Called only after _PERFORM_TRANSITION and the save simulation passed, so
    "! it may reference results produced during the run - a document number, an
    "! assigned key.
    "!
    "! @parameter i_processed_object_ext_id | External ID of the processed object, e.g. 70000678 for an equipment.
    "! @parameter i_processed_object_ext_uuid | External UUID of the processed object.
    "! @parameter r_message | Success message.
    METHODS get_success_message ABSTRACT IMPORTING i_processed_object_ext_id   TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectID
                                                   i_processed_object_ext_uuid TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectUUID
                                         RETURNING VALUE(r_message)            TYPE symsg.

    "! Get ID or UUID of the processed object.
    "!
    "! @parameter e_processed_object_ext_id   | External ID of the processed object, e.g. 70000678 for an equipment.
    "! @parameter e_processed_object_ext_uuid | External UUID of the processed object.
    METHODS get_processed_object FINAL EXPORTING e_processed_object_ext_id   TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectID
                                                 e_processed_object_ext_uuid TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectUUID.

    METHODS get_message_prefix_for_log IMPORTING i_processed_object_ext_id   TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectID
                                                 i_processed_object_ext_uuid TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectUUID
                                       RETURNING VALUE(r_message)            TYPE symsg.

  PRIVATE SECTION.
    "! Bound only while PERFORM_TRANSITION is running.
    DATA mo_handler                  TYPE REF TO zif_prc_message_handler.
    DATA m_processed_object_ext_id   TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectID.
    DATA m_processed_object_ext_uuid TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectUUID.
ENDCLASS.


CLASS zcl_prc_transition_handlr_base IMPLEMENTATION.
  METHOD get_failure_message.
    " by default do nothing, as fallback the first added error messages will be used
  ENDMETHOD.

  METHOD get_message_handler.
    r_message = mo_handler.
  ENDMETHOD.

  METHOD get_message_prefix_for_log.
  ENDMETHOD.

  METHOD get_processed_object.
    e_processed_object_ext_id = m_processed_object_ext_id.
    e_processed_object_ext_uuid = m_processed_object_ext_uuid.
  ENDMETHOD.

  METHOD zif_prc_transition_handler~initialize.
    mo_handler = i_message_handler.
    m_processed_object_ext_id = i_processed_object_ext_id.
    m_processed_object_ext_uuid = i_processed_object_ext_uuid.

    mo_handler->set_log_message_prefix( get_message_prefix_for_log( EXPORTING i_processed_object_ext_id = m_processed_object_ext_id
                                                                              i_processed_object_ext_uuid = m_processed_object_ext_uuid ) ).
  ENDMETHOD.

  METHOD zif_prc_transition_handler~perform_transition.
    TRY.
        r_new_state = perform_transition( EXPORTING i_start_state               = i_start_state
                                                    i_processed_object_ext_id   = m_processed_object_ext_id
                                                    i_processed_object_ext_uuid = m_processed_object_ext_uuid
                                          CHANGING  c_payload_json              = c_payload_json ).
        mo_handler->simulate_save( ).
      CATCH zcx_prc_unit_of_work_failed INTO DATA(lx_unit_of_work_failed).
        DATA(ls_failure_message) = get_failure_message( ).
        IF ls_failure_message IS NOT INITIAL.
          mo_handler->set_failure_header( ls_failure_message ).
        ENDIF.
        RAISE EXCEPTION lx_unit_of_work_failed.
    ENDTRY.

    mo_handler->set_success_header( get_success_message( i_processed_object_ext_id   = m_processed_object_ext_id
                                                         i_processed_object_ext_uuid = m_processed_object_ext_uuid ) ).

    CLEAR mo_handler.
  ENDMETHOD.
ENDCLASS.
