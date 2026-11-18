*"* use this source file for your ABAP unit test classes

CLASS ltc_handler DEFINITION DEFERRED.
CLASS zcl_prc_message_handler DEFINITION LOCAL FRIENDS ltc_handler.

"! Test exception with a T100 key and the severity of the RAISE ... MESSAGE statement
CLASS lcx_dyn DEFINITION INHERITING FROM cx_static_check FINAL.
  PUBLIC SECTION.
    INTERFACES if_t100_dyn_msg.
    METHODS constructor IMPORTING textid   LIKE if_t100_message=>t100key OPTIONAL
                                  previous LIKE previous OPTIONAL.
ENDCLASS.


CLASS lcx_dyn IMPLEMENTATION.
  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.
  ENDMETHOD.
ENDCLASS.


"! Unit tests of the handler on its own: API behavior that the scenario tests
"! (test repository, ZCL_PRC_TEST_MSG_HDLR / ZCL_PRC_TEST_MSG_MAPPER) do not cover.
"! Message class ZPRC_MSG_HANDLR_TEST, message 001 '&1 &2'.
CLASS ltc_handler DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zif_prc_message_handler.

    METHODS setup.

    METHODS initial_state            FOR TESTING.
    METHODS empty_bapi_result        FOR TESTING RAISING cx_static_check.
    METHODS order_of_arrival         FOR TESTING RAISING cx_static_check.
    METHODS variables_are_kept       FOR TESTING RAISING cx_static_check.
    METHODS chaining_returns_self    FOR TESTING RAISING cx_static_check.
    METHODS error_always_fails       FOR TESTING.
    METHODS failure_always_has_error FOR TESTING.
    METHODS engine_adds_without_fail FOR TESTING.
ENDCLASS.


CLASS ltc_handler IMPLEMENTATION.
  METHOD setup.
    cut = zcl_prc_msg_handler_for_test=>create( ).
  ENDMETHOD.

  METHOD initial_state.
    cl_abap_unit_assert=>assert_false( cut->has_failed( ) ).
    cl_abap_unit_assert=>assert_false( cut->has_errors( ) ).
    cl_abap_unit_assert=>assert_initial( cut->get_messages( ) ).
  ENDMETHOD.

  METHOD empty_bapi_result.
    cut->add_bapi_result( VALUE #( ) ).

    cl_abap_unit_assert=>assert_false( cut->has_failed( ) ).
    cl_abap_unit_assert=>assert_false( cut->has_errors( ) ).
    cl_abap_unit_assert=>assert_initial( cut->get_messages( ) ).
  ENDMETHOD.

  METHOD order_of_arrival.
    " Messages are kept in order of arrival, across lines of one call and across methods
    MESSAGE i001(zprc_msg_handlr_test) WITH '1' INTO DATA(lv_dummy) ##NEEDED.
    cut->add_message_from_sy( ).
    cut->add_bapi_result( VALUE #( type = 'I' id = 'ZPRC_MSG_HANDLR_TEST' number = '001'
                                   ( message_v1 = '2' )
                                   ( message_v1 = '3' ) ) ).
    MESSAGE w001(zprc_msg_handlr_test) WITH '4' INTO lv_dummy ##NEEDED.
    cut->add_message_from_sy( ).

    DATA(lt_messages) = cut->get_messages( ).
    cl_abap_unit_assert=>assert_equals( act = VALUE string_table( FOR m IN lt_messages ( CONV #( m-msgv1 ) ) )
                                        exp = VALUE string_table( ( `1` ) ( `2` ) ( `3` ) ( `4` ) ) ).
  ENDMETHOD.

  METHOD variables_are_kept.
    MESSAGE i001(zprc_msg_handlr_test) WITH 'V1' 'V2' 'V3' 'V4' INTO DATA(lv_dummy) ##NEEDED.
    cut->add_message_from_sy( ).

    DATA(lt_messages) = cut->get_messages( ).
    DATA(ls_message) = lt_messages[ 1 ].
    cl_abap_unit_assert=>assert_equals(
        act = CORRESPONDING symsg( ls_message )
        exp = VALUE symsg( msgty = 'I' msgid = 'ZPRC_MSG_HANDLR_TEST' msgno = '001'
                           msgv1 = 'V1' msgv2 = 'V2' msgv3 = 'V3' msgv4 = 'V4' ) ).
    cl_abap_unit_assert=>assert_not_initial( act = ls_message-message_text
                                             msg = 'Text is resolved when the message is added' ).
  ENDMETHOD.

  METHOD chaining_returns_self.
    MESSAGE i001(zprc_msg_handlr_test) INTO DATA(lv_dummy) ##NEEDED.

    cl_abap_unit_assert=>assert_equals( act = cut->add_message_from_sy( ) exp = cut ).
    cl_abap_unit_assert=>assert_equals( act = cut->add_message_from_text( i_message_text     = `text`
                                                                          i_message_severity = 'I' )
                                        exp = cut ).
    cl_abap_unit_assert=>assert_equals( act = cut->add_bapi_result( VALUE #( ) ) exp = cut ).
    cl_abap_unit_assert=>assert_equals( act = cut->add_EML_modify_result( ) exp = cut ).

    " An information exception does not fail, so the handler is returned
    TRY.
        RAISE EXCEPTION TYPE lcx_dyn MESSAGE i001(zprc_msg_handlr_test).
      CATCH lcx_dyn INTO DATA(info).
    ENDTRY.
    cl_abap_unit_assert=>assert_equals( act = cut->add_exception( info ) exp = cut ).
  ENDMETHOD.

  METHOD error_always_fails.
    " An error is a failure by default (I_FAIL_STEP = ABAP_TRUE); a failed step has errors
    MESSAGE e001(zprc_msg_handlr_test) WITH 'E' INTO DATA(lv_dummy) ##NEEDED.
    TRY.
        cut->add_message_from_sy( ).
        cl_abap_unit_assert=>fail( 'An error message must fail the step' ).
      CATCH zcx_prc_unit_of_work_failed ##NO_HANDLER.
        " expected
    ENDTRY.

    cl_abap_unit_assert=>assert_true( cut->has_failed( ) ).
    cl_abap_unit_assert=>assert_true( cut->has_errors( ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( cut->get_messages( ) ) exp = 1 ).
  ENDMETHOD.

  METHOD failure_always_has_error.
    " FAILED without any message: the handler adds ZPRC_PROCESS_MESSAGE/002, so a
    " failed step always has an error
    DATA failed TYPE RESPONSE FOR FAILED EARLY zr_prc_runtp.
    failed-run = VALUE #( ( %cid = 'A' ) ).
    TRY.
        cut->add_EML_modify_result( i_failed = failed ).
        cl_abap_unit_assert=>fail( 'FAILED must fail the step' ).
      CATCH zcx_prc_unit_of_work_failed ##NO_HANDLER.
        " expected
    ENDTRY.

    DATA(lt_messages) = cut->get_messages( ).
    cl_abap_unit_assert=>assert_equals(
        act = VALUE symsg( msgid = lt_messages[ 1 ]-msgid msgno = lt_messages[ 1 ]-msgno msgty = lt_messages[ 1 ]-msgty )
        exp = VALUE symsg( msgid = 'ZPRC_PROCESS_MESSAGE' msgno = '002' msgty = 'E' ) ).
  ENDMETHOD.

  METHOD engine_adds_without_fail.
    " Engine only (friends): an error is recorded without failing the step
    DATA(handler) = CAST zcl_prc_message_handler( cut ).
    handler->add_message_without_failing( VALUE #( msgty = 'E' msgid = 'ZPRC_MSG_HANDLR_TEST' msgno = '001' msgv1 = 'e' ) ).
    handler->add_exception_without_failing( NEW cx_sy_zerodivide( ) ).

    cl_abap_unit_assert=>assert_false( cut->has_failed( ) ).
    cl_abap_unit_assert=>assert_true( cut->has_errors( ) ).
    cl_abap_unit_assert=>assert_equals( act = lines( cut->get_messages( ) ) exp = 2 ).
  ENDMETHOD.
ENDCLASS.
