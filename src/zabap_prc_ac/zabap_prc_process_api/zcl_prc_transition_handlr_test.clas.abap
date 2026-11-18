"! <p class="shorttext synchronized">Test base for transition handlers</p>
"!
"! Abstract superclass for unit tests of transition handlers. A local test
"! class inherits from it and drives the transitions of a process the way the
"! processing engine does: INITIALIZE once with the process class and the
"! processed object, then PERFORM_TRANSITION per start state.
"!
"! <h2>What PERFORM_TRANSITION does</h2>
"! It mirrors the step level of the engine, without persistence, lock and
"! commit:
"! <ul>
"! <li>a fresh message handler per call (MESSAGE_HANDLER),</li>
"! <li>layers 1-Core and 2-Simulation of the engine: the process class is
"!     instantiated by its name like in the engine, the transition handler of
"!     the start state is called (TRANSITION), the end state is taken from the
"!     state graph and the save is simulated (can be switched off in INITIALIZE),</li>
"! <li>the payload is taken over only if the step does not fail (PAYLOAD_JSON),</li>
"! <li>a violation of the process definition (no handler, end state outside the
"!     graph, fork without end state) fails the test with the engine message,</li>
"! <li>the step header as the engine writes it (HEADER): on success the success
"!     message of the transition with its type S, I or W, by default
"!     ZPRC_PROCESS_MESSAGE/017; another type fails the step with
"!     ZPRC_PROCESS_MESSAGE/023. With findings (errors added with
"!     I_FAIL_STEP = ABAP_FALSE, transition X -> X) the last error - no
"!     exception, the end state is the start state; findings with another end
"!     state fail the step with ZPRC_PROCESS_MESSAGE/024. On failure the
"!     failure message of the transition, else the last error.</li>
"! <li>on success the header is one of the messages of the step afterwards, as
"!     in the persistence after the commit; with findings it is one already.</li>
"! </ul>
"! On failure ZCX_PRC_UNIT_OF_WORK_FAILED is raised again once HEADER is set,
"! so a test catches it and then checks HEADER and MESSAGE_HANDLER.
"!
"! <h2>Several steps in one test</h2>
"! PAYLOAD_JSON is kept between calls, so a test can follow a path through the
"! graph by calling PERFORM_TRANSITION with the state returned by the last call.
"!
"! <h2>Engine code used</h2>
"! The step runs through the real layers 1-Core and 2-Simulation of the
"! engine: the same process instantiation, transition call, end state rule and
"! save simulation. Findings are recognized by ZCL_PRC_STEP_3_RESULT=>HAS_FINDINGS
"! and the header is chosen by ZCL_PRC_STEP_HEADER, the same code the engine
"! uses - no copies. Everything else is left out on purpose - persistence,
"! commit, rollback, retry, lock, session isolation, log, events.
"!
"! <h2>Test properties</h2>
"! Declare RISK LEVEL and DURATION on every test class of the hierarchy,
"! including abstract intermediate classes - otherwise ABAP Unit may skip the
"! tests without notice.
CLASS zcl_prc_transition_handlr_test DEFINITION PUBLIC ABSTRACT CREATE PUBLIC
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PROTECTED SECTION.
    "! Transition handler of the last PERFORM_TRANSITION.
    DATA transition      TYPE REF TO zif_prc_transition_handler.
    "! Message handler of the last PERFORM_TRANSITION - the messages of that step.
    DATA message_handler TYPE REF TO zif_prc_message_handler.
    "! Step header of the last PERFORM_TRANSITION, as the engine writes it.
    DATA header          TYPE zif_prc_message_handler=>ty_message_details.
    "! Payload of the processed object; changed by steps that do not fail only.
    DATA payload_json    TYPE zprc_payload_json.

    "! Sets the process and the processed object for all following calls of
    "! PERFORM_TRANSITION. Usually called in SETUP.
    "!
    "! @parameter i_process_class             | Process class under test; instantiated like in the engine.
    "! @parameter i_process_name              | Name of the process.
    "! @parameter i_processed_object_ext_id   | External ID of the processed object.
    "! @parameter i_processed_object_ext_uuid | External UUID of the processed object.
    "! @parameter i_payload_json              | Payload before the first transition.
    "! @parameter i_simulate_save             | ABAP_TRUE (default): simulate the save like the engine.
    METHODS initialize
      IMPORTING i_process_class             TYPE zprc_process_impl_class
                i_process_name              TYPE zprc_process_name
                i_processed_object_ext_id   TYPE zi_prc_processedobject-ExternalProcessedObjectID   OPTIONAL
                i_processed_object_ext_uuid TYPE zi_prc_processedobject-ExternalProcessedObjectUUID OPTIONAL
                i_payload_json              TYPE zprc_payload_json OPTIONAL
                i_simulate_save             TYPE abap_bool DEFAULT abap_true.

    "! Performs the transition of the start state as one step of the engine.
    "!
    "! @parameter i_start_state               | Start state of the transition.
    "! @parameter r_new_state                 | End state as the engine determines it.
    "! @raising   zcx_prc_unit_of_work_failed | The step failed; HEADER and MESSAGE_HANDLER are set.
    METHODS perform_transition IMPORTING i_start_state      TYPE zif_prc_process=>ty_state
                               RETURNING VALUE(r_new_state) TYPE zif_prc_process=>ty_state
                               RAISING   zcx_prc_unit_of_work_failed.

    "! Prefix of the application log for the transition of the start state, read
    "! like the engine does: right after INITIALIZE, without the transition run.
    "!
    "! @parameter i_start_state | Start state of the transition.
    "! @parameter r_message     | Prefix message; initial for the default prefix.
    METHODS get_message_prefix_for_log IMPORTING i_start_state    TYPE zif_prc_process=>ty_state
                                       RETURNING VALUE(r_message) TYPE symsg.

    "! Asserts the step header of the last PERFORM_TRANSITION.
    METHODS assert_header IMPORTING i_msgid TYPE symsgid
                                    i_msgty TYPE symsgty
                                    i_msgno TYPE symsgno.

    "! Asserts that the last PERFORM_TRANSITION collected the message.
    METHODS assert_message_exists IMPORTING i_msgid TYPE symsgid
                                            i_msgty TYPE symsgty
                                            i_msgno TYPE symsgno.

  PRIVATE SECTION.
    DATA m_process_name              TYPE zprc_process_name.
    DATA m_process_class             TYPE zprc_process_impl_class.
    DATA m_processed_object_ext_id   TYPE zi_prc_processedobject-ExternalProcessedObjectID.
    DATA m_processed_object_ext_uuid TYPE zi_prc_processedobject-ExternalProcessedObjectUUID.
    DATA m_simulate_save             TYPE abap_bool.

    METHODS create_transition IMPORTING i_start_state       TYPE zif_prc_process=>ty_state
                                        i_message_handler   TYPE REF TO zif_prc_message_handler
                              RETURNING VALUE(r_transition) TYPE REF TO zif_prc_transition_handler.

    "! Layers 1-Core and 2-Simulation of the engine, as built by the step factory.
    METHODS create_step RETURNING VALUE(r_step) TYPE REF TO zif_prc_processing_step.

    "! The success header among the messages of the step, as persisted with the commit.
    METHODS add_header_to_messages.
ENDCLASS.



CLASS zcl_prc_transition_handlr_test IMPLEMENTATION.

  METHOD initialize.
    m_process_class             = i_process_class.
    m_process_name              = i_process_name.
    m_processed_object_ext_id   = i_processed_object_ext_id.
    m_processed_object_ext_uuid = i_processed_object_ext_uuid.
    m_simulate_save             = i_simulate_save.
    payload_json                = i_payload_json.
    CLEAR: transition, message_handler, header.
  ENDMETHOD.


  METHOD perform_transition.
    CLEAR: header, transition.
    message_handler = zcl_prc_msg_handler_for_test=>create( ).

    DATA(state) = VALUE zif_prc_processing_engine=>ty_state( ProcessName                 = m_process_name
                                                             FactoryClassName            = m_process_class
                                                             State                       = i_start_state
                                                             ExternalProcessedObjectID   = m_processed_object_ext_id
                                                             ExternalProcessedObjectUUID = m_processed_object_ext_uuid
                                                             PayloadJson                 = payload_json ).
    DATA(findings) = abap_false.
    TRY.
        DATA(state_after) = create_step( )->execute( EXPORTING i_state           = state
                                                               i_message_handler = message_handler
                                                     IMPORTING e_transition      = transition ).
        " Like the result layer: findings (X -> X) or success; the success message
        " may fail the step on a program error
        findings = zcl_prc_step_3_result=>has_findings( i_start_state     = i_start_state
                                                        i_end_state       = state_after-State
                                                        i_message_handler = message_handler ).
        header = COND #( WHEN findings = abap_true
                         THEN zcl_prc_step_header=>for_findings( message_handler )
                         ELSE zcl_prc_step_header=>for_success( i_transition      = transition
                                                                i_message_handler = message_handler ) ).

      CATCH zcx_prc_unit_of_work_failed INTO DATA(failure).
        " Like the layer for expected errors: discard the buffer, failure message or last error
        ROLLBACK ENTITIES.
        header = zcl_prc_step_header=>for_failure(
                     i_message_handler = message_handler
                     i_failure_message = COND #( WHEN transition IS BOUND
                                                 THEN transition->get_failure_message( ) ) ).
        RAISE EXCEPTION failure.

      CATCH zcx_prc_process_definition INTO DATA(definition_error).
        " In the engine an unexpected error; here an error in the process class under test
        cl_abap_unit_assert=>fail( msg = definition_error->get_text( ) ).
    ENDTRY.

    r_new_state  = state_after-State.
    payload_json = state_after-PayloadJson.
    " The findings header is one of the messages already; the success header joins with the commit
    IF findings = abap_false.
      add_header_to_messages( ).
    ENDIF.
  ENDMETHOD.


  METHOD get_message_prefix_for_log.
    r_message = create_transition( i_start_state     = i_start_state
                                   i_message_handler = zcl_prc_msg_handler_for_test=>create( )
                                 )->get_message_prefix_for_log( ).
  ENDMETHOD.


  METHOD assert_header.
    cl_abap_unit_assert=>assert_equals(
        exp = VALUE symsg( msgid = i_msgid msgty = i_msgty msgno = i_msgno )
        act = VALUE symsg( msgid = header-msgid msgty = header-msgty msgno = header-msgno )
        msg = |Unexpected step header: { header-message_text }| ).
  ENDMETHOD.


  METHOD assert_message_exists.
    DATA(messages) = message_handler->get_messages( ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( messages[ msgid = i_msgid msgty = i_msgty msgno = i_msgno ] ) )
        msg = |Message { i_msgty }{ i_msgno }({ i_msgid }) not collected| ).
  ENDMETHOD.


  METHOD create_transition.
    cl_abap_unit_assert=>assert_not_initial( act = m_process_class
                                             msg = `INITIALIZE has not been called` ).

    " Loaded like in the log layer of the engine, the only user of this method
    " (GET_MESSAGE_PREFIX_FOR_LOG): a class that cannot be loaded is reported with
    " ZPRC_PROCESS_MESSAGE/021. PERFORM_TRANSITION runs the real core layer instead.
    DATA load_error TYPE symsg.
    DATA(process) = zcl_prc_process_loader=>get_process( EXPORTING i_class_name = m_process_class
                                                         IMPORTING e_error      = load_error ).
    IF process IS NOT BOUND.
      MESSAGE ID load_error-msgid TYPE 'I' NUMBER load_error-msgno
              WITH load_error-msgv1 load_error-msgv2 load_error-msgv3 load_error-msgv4
              INTO DATA(load_error_text).
      cl_abap_unit_assert=>fail( msg = load_error_text ).
    ENDIF.

    r_transition = process->get_transition_handler( i_start_state      = i_start_state
                                                    i_processed_object = m_processed_object_ext_id ).
    cl_abap_unit_assert=>assert_bound( act = r_transition
                                       msg = |No transition handler for start state { i_start_state }| ).

    r_transition->initialize( i_process_name              = m_process_name
                              i_processed_object_ext_id   = m_processed_object_ext_id
                              i_processed_object_ext_uuid = m_processed_object_ext_uuid
                              i_message_handler           = i_message_handler ).
  ENDMETHOD.


  METHOD create_step.
    IF m_simulate_save = abap_true.
      r_step = NEW zcl_prc_step_2_simulation( NEW zcl_prc_step_1_core( ) ).
    ELSE.
      r_step = NEW zcl_prc_step_1_core( ).
    ENDIF.
  ENDMETHOD.


  METHOD add_header_to_messages.
    MESSAGE ID header-msgid TYPE header-msgty NUMBER header-msgno
            WITH header-msgv1 header-msgv2 header-msgv3 header-msgv4
            INTO DATA(text) ##NEEDED.
    TRY.
        message_handler->add_message_from_sy( ).
      CATCH zcx_prc_unit_of_work_failed ##NO_HANDLER.
        " Cannot happen: the success header is S, I or W
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
