"! <p class="shorttext synchronized">Standard implementation of ZIF_PRC_MESSAGE_HANDLER</p>
"!
"! One instance per unit of work.
"!
"! Severities: W, I and S are kept. Everything else (E, A, X, ...) is treated
"! and stored as error E, see NORMALIZE_SEVERITY.
"!
"! Header: the last message of the highest severity E > S > W > I. A failure
"! without any error message adds ZPRC_PROCESS_MESSAGE/002.
"! <p class="shorttext synchronized">Standard implementation of ZIF_PRC_MESSAGE_HANDLER</p>
"!
"! One instance per step, created by the processing engine and handed to the
"! transition. The rules (failure, severities, header) are documented at
"! ZIF_PRC_MESSAGE_HANDLER.
"!
"! Every message entering the handler passes TO_STORED_MESSAGE: severity
"! normalized, text resolved. Messages are kept in order of arrival; the
"! header is updated with every message.
CLASS zcl_prc_message_handler DEFINITION PUBLIC FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES zif_prc_message_handler.

    "! Creates a fresh, empty handler for one step.
    "!
    "! @parameter r_message_handler | New handler.
    CLASS-METHODS create_message_handler RETURNING VALUE(r_message_handler) TYPE REF TO zif_prc_message_handler.

  PRIVATE SECTION.
    DATA ms_header   TYPE zif_prc_message_handler=>ty_message_details.
    DATA mt_messages TYPE zif_prc_message_handler=>tt_messages.
    DATA mv_failed   TYPE abap_bool.

    "! Marks the step as failed and raises.
    "! Without any error message, ZPRC_PROCESS_MESSAGE/002 is added first, so a
    "! failed step never ends with an S/W/I header.
    "!
    "! @raising zcx_prc_unit_of_work_failed | Always.
    METHODS fail RAISING zcx_prc_unit_of_work_failed.

    "! Stores one message and updates the header.
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

    "! Rank of a normalized severity for the header: E 4, S 3, W 2, I 1.
    "!
    "! @parameter i_msgty | Normalized severity (E, S, W, I).
    "! @parameter r_rank  | Rank; 0 for an initial severity.
    METHODS severity_rank IMPORTING i_msgty       TYPE symsgty
                          RETURNING VALUE(r_rank) TYPE i.
ENDCLASS.


CLASS zcl_prc_message_handler IMPLEMENTATION.
  METHOD append_message.
    APPEND to_stored_message( i_message ) TO mt_messages ASSIGNING FIELD-SYMBOL(<fs>).

    " Header: last message of the highest severity
    IF severity_rank( <fs>-msgty ) >= severity_rank( ms_header-msgty ).
      ms_header = <fs>.
    ENDIF.
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

  METHOD fail.
    " A failed unit of work never ends with an S/W/I header
    IF NOT line_exists( mt_messages[ msgty = 'E' ] ).
      MESSAGE e002(zprc_process_message) INTO DATA(lv_dummy) ##NEEDED.
      append_message( CORRESPONDING #( sy ) ).
    ENDIF.

    mv_failed = abap_true.
    RAISE EXCEPTION NEW zcx_prc_unit_of_work_failed( ).
  ENDMETHOD.

  METHOD normalize_severity.
    r_msgty = COND #( WHEN i_msgty = 'W' OR i_msgty = 'I' OR i_msgty = 'S'
                      THEN i_msgty
                      ELSE 'E' ).
  ENDMETHOD.

  METHOD severity_rank.
    r_rank = SWITCH #( i_msgty
                       WHEN 'E' THEN 4
                       WHEN 'S' THEN 3
                       WHEN 'W' THEN 2
                       WHEN 'I' THEN 1
                       ELSE 0 ).
  ENDMETHOD.

  METHOD zif_prc_message_handler~add_bapi_result.
    r_message_handler = me.

    DATA(lt_msg) = zcl_prc_message_mapper=>from_bapiret( i_bapiret ).
    append_messages( lt_msg ).
    IF i_fail_on_error_message = abap_true AND contains_error( lt_msg ).
      fail( ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_prc_message_handler~add_EML_modify_result.
    r_message_handler = me.

    IF i_reported IS SUPPLIED.
      DATA(lt_msg) = zcl_prc_message_mapper=>from_reported( i_reported ).
      append_messages( lt_msg ).
      IF i_fail_on_error_message = abap_true AND contains_error( lt_msg ).
        fail( ).
      ENDIF.
    ENDIF.

    IF i_failed IS SUPPLIED AND zcl_prc_message_mapper=>is_failed( i_failed ) = abap_true.
      fail( ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_prc_message_handler~add_exception.
    r_message_handler = me.

    " Innermost cause first, the exception itself last
    DATA lt_chain TYPE STANDARD TABLE OF REF TO cx_root WITH EMPTY KEY.
    DATA(lo_exception) = i_exception.
    WHILE lo_exception IS BOUND.
      INSERT lo_exception INTO lt_chain INDEX 1.
      lo_exception = lo_exception->previous.
    ENDWHILE.

    DATA lt_msg TYPE zcl_prc_message_mapper=>tt_messages.
    LOOP AT lt_chain INTO lo_exception.
      APPEND CORRESPONDING #( exception_to_message( lo_exception ) ) TO lt_msg.
    ENDLOOP.

    append_messages( lt_msg ).
    IF i_fail_on_error_message = abap_true AND contains_error( lt_msg ).
      fail( ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_prc_message_handler~add_message_from_sy.
    r_message_handler = me.

    DATA(ls_msg) = CORRESPONDING symsg( sy ).
    append_message( ls_msg ).
    IF i_fail_on_error_message = abap_true AND normalize_severity( ls_msg-msgty ) = 'E'.
      fail( ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_prc_message_handler~add_message_from_text.
    r_message_handler = me.

    DATA(ls_msg) = zcl_prc_message_mapper=>from_text( text  = i_message_text
                                                      msgty = i_message_severity ).
    append_message( ls_msg ).
    IF i_fail_on_error_message = abap_true AND normalize_severity( ls_msg-msgty ) = 'E'.
      fail( ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_prc_message_handler~get_header.
    r_message = ms_header.
  ENDMETHOD.

  METHOD zif_prc_message_handler~get_messages.
    r_messages = mt_messages.
  ENDMETHOD.

  METHOD zif_prc_message_handler~has_errors.
    r_has_errors = mv_failed.
  ENDMETHOD.
ENDCLASS.

