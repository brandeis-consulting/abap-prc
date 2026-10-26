"! <p class="shorttext synchronized">Base class for transition handlers</p>
"!
"! The subclass owns the content of a transition: the work itself and,
"! optionally, its own success and failure message. Everything around it -
"! simulating the save, committing, rolling back, choosing the step header -
"! is done by the layers of the processing engine.
"!
"! <h2>Minimal transition</h2>
"! Redefine PERFORM_TRANSITION only. The step header is then
"! ZPRC_PROCESS_MESSAGE/017 on success and the last error message on failure.
"!
"! <h2>Own messages</h2>
"! Redefine GET_SUCCESS_MESSAGE to report a business result, and
"! GET_FAILURE_MESSAGE to describe the intent of the transition on failure.
"! Declare them with real MESSAGE ... INTO statements followed by SY_MESSAGE( )
"! to keep the where-used list of the messages intact.
"!
"! <h2>Application log</h2>
"! Every message of a step goes into the application log of the run. Redefine
"! GET_MESSAGE_PREFIX_FOR_LOG to name the object in front of each entry.
"!
"! <h2>Context</h2>
"! The processed object is passed to the phase methods and is also available
"! via GET_PROCESSED_OBJECT( ) in helper methods; the message handler via
"! GET_MESSAGE_HANDLER( ).
CLASS zcl_prc_transition_handlr_base DEFINITION PUBLIC ABSTRACT CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_prc_transition_handler.

  PROTECTED SECTION.
    "! Returns the message handler of the running transition.
    "!
    "! Available in all phase methods and in any helper method called from
    "! them, so the handler does not have to be passed around. Do not keep the
    "! reference beyond the running transition.
    "!
    "! @parameter r_message | Handler of the running transition.
    METHODS get_message_handler FINAL RETURNING VALUE(r_message) TYPE REF TO zif_prc_message_handler.

    "! Returns the message of the last MESSAGE ... INTO statement (fields SY-MSG*)
    "! as SYMSG - for GET_SUCCESS_MESSAGE, GET_FAILURE_MESSAGE and
    "! GET_MESSAGE_PREFIX_FOR_LOG. Use it right after the MESSAGE statement:
    "! MESSAGE s006(zmy_messages) WITH ... INTO DATA(lv_dummy), then
    "! r_message = sy_message( ). Replaces CORRESPONDING #( sy ), which accesses
    "! the whole SY structure (syntax warning in ABAP for Cloud Development).
    "!
    "! @parameter r_message | Message of SY-MSGTY, SY-MSGID, SY-MSGNO and SY-MSGV1 to SY-MSGV4.
    METHODS sy_message FINAL RETURNING VALUE(r_message) TYPE symsg.

    "! Returns the message reported as step header if the transition fails.
    "!
    "! May be called at any time, also if the failure happened outside the
    "! transition (simulation, commit), so it must not depend on results of the
    "! run. Describe the intent of the transition - "equipment X could not be
    "! assigned to truck Y" - rather than the technical cause; the cause arrives
    "! as a detail message.
    "!
    "! Optional: by default none, the header is then the last error message.
    "!
    "! @parameter r_message | Failure message; initial if none is declared.
    METHODS get_failure_message RETURNING VALUE(r_message) TYPE symsg.

    "! Performs the actual work of the transition.
    "!
    "! Feed every operation into GET_MESSAGE_HANDLER( ) right after it ran -
    "! ADD_EML_MODIFY_RESULT for EML, ADD_BAPI_RESULT for BAPIs, ADD_EXCEPTION
    "! for caught exceptions, ADD_MESSAGE_FROM_SY for own messages. Any failure
    "! raises out of those methods, so no state has to be queried in between.
    "!
    "! Do not commit, roll back or simulate the save here - the engine does that
    "! afterwards. A transition that needs an intermediate checkpoint is really
    "! two transitions.
    "!
    "! @parameter i_start_state               | Start state of the transition, e.g. "A" for a transition from A to B.
    "! @parameter i_processed_object_ext_id   | External ID of the processed object, e.g. 70000678 for an equipment.
    "! @parameter i_processed_object_ext_uuid | External UUID of the processed object.
    "! @parameter c_payload_json              | Payload of the processed object; may be changed.
    "! @parameter r_new_state                 | End state; only needed if the start state has more than one transition (fork).
    "! @raising   zcx_prc_unit_of_work_failed | Raised by the message handler on failure.
    METHODS perform_transition ABSTRACT IMPORTING i_start_state               TYPE zif_prc_process=>ty_state
                                                  i_processed_object_ext_id   TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectID
                                                  i_processed_object_ext_uuid TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectUUID
                                        CHANGING  c_payload_json              TYPE zprc_payload_json
                                        RETURNING VALUE(r_new_state)          TYPE zif_prc_process=>ty_state
                                        RAISING   zcx_prc_unit_of_work_failed.

    "! Returns the message reported as step header if the transition succeeded.
    "!
    "! Called only after PERFORM_TRANSITION and the save simulation passed, so
    "! it may refer to results produced during the run - a document number, an
    "! assigned key.
    "!
    "! Optional: by default ZPRC_PROCESS_MESSAGE/017 "Transition from state &1
    "! completed successfully" with the start state.
    "!
    "! @parameter i_processed_object_ext_id   | External ID of the processed object, e.g. 70000678 for an equipment.
    "! @parameter i_processed_object_ext_uuid | External UUID of the processed object.
    "! @parameter r_message                   | Success message.
    METHODS get_success_message IMPORTING i_processed_object_ext_id   TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectID
                                          i_processed_object_ext_uuid TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectUUID
                                RETURNING VALUE(r_message)            TYPE symsg.

    "! Returns ID and UUID of the processed object - for helper methods that are
    "! not handed them as parameters.
    "!
    "! @parameter e_processed_object_ext_id   | External ID of the processed object, e.g. 70000678 for an equipment.
    "! @parameter e_processed_object_ext_uuid | External UUID of the processed object.
    METHODS get_processed_object FINAL EXPORTING e_processed_object_ext_id   TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectID
                                                 e_processed_object_ext_uuid TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectUUID.

    "! Returns the prefix of every message of this transition in the application
    "! log, e.g. "Equipment 70000678:". Called without the transition having
    "! run, so it must depend on the processed object only.
    "!
    "! Optional: by default none, the log then shows process, object and states.
    "!
    "! @parameter i_processed_object_ext_id   | External ID of the processed object.
    "! @parameter i_processed_object_ext_uuid | External UUID of the processed object.
    "! @parameter r_message                   | Prefix message; initial by default.
    METHODS get_message_prefix_for_log IMPORTING i_processed_object_ext_id   TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectID
                                                 i_processed_object_ext_uuid TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectUUID
                                       RETURNING VALUE(r_message)            TYPE symsg.

  PRIVATE SECTION.
    DATA mo_handler                  TYPE REF TO zif_prc_message_handler.
    DATA m_processed_object_ext_id   TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectID.
    DATA m_processed_object_ext_uuid TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectUUID.
    DATA m_process_name              TYPE zprc_process_name.
    "! Start state of the running transition, for the default success message
    DATA m_start_state               TYPE zif_prc_process=>ty_state.
ENDCLASS.


CLASS zcl_prc_transition_handlr_base IMPLEMENTATION.
  METHOD get_failure_message.
    " by default none: the header is then the last error message of the step
  ENDMETHOD.

  METHOD get_success_message.
    " by default the generic PRC message with the start state
    MESSAGE s017(zprc_process_message) WITH m_start_state INTO DATA(lv_dummy) ##NEEDED.
    r_message = sy_message( ).
  ENDMETHOD.

  METHOD sy_message.
    r_message = VALUE #( msgty = sy-msgty
                         msgid = sy-msgid
                         msgno = sy-msgno
                         msgv1 = sy-msgv1
                         msgv2 = sy-msgv2
                         msgv3 = sy-msgv3
                         msgv4 = sy-msgv4 ).
  ENDMETHOD.

  METHOD get_message_handler.
    r_message = mo_handler.
  ENDMETHOD.

  METHOD get_message_prefix_for_log.
    " by default none: the log shows process, object and states
  ENDMETHOD.

  METHOD get_processed_object.
    e_processed_object_ext_id = m_processed_object_ext_id.
    e_processed_object_ext_uuid = m_processed_object_ext_uuid.
  ENDMETHOD.

  METHOD zif_prc_transition_handler~initialize.
    mo_handler = i_message_handler.
    m_processed_object_ext_id = i_processed_object_ext_id.
    m_processed_object_ext_uuid = i_processed_object_ext_uuid.
    m_process_name = i_process_name.
  ENDMETHOD.

  METHOD zif_prc_transition_handler~perform_transition.
    m_start_state = i_start_state.
    r_new_state = perform_transition( EXPORTING i_start_state               = i_start_state
                                                i_processed_object_ext_id   = m_processed_object_ext_id
                                                i_processed_object_ext_uuid = m_processed_object_ext_uuid
                                      CHANGING  c_payload_json              = c_payload_json ).
  ENDMETHOD.

  METHOD zif_prc_transition_handler~get_success_message.
    r_message = get_success_message( i_processed_object_ext_id   = m_processed_object_ext_id
                                     i_processed_object_ext_uuid = m_processed_object_ext_uuid ).
  ENDMETHOD.

  METHOD zif_prc_transition_handler~get_failure_message.
    r_message = get_failure_message( ).
  ENDMETHOD.

  METHOD zif_prc_transition_handler~get_message_prefix_for_log.
    r_message = get_message_prefix_for_log( i_processed_object_ext_id   = m_processed_object_ext_id
                                            i_processed_object_ext_uuid = m_processed_object_ext_uuid ).
  ENDMETHOD.
ENDCLASS.
