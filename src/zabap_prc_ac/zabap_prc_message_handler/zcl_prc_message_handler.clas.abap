"! <p class="shorttext synchronized">Standard implementation of ZIF_PRC_MESSAGE_HANDLER</p>
"!
"! One instance per step, created by the processing engine and handed to the
"! transition. The rules (failure, findings, severities) are documented at
"! ZIF_PRC_MESSAGE_HANDLER. The step header is not a concept of the handler:
"! the engine chooses it (ZCL_PRC_STEP_HEADER).
"!
"! Only the engine creates handlers (global friends). A transition always
"! works with the handler it is given; tests use ZCL_PRC_MSG_HANDLER_FOR_TEST.
"!
"! <h2>Engine only: adding without failing</h2>
"! Through the public interface every error fails the step unless the caller
"! declares it a finding (I_FAIL_STEP = ABAP_FALSE). The engine itself has to
"! record errors without failing - the failure message after the failure, the
"! abort of a step session, an unexpected exception, messages that arrive
"! after the commit. The ADD_..._WITHOUT_FAILING methods are private and
"! reserved to the friends of the engine.
"!
"! Every message entering the handler passes TO_STORED_MESSAGE: severity
"! normalized, text resolved. Messages are kept in order of arrival.
CLASS zcl_prc_message_handler DEFINITION PUBLIC FINAL CREATE PRIVATE
  GLOBAL FRIENDS zcl_prc_object_step_loop
                 zcl_prc_step_8_isolation_task
                 zcl_prc_step_log
                 zcl_prc_msg_handler_for_test
                 zcl_prc_step_header
                 zcl_prc_step_4_commit
                 zcl_prc_step_6_unexpected
                 zcl_prc_step_8_isolation.

  PUBLIC SECTION.
    INTERFACES zif_prc_message_handler.

  PRIVATE SECTION.
    DATA mt_messages TYPE zif_prc_message_handler=>tt_messages.
    DATA mv_failed   TYPE abap_bool.

    "! Creates a fresh, empty handler for one step (engine and tests only).
    "!
    "! @parameter r_message_handler | New handler.
    CLASS-METHODS create_message_handler RETURNING VALUE(r_message_handler) TYPE REF TO zif_prc_message_handler.

    "! Engine only: adds one message, also an error, without failing the step.
    "!
    "! @parameter i_message | Message as delivered by the caller.
    METHODS add_message_without_failing IMPORTING i_message TYPE symsg.

    "! Engine only: adds an exception with its PREVIOUS chain, also an error,
    "! without failing the step.
    "!
    "! @parameter i_exception | Exception to be recorded.
    METHODS add_exception_without_failing IMPORTING i_exception TYPE REF TO cx_root.

    "! Engine only: adds the messages of an EML REPORTED response, also errors,
    "! without failing the step - e.g. messages that arrive after the commit.
    "!
    "! @parameter i_reported | REPORTED response.
    METHODS add_reported_without_failing IMPORTING i_reported TYPE any.

    "! An operation reported an error: fails the step, or records a finding.
    "!
    "! @parameter i_fail_step                 | ABAP_TRUE: fail the step; ABAP_FALSE: a finding.
    "! @raising   zcx_prc_unit_of_work_failed | I_FAIL_STEP is set.
    METHODS on_error IMPORTING i_fail_step TYPE abap_bool
                     RAISING   zcx_prc_unit_of_work_failed.

    "! Marks the step as failed and raises.
    "! Without any error message, ZPRC_PROCESS_MESSAGE/002 is added first, so a
    "! failed step always has an error.
    "!
    "! @raising zcx_prc_unit_of_work_failed | Always.
    METHODS fail RAISING zcx_prc_unit_of_work_failed.

    "! Adds ZPRC_PROCESS_MESSAGE/002 if no error has been collected yet.
    METHODS ensure_error.

    "! Stores one message.
    "!
    "! @parameter i_message | Message as delivered by the caller.
    METHODS append_message IMPORTING i_message TYPE symsg.

    "! Stores several messages in order.
    "!
    "! @parameter i_messages | Messages as delivered by the caller.
    METHODS append_messages IMPORTING i_messages TYPE zcl_prc_message_mapper=>tt_messages.

    "! Message as stored: severity normalized, text resolved.
    "! The single place where a message entering the handler is normalized.
    "!
    "! @parameter i_message | Message as delivered by the caller.
    "! @parameter r_message | Message as stored.
    METHODS to_stored_message IMPORTING i_message        TYPE symsg
                              RETURNING VALUE(r_message) TYPE zif_prc_message_handler=>ty_message_details.

    "! The exception and its PREVIOUS chain as messages: the innermost cause
    "! first, the exception itself last.
    "!
    "! @parameter i_exception | Exception.
    "! @parameter r_messages  | Messages, severity not yet normalized.
    METHODS exception_chain_to_messages IMPORTING i_exception       TYPE REF TO cx_root
                                        RETURNING VALUE(r_messages) TYPE zcl_prc_message_mapper=>tt_messages.

    "! One exception as message: its T100 key if it has one, else its text as
    "! SY 499; severity from IF_T100_DYN_MSG / IF_ABAP_BEHV_MESSAGE, else E.
    "!
    "! @parameter i_exception | Exception, without its PREVIOUS chain.
    "! @parameter r_message   | Message, severity not yet normalized.
    METHODS exception_to_message IMPORTING i_exception      TYPE REF TO cx_root
                                 RETURNING VALUE(r_message) TYPE symsg.

    "! ABAP_TRUE if at least one message is an error after normalization.
    "!
    "! @parameter i_messages | Messages as delivered by the caller.
    "! @parameter r_result   | ABAP_TRUE if an E, A, X or blank severity is contained.
    METHODS contains_error IMPORTING i_messages      TYPE zcl_prc_message_mapper=>tt_messages
                           RETURNING VALUE(r_result) TYPE abap_bool.

    "! Internal severity of a message: W, I and S are kept, everything else
    "! (E, A, X, blank) becomes E.
    "!
    "! @parameter i_msgty | Severity as delivered by the caller.
    "! @parameter r_msgty | W, I, S or E.
    METHODS normalize_severity IMPORTING i_msgty        TYPE symsgty
                               RETURNING VALUE(r_msgty) TYPE symsgty.
    "! The message in SY-MSGTY, SY-MSGID, SY-MSGNO and SY-MSGV1 to SY-MSGV4, read field
    "! by field (CORRESPONDING #( sy ) would access the whole SY structure).
    "!
    "! @parameter r_message | Message in SY.
    METHODS message_from_sy RETURNING VALUE(r_message) TYPE symsg.
ENDCLASS.


CLASS zcl_prc_message_handler IMPLEMENTATION.
  METHOD append_message.
    APPEND to_stored_message( i_message ) TO mt_messages.
  ENDMETHOD.

  METHOD append_messages.
    LOOP AT i_messages INTO DATA(ls_message).
      append_message( ls_message ).
    ENDLOOP.
  ENDMETHOD.

  METHOD to_stored_message.
    r_message = CORRESPONDING #( i_message ).
    r_message-msgty = normalize_severity( r_message-msgty ).

    MESSAGE ID r_message-msgid
            TYPE r_message-msgty
            NUMBER r_message-msgno
            WITH r_message-msgv1
                 r_message-msgv2
                 r_message-msgv3
                 r_message-msgv4
            INTO r_message-message_text.
  ENDMETHOD.

  METHOD exception_chain_to_messages.
    DATA lt_chain TYPE STANDARD TABLE OF REF TO cx_root WITH EMPTY KEY.
    DATA(lo_exception) = i_exception.
    WHILE lo_exception IS BOUND.
      INSERT lo_exception INTO lt_chain INDEX 1.
      lo_exception = lo_exception->previous.
    ENDWHILE.

    LOOP AT lt_chain INTO lo_exception.
      APPEND CORRESPONDING #( exception_to_message( lo_exception ) ) TO r_messages.
    ENDLOOP.
  ENDMETHOD.

  METHOD exception_to_message.
    IF i_exception IS INSTANCE OF if_t100_message.
      " T100 key of the exception; the variables are named by ATTR1-4
      DATA(ls_key) = CAST if_t100_message( i_exception )->t100key.
      r_message-msgid = ls_key-msgid.
      r_message-msgno = ls_key-msgno.

      DATA(lt_attributes) = VALUE string_table( ( ls_key-attr1 ) ( ls_key-attr2 )
                                                ( ls_key-attr3 ) ( ls_key-attr4 ) ).
      DATA lt_values TYPE STANDARD TABLE OF symsgv WITH EMPTY KEY.
      LOOP AT lt_attributes INTO DATA(lv_attribute).
        DATA(lv_value) = VALUE symsgv( ).
        IF lv_attribute IS NOT INITIAL.
          ASSIGN i_exception->(lv_attribute) TO FIELD-SYMBOL(<lv_attribute>).
          IF sy-subrc = 0.
            lv_value = |{ <lv_attribute> }|.
          ENDIF.
        ENDIF.
        APPEND lv_value TO lt_values.
      ENDLOOP.
      r_message-msgv1 = lt_values[ 1 ].
      r_message-msgv2 = lt_values[ 2 ].
      r_message-msgv3 = lt_values[ 3 ].
      r_message-msgv4 = lt_values[ 4 ].
    ELSE.
      r_message = zcl_prc_message_mapper=>from_text( text  = i_exception->get_text( )
                                                     msgty = 'E' ).
    ENDIF.
    r_message-msgty = 'E'.

    IF i_exception IS INSTANCE OF if_t100_dyn_msg.
      DATA(lv_msgty) = CAST if_t100_dyn_msg( i_exception )->msgty.
      IF lv_msgty IS NOT INITIAL.
        r_message-msgty = lv_msgty.
      ENDIF.
    ENDIF.

    IF i_exception IS INSTANCE OF if_abap_behv_message.
      r_message-msgty = SWITCH #( CAST if_abap_behv_message( i_exception )->m_severity
                                  WHEN if_abap_behv_message=>severity-success     THEN 'S'
                                  WHEN if_abap_behv_message=>severity-information THEN 'I'
                                  WHEN if_abap_behv_message=>severity-warning     THEN 'W'
                                  ELSE 'E' ).
    ENDIF.
  ENDMETHOD.

  METHOD contains_error.
    LOOP AT i_messages INTO DATA(ls_message).
      IF normalize_severity( ls_message-msgty ) = 'E'.
        r_result = abap_true.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD create_message_handler.
    r_message_handler = NEW zcl_prc_message_handler( ).
  ENDMETHOD.

  METHOD add_message_without_failing.
    append_message( i_message ).
  ENDMETHOD.

  METHOD add_exception_without_failing.
    append_messages( exception_chain_to_messages( i_exception ) ).
  ENDMETHOD.

  METHOD add_reported_without_failing.
    append_messages( zcl_prc_message_mapper=>from_reported( i_reported ) ).
  ENDMETHOD.

  METHOD on_error.
    IF i_fail_step = abap_true.
      fail( ).
    ENDIF.
    " A finding: recorded only, the step does not fail. It always has an error
    " (e.g. FAILED without message), so the result layer recognizes it.
    ensure_error( ).
  ENDMETHOD.

  METHOD fail.
    " A failed unit of work always has an error
    ensure_error( ).
    mv_failed = abap_true.
    RAISE EXCEPTION NEW zcx_prc_unit_of_work_failed( ).
  ENDMETHOD.

  METHOD ensure_error.
    IF NOT line_exists( mt_messages[ msgty = 'E' ] ).
      MESSAGE e002(zprc_process_message) INTO DATA(dummy) ##NEEDED.
      append_message( message_from_sy( ) ).
    ENDIF.
  ENDMETHOD.

  METHOD normalize_severity.
    r_msgty = COND #( WHEN i_msgty = 'W' OR i_msgty = 'I' OR i_msgty = 'S'
                      THEN i_msgty
                      ELSE 'E' ).
  ENDMETHOD.

  METHOD zif_prc_message_handler~add_bapi_result.
    r_message_handler = me.

    DATA(messages) = zcl_prc_message_mapper=>from_bapiret( i_bapiret ).
    append_messages( messages ).
    IF contains_error( messages ).
      on_error( i_fail_step ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_prc_message_handler~add_EML_modify_result.
    r_message_handler = me.

    IF i_reported IS SUPPLIED.
      DATA(messages) = zcl_prc_message_mapper=>from_reported( i_reported ).
      append_messages( messages ).
      IF contains_error( messages ).
        on_error( i_fail_step ).
      ENDIF.
    ENDIF.

    IF i_failed IS SUPPLIED AND zcl_prc_message_mapper=>is_failed( i_failed ) = abap_true.
      on_error( i_fail_step ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_prc_message_handler~add_exception.
    r_message_handler = me.

    DATA(messages) = exception_chain_to_messages( i_exception ).
    append_messages( messages ).
    IF contains_error( messages ).
      on_error( i_fail_step ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_prc_message_handler~add_message_from_sy.
    r_message_handler = me.

    DATA(message) = message_from_sy( ).
    append_message( message ).
    IF normalize_severity( message-msgty ) = 'E'.
      on_error( i_fail_step ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_prc_message_handler~add_message_from_text.
    r_message_handler = me.

    DATA(message) = zcl_prc_message_mapper=>from_text( text  = i_message_text
                                                       msgty = i_message_severity ).
    append_message( message ).
    IF normalize_severity( message-msgty ) = 'E'.
      on_error( i_fail_step ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_prc_message_handler~get_messages.
    r_messages = mt_messages.
  ENDMETHOD.

  METHOD zif_prc_message_handler~has_errors.
    " A failure or a finding - every error is stored as E
    r_has_errors = xsdbool( line_exists( mt_messages[ msgty = 'E' ] ) ).
  ENDMETHOD.


  METHOD zif_prc_message_handler~has_failed.
    r_has_failed = mv_failed.
  ENDMETHOD.
  METHOD message_from_sy.
    r_message = VALUE #( msgty = sy-msgty
                         msgid = sy-msgid
                         msgno = sy-msgno
                         msgv1 = sy-msgv1
                         msgv2 = sy-msgv2
                         msgv3 = sy-msgv3
                         msgv4 = sy-msgv4 ).
  ENDMETHOD.
ENDCLASS.
