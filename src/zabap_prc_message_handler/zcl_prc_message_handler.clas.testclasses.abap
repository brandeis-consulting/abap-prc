*"* use this source file for your ABAP unit test classes
*
*CLASS ltc_handler DEFINITION FINAL
*  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
*
*  PRIVATE SECTION.
*    "! generic message class, &1&2&3&4
*    CONSTANTS co_msgid TYPE symsgid VALUE 'ZPRC_MSG_HANDLR_TEST'.
*    CONSTANTS co_msgno TYPE symsgno VALUE '001'.
*
*    DATA mo_cut TYPE REF TO zif_prc_message_handler.
*
*    METHODS setup.
*
*    METHODS bapi_line
*
*      IMPORTING !type         TYPE symsgty
*
*                !id           TYPE symsgid DEFAULT co_msgid
*
*                !number       TYPE symsgno DEFAULT co_msgno
*
*                v1            TYPE string  OPTIONAL
*
*                !text         TYPE string  OPTIONAL
*
*      RETURNING VALUE(result) TYPE zif_prc_message_handler=>tt_bapiret2.
*
*    " --- initial state -------------------------------------------------
*
*    METHODS initial_state                FOR TESTING.
*
*    " --- failure header ------------------------------------------------
*
*    METHODS header_from_sy               FOR TESTING RAISING cx_static_check.
*
*    METHODS header_explicit              FOR TESTING RAISING cx_static_check.
*
*    METHODS header_is_no_detail          FOR TESTING RAISING cx_static_check.
*
*    METHODS header_can_be_refined        FOR TESTING RAISING cx_static_check.
*
*    " --- own messages via SY -------------------------------------------
*
*    METHODS sy_success_is_collected      FOR TESTING RAISING cx_static_check.
*
*    METHODS sy_error_fails_by_default    FOR TESTING.
*
*    METHODS sy_error_can_be_suppressed   FOR TESTING RAISING cx_static_check.
*
*    METHODS sy_abort_always_fails        FOR TESTING.
*
*    METHODS sy_variables_are_kept        FOR TESTING RAISING cx_static_check.
*
*    " --- BAPI results ---------------------------------------------------
*
*    METHODS bapi_empty_is_ok             FOR TESTING RAISING cx_static_check.
*
*    METHODS bapi_info_is_collected       FOR TESTING RAISING cx_static_check.
*
*    METHODS bapi_error_fails             FOR TESTING.
*
*    METHODS bapi_error_can_be_suppressed FOR TESTING RAISING cx_static_check.
*
*    METHODS bapi_abort_always_fails      FOR TESTING.
*
*    METHODS bapi_t100_is_kept            FOR TESTING RAISING cx_static_check.
*
*    METHODS bapi_free_text_becomes_sy499 FOR TESTING RAISING cx_static_check.
*
*    METHODS bapi_order_is_kept           FOR TESTING RAISING cx_static_check.
*
*    " --- EML results without a BO --------------------------------------
*
*    METHODS eml_initial_failed_is_ok     FOR TESTING RAISING cx_static_check.
*
*    METHODS eml_filled_failed_fails      FOR TESTING.
*
*    METHODS eml_unbound_entries_ignored  FOR TESTING RAISING cx_static_check.
*
*    METHODS eml_empty_entries_ignored    FOR TESTING RAISING cx_static_check.
*
*    METHODS eml_dynamic_failed_fails     FOR TESTING.
*
*    " --- closing --------------------------------------------------------
*
*    METHODS close_ok_seals               FOR TESTING RAISING cx_static_check.
*
*    METHODS close_failed_raises          FOR TESTING.
*
*    METHODS close_failed_sets_header     FOR TESTING.
*
*    " --- sealing --------------------------------------------------------
*
*    METHODS add_after_close_is_misuse    FOR TESTING RAISING cx_static_check.
*
*    METHODS close_after_close_is_misuse  FOR TESTING RAISING cx_static_check.
*
*    METHODS close_ok_after_error         FOR TESTING.
*
*    " --- chaining -------------------------------------------------------
*
*    METHODS chaining_returns_self        FOR TESTING RAISING cx_static_check.
*
*ENDCLASS.
*
*
*CLASS ltc_handler IMPLEMENTATION.
*  METHOD setup.
*    mo_cut = zcl_prc_message_handler=>create_message_handler( ).
*  ENDMETHOD.
*
*  METHOD bapi_line.
*    result = VALUE #( ( type       = type
*
*                        id         = id
*
*                        number     = number
*
*                        message_v1 = v1
*
*                        message    = text ) ).
*
*    IF id IS INITIAL.
*
*      CLEAR result[ 1 ]-number.
*
*    ENDIF.
*  ENDMETHOD.
*
*  METHOD initial_state.
*    cl_abap_unit_assert=>assert_false( mo_cut->has_errors( ) ).
*
*    cl_abap_unit_assert=>assert_false( mo_cut->is_closed( ) ).
*
*    cl_abap_unit_assert=>assert_initial( mo_cut->get_header( ) ).
*
*    cl_abap_unit_assert=>assert_initial( mo_cut->get_messages( ) ).
*  ENDMETHOD.
*
*  METHOD header_from_sy.
*    MESSAGE e001(zprc_msg_handlr_test) WITH 'EQUI' 'TRUCK' INTO DATA(lv_dummy) ##NEEDED.
*
*    mo_cut->set_failure_header( CORRESPONDING #( sy ) ).
*
*    DATA(ls_header) = mo_cut->get_header( ).
*
*    cl_abap_unit_assert=>assert_equals( exp = 'E'
*                                        act = ls_header-msgty ).
*
*    cl_abap_unit_assert=>assert_equals( exp = co_msgid
*                                        act = ls_header-msgid ).
*
*    cl_abap_unit_assert=>assert_equals( exp = co_msgno
*                                        act = ls_header-msgno ).
*
*    cl_abap_unit_assert=>assert_equals( exp = 'EQUI'
*                                        act = ls_header-msgv1 ).
*
*    cl_abap_unit_assert=>assert_equals( exp = 'TRUCK'
*                                        act = ls_header-msgv2 ).
*  ENDMETHOD.
*
*  METHOD header_explicit.
*    DATA(ls_in) = VALUE symsg( msgty = 'E'
*                               msgid = 'ZX'
*                               msgno = '042'
*                               msgv1 = 'A' ).
*
*    mo_cut->set_failure_header( ls_in ).
*    DATA(ls_header) = CORRESPONDING symsg( mo_cut->get_header( ) ).
*    cl_abap_unit_assert=>assert_equals( exp = ls_in
*                                        act = ls_header ).
*  ENDMETHOD.
*
*  METHOD header_is_no_detail.
*    " The header is not a collected message and must never fail the handler,
*
*    " even though it is an error message.
*
*    MESSAGE e001(zprc_msg_handlr_test) WITH 'X' INTO DATA(lv_dummy) ##NEEDED.
*
*    mo_cut->set_failure_header( ).
*
*    cl_abap_unit_assert=>assert_initial( mo_cut->get_messages( ) ).
*
*    cl_abap_unit_assert=>assert_false( mo_cut->has_errors( ) ).
*
*    cl_abap_unit_assert=>assert_false( mo_cut->is_closed( ) ).
*  ENDMETHOD.
*
*  METHOD header_can_be_refined.
*    mo_cut->set_failure_header( VALUE #( msgty = 'E'
*                                         msgid = 'ZX'
*                                         msgno = '001' ) ).
*
*    mo_cut->set_failure_header( VALUE #( msgty = 'E'
*                                         msgid = 'ZX'
*                                         msgno = '002' ) ).
*
*    cl_abap_unit_assert=>assert_equals( exp = '002'
*                                        act = mo_cut->get_header( )-msgno ).
*  ENDMETHOD.
*
*  METHOD sy_success_is_collected.
*    MESSAGE s001(zprc_msg_handlr_test) WITH 'OK' INTO DATA(lv_dummy) ##NEEDED.
*
*    mo_cut->add_message_from_sy( ).
*
*    cl_abap_unit_assert=>assert_equals( exp = 1
*                                        act = lines( mo_cut->get_messages( ) ) ).
*
*    cl_abap_unit_assert=>assert_false( mo_cut->has_errors( ) ).
*
*    cl_abap_unit_assert=>assert_false( mo_cut->is_closed( ) ).
*  ENDMETHOD.
*
*  METHOD sy_error_fails_by_default.
*    TRY.
*
*        MESSAGE e001(zprc_msg_handlr_test) WITH 'BOOM' INTO DATA(lv_dummy) ##NEEDED.
*
*        mo_cut->add_message_from_sy( ).
*
*        cl_abap_unit_assert=>fail( 'Expected ZCX_PRC_UNIT_OF_WORK_FAILED' ).
*
*      CATCH zcx_prc_unit_of_work_failed ##NO_HANDLER.
*
*    ENDTRY.
*
*    cl_abap_unit_assert=>assert_true( mo_cut->has_errors( ) ).
*
*    cl_abap_unit_assert=>assert_true( mo_cut->is_closed( ) ).
*
*    " The message is collected before the raise
*
*    cl_abap_unit_assert=>assert_equals( exp = 1
*                                        act = lines( mo_cut->get_messages( ) ) ).
*  ENDMETHOD.
*
*  METHOD sy_error_can_be_suppressed.
*    MESSAGE e001(zprc_msg_handlr_test) WITH 'SOFT' INTO DATA(lv_dummy) ##NEEDED.
*
*    mo_cut->add_message_from_sy( i_fail_on_error_message = abap_false ).
*
*    cl_abap_unit_assert=>assert_false( mo_cut->has_errors( ) ).
*
*    cl_abap_unit_assert=>assert_equals( exp = 1
*                                        act = lines( mo_cut->get_messages( ) ) ).
*  ENDMETHOD.
*
*  METHOD sy_abort_always_fails.
*    TRY.
*
*        MESSAGE a001(zprc_msg_handlr_test) WITH 'DEAD' INTO DATA(lv_dummy) ##NEEDED.
*
*        mo_cut->add_message_from_sy( i_fail_on_error_message = abap_false ).
*
*        cl_abap_unit_assert=>fail( 'Severity A must fail regardless of the flag' ).
*
*      CATCH zcx_prc_unit_of_work_failed ##NO_HANDLER.
*
*    ENDTRY.
*
*    cl_abap_unit_assert=>assert_true( mo_cut->has_errors( ) ).
*  ENDMETHOD.
*
*  METHOD sy_variables_are_kept.
*    MESSAGE i001(zprc_msg_handlr_test) WITH 'V1' 'V2' 'V3' 'V4' INTO DATA(lv_dummy) ##NEEDED.
*
*    mo_cut->add_message_from_sy( ).
*
*    DATA(lt_msg) = mo_cut->get_messages( ).
*    DATA(ls_msg) = lt_msg[ 1 ].
*
*    cl_abap_unit_assert=>assert_equals( exp = 'I'
*                                        act = ls_msg-msgty ).
*
*    cl_abap_unit_assert=>assert_equals( exp = co_msgid
*                                        act = ls_msg-msgid ).
*
*    cl_abap_unit_assert=>assert_equals( exp = co_msgno
*                                        act = ls_msg-msgno ).
*
*    cl_abap_unit_assert=>assert_equals( exp = 'V1'
*                                        act = ls_msg-msgv1 ).
*
*    cl_abap_unit_assert=>assert_equals( exp = 'V4'
*                                        act = ls_msg-msgv4 ).
*  ENDMETHOD.
*
*  METHOD bapi_empty_is_ok.
*    mo_cut->add_bapi_result( VALUE zif_prc_message_handler=>tt_bapiret2( ) ).
*
*    cl_abap_unit_assert=>assert_false( mo_cut->has_errors( ) ).
*
*    cl_abap_unit_assert=>assert_initial( mo_cut->get_messages( ) ).
*  ENDMETHOD.
*
*  METHOD bapi_info_is_collected.
*    mo_cut->add_bapi_result( bapi_line( type = 'S'
*                                        v1   = 'A' ) ).
*
*    mo_cut->add_bapi_result( bapi_line( type = 'W'
*                                        v1   = 'B' ) ).
*
*    mo_cut->add_bapi_result( bapi_line( type = 'I'
*                                        v1   = 'C' ) ).
*
*    cl_abap_unit_assert=>assert_equals( exp = 3
*                                        act = lines( mo_cut->get_messages( ) ) ).
*
*    cl_abap_unit_assert=>assert_false( mo_cut->has_errors( ) ).
*  ENDMETHOD.
*
*  METHOD bapi_error_fails.
*    TRY.
*
*        mo_cut->add_bapi_result( bapi_line( type = 'E'
*                                            v1   = 'X' ) ).
*
*        cl_abap_unit_assert=>fail( 'Expected ZCX_PRC_UNIT_OF_WORK_FAILED' ).
*
*      CATCH zcx_prc_unit_of_work_failed ##NO_HANDLER.
*
*    ENDTRY.
*
*    cl_abap_unit_assert=>assert_true( mo_cut->has_errors( ) ).
*
*    cl_abap_unit_assert=>assert_equals( exp = 1
*                                        act = lines( mo_cut->get_messages( ) ) ).
*  ENDMETHOD.
*
*  METHOD bapi_error_can_be_suppressed.
*    mo_cut->add_bapi_result( i_bapiret               = bapi_line( type = 'E'
*                                                                  v1   = 'X' )
*
*                             i_fail_on_error_message = abap_false ).
*
*    cl_abap_unit_assert=>assert_false( mo_cut->has_errors( ) ).
*
*    cl_abap_unit_assert=>assert_equals( exp = 1
*                                        act = lines( mo_cut->get_messages( ) ) ).
*  ENDMETHOD.
*
*  METHOD bapi_abort_always_fails.
*    TRY.
*
*        mo_cut->add_bapi_result( i_bapiret               = bapi_line( type = 'A' )
*
*                                 i_fail_on_error_message = abap_false ).
*
*        cl_abap_unit_assert=>fail( 'Severity A must fail regardless of the flag' ).
*
*      CATCH zcx_prc_unit_of_work_failed ##NO_HANDLER.
*
*    ENDTRY.
*  ENDMETHOD.
*
*  METHOD bapi_t100_is_kept.
*    mo_cut->add_bapi_result( VALUE #( ( type       = 'W'
*
*                                        id         = 'ZX'
*
*                                        number     = '123'
*
*                                        message_v1 = 'P1'
*
*                                        message_v2 = 'P2'
*
*                                        message_v3 = 'P3'
*
*                                        message_v4 = 'P4' ) ) ).
*
*    DATA(lt_msg) = mo_cut->get_messages( ).
*    DATA(ls_msg) = lt_msg[ 1 ].
*    cl_abap_unit_assert=>assert_equals( exp = 'ZX'
*                                        act = ls_msg-msgid ).
*
*    cl_abap_unit_assert=>assert_equals( exp = '123'
*                                        act = ls_msg-msgno ).
*
*    cl_abap_unit_assert=>assert_equals( exp = 'P3'
*                                        act = ls_msg-msgv3 ).
*  ENDMETHOD.
*
*  METHOD bapi_free_text_becomes_sy499.
*    " A BAPI line without a message class carries text only. It must survive
*    " as SY 499 with the text spread over the four variables.
*
*    mo_cut->add_bapi_result(
*        VALUE #(
*            ( type    = 'I'
*              message = 'Equipment could not be assigned to the truck, because the message is way to long to survive the 50 charactor!' ) ) ).
*
*    DATA(lt_msg) = mo_cut->get_messages( ).
*    DATA(ls_msg) = lt_msg[ 1 ].
*
*    cl_abap_unit_assert=>assert_equals( exp = 'SY'
*                                        act = ls_msg-msgid ).
*
*    cl_abap_unit_assert=>assert_equals( exp = '499'
*                                        act = ls_msg-msgno ).
*
*    cl_abap_unit_assert=>assert_equals( exp = 'I'
*                                        act = ls_msg-msgty ).
*
*    cl_abap_unit_assert=>assert_not_initial( ls_msg-msgv1 ).
*
*    cl_abap_unit_assert=>assert_not_initial( ls_msg-msgv2 ).
*  ENDMETHOD.
*
*  METHOD bapi_order_is_kept.
*    mo_cut->add_bapi_result( VALUE #( type = 'I'
*                                      id   = 'ZX'
*                                      ( number = '001' )
*
*                                      ( number = '002' )
*
*                                      ( number = '003' ) ) ).
*
*    DATA(lt_msg) = mo_cut->get_messages( ).
*
*    cl_abap_unit_assert=>assert_equals( exp = '001'
*                                        act = lt_msg[ 1 ]-msgno ).
*
*    cl_abap_unit_assert=>assert_equals( exp = '002'
*                                        act = lt_msg[ 2 ]-msgno ).
*
*    cl_abap_unit_assert=>assert_equals( exp = '003'
*                                        act = lt_msg[ 3 ]-msgno ).
*  ENDMETHOD.
*
*  METHOD eml_initial_failed_is_ok.
*    " Stands in for a BO specific FAILED structure: an initial structure means
*
*    " nothing failed. Requires no BDEF derived type.
*
*    TYPES: BEGIN OF ty_row,
*
*             tky TYPE string,
*
*           END OF ty_row.
*
*    TYPES: BEGIN OF ty_failed,
*
*             entity TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY,
*
*           END OF ty_failed.
*
*    DATA ls_failed TYPE ty_failed.
*
*    mo_cut->add_EML_modify_result( i_failed = ls_failed ).
*
*    cl_abap_unit_assert=>assert_false( mo_cut->has_errors( ) ).
*  ENDMETHOD.
*
*  METHOD eml_filled_failed_fails.
*    TYPES: BEGIN OF ty_row,
*
*             tky TYPE string,
*
*           END OF ty_row.
*
*    TYPES: BEGIN OF ty_failed,
*
*             entity TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY,
*
*           END OF ty_failed.
*
*    DATA(ls_failed) = VALUE ty_failed( entity = VALUE #( ( tky = '4711' ) ) ).
*
*    TRY.
*
*        mo_cut->add_EML_modify_result( i_failed = ls_failed ).
*
*        cl_abap_unit_assert=>fail( 'A filled FAILED must always fail the handler' ).
*
*      CATCH zcx_prc_unit_of_work_failed ##NO_HANDLER.
*
*    ENDTRY.
*
*    cl_abap_unit_assert=>assert_true( mo_cut->has_errors( ) ).
*  ENDMETHOD.
*
*  METHOD eml_unbound_entries_ignored.
*    " Dynamic response form: rows whose ENTRIES reference is not bound
*
*    " must be skipped without a dump.
*
*    DATA(lt_resp) = VALUE abp_behv_response_tab( ( root_name = 'ZI_ANY' entity_name = 'ANY' ) ).
*
*    mo_cut->add_EML_modify_result( i_failed   = lt_resp
*                                   i_reported = lt_resp ).
*
*    cl_abap_unit_assert=>assert_false( mo_cut->has_errors( ) ).
*
*    cl_abap_unit_assert=>assert_initial( mo_cut->get_messages( ) ).
*  ENDMETHOD.
*
*  METHOD eml_empty_entries_ignored.
*    DATA lt_empty TYPE STANDARD TABLE OF string WITH EMPTY KEY.
*
*    DATA(lt_resp) = VALUE abp_behv_response_tab( ( root_name   = 'ZI_ANY'
*
*                                                   entity_name = 'ANY'
*
*                                                   entries     = REF #( lt_empty ) ) ).
*
*    mo_cut->add_EML_modify_result( i_failed   = lt_resp
*                                   i_reported = lt_resp ).
*
*    cl_abap_unit_assert=>assert_false( mo_cut->has_errors( ) ).
*
*    cl_abap_unit_assert=>assert_initial( mo_cut->get_messages( ) ).
*  ENDMETHOD.
*
*  METHOD eml_dynamic_failed_fails.
*    TYPES: BEGIN OF ty_row,
*
*             tky TYPE string,
*
*           END OF ty_row.
*
*    DATA lt_entries TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.
*
*    lt_entries = VALUE #( ( tky = '4711' ) ).
*
*    DATA(lt_resp) = VALUE abp_behv_response_tab( ( root_name   = 'ZI_ANY'
*
*                                                   entity_name = 'ANY'
*
*                                                   entries     = REF #( lt_entries ) ) ).
*
*    TRY.
*
*        mo_cut->add_EML_modify_result( i_failed = lt_resp ).
*
*        cl_abap_unit_assert=>fail( 'A non-empty ENTRIES table means failure' ).
*
*      CATCH zcx_prc_unit_of_work_failed ##NO_HANDLER.
*
*    ENDTRY.
*  ENDMETHOD.
*
*  METHOD close_ok_seals.
*    mo_cut->add_bapi_result( bapi_line( type = 'I' ) ).
*
*    MESSAGE s001(zprc_msg_handlr_test) WITH 'DONE' INTO DATA(lv_dummy) ##NEEDED.
*
*    mo_cut->close_ok( CORRESPONDING #( sy ) ).
*
*    cl_abap_unit_assert=>assert_true( mo_cut->is_closed( ) ).
*
*    cl_abap_unit_assert=>assert_false( mo_cut->has_errors( ) ).
*
*    DATA(ls_header) = mo_cut->get_header( ).
*
*    " The success message is the header, not an additional detail
*    cl_abap_unit_assert=>assert_equals( exp = 'S'
*                                        act = ls_header-msgty ).
*
*    cl_abap_unit_assert=>assert_equals( exp = 'DONE'
*                                        act = ls_header-msgv1 ).
*
*    cl_abap_unit_assert=>assert_equals( exp = 2
*                                        act = lines( mo_cut->get_messages( ) ) ).
*  ENDMETHOD.
*
*  METHOD close_failed_raises.
*    TRY.
*
*        MESSAGE e001(zprc_msg_handlr_test) WITH 'NOPE' INTO DATA(lv_dummy) ##NEEDED.
*
*        mo_cut->close_failed( ).
*
*        cl_abap_unit_assert=>fail( 'CLOSE_FAILED must always raise' ).
*
*      CATCH zcx_prc_unit_of_work_failed ##NO_HANDLER.
*
*    ENDTRY.
*
*    cl_abap_unit_assert=>assert_true( mo_cut->has_errors( ) ).
*
*    cl_abap_unit_assert=>assert_true( mo_cut->is_closed( ) ).
*  ENDMETHOD.
*
*  METHOD close_failed_sets_header.
*    TRY.
*
*        MESSAGE e001(zprc_msg_handlr_test) WITH 'EQUI' 'TRUCK' INTO DATA(lv_dummy) ##NEEDED.
*
*        mo_cut->close_failed( ).
*
*      CATCH zcx_prc_unit_of_work_failed ##NO_HANDLER.
*
*    ENDTRY.
*
*    DATA(ls_header) = mo_cut->get_header( ).
*
*    cl_abap_unit_assert=>assert_equals( exp = 'E'
*                                        act = ls_header-msgty ).
*
*    cl_abap_unit_assert=>assert_equals( exp = 'EQUI'
*                                        act = ls_header-msgv1 ).
*
*    cl_abap_unit_assert=>assert_equals( exp = 'TRUCK'
*                                        act = ls_header-msgv2 ).
*  ENDMETHOD.
*
*  METHOD add_after_close_is_misuse.
*    MESSAGE s001(zprc_msg_handlr_test) INTO DATA(lv_dummy) ##NEEDED.
*
*    mo_cut->close_ok( CORRESPONDING #( sy ) ).
*
*    TRY.
*
*        mo_cut->add_bapi_result( bapi_line( type = 'I' ) ).
*
*        cl_abap_unit_assert=>fail( 'ADD_BAPI_RESULT after sealing must be misuse' ).
*
*      CATCH zcx_prc_message_handler_misuse ##NO_HANDLER.
*
*    ENDTRY.
*
*    TRY.
*
*        MESSAGE i001(zprc_msg_handlr_test) INTO lv_dummy ##NEEDED.
*
*        mo_cut->add_message_from_sy( ).
*
*        cl_abap_unit_assert=>fail( 'ADD_MESSAGE_FROM_SY after sealing must be misuse' ).
*
*      CATCH zcx_prc_message_handler_misuse ##NO_HANDLER.
*
*    ENDTRY.
*
*    TRY.
*
*        mo_cut->set_failure_header( VALUE #( msgty = 'E'
*                                             msgid = 'ZX'
*                                             msgno = '001' ) ).
*
*        cl_abap_unit_assert=>fail( 'SET_FAILURE_HEADER after sealing must be misuse' ).
*
*      CATCH zcx_prc_message_handler_misuse ##NO_HANDLER.
*
*    ENDTRY.
*  ENDMETHOD.
*
*  METHOD close_after_close_is_misuse.
*    MESSAGE s001(zprc_msg_handlr_test) INTO DATA(lv_dummy) ##NEEDED.
*    mo_cut->close_ok( CORRESPONDING #( sy ) ).
*
*    TRY.
*
*        MESSAGE s001(zprc_msg_handlr_test) INTO lv_dummy ##NEEDED.
*        mo_cut->close_ok( CORRESPONDING #( sy ) ).
*
*        cl_abap_unit_assert=>fail( 'CLOSE_OK twice must be misuse' ).
*
*      CATCH zcx_prc_message_handler_misuse ##NO_HANDLER.
*
*    ENDTRY.
*  ENDMETHOD.
*
*  METHOD close_ok_after_error.
*    " Documents the actual behavior: FAIL( ) already seals, so CLOSE_OK runs
*
*    " into ALREADY_CLOSED - SUCCESS_DESPITE_ERRORS is currently unreachable.
*
*    TRY.
*
*        mo_cut->add_bapi_result( bapi_line( type = 'E' ) ).
*
*      CATCH zcx_prc_unit_of_work_failed ##NO_HANDLER.
*
*    ENDTRY.
*
*    TRY.
*
*        MESSAGE s001(zprc_msg_handlr_test) INTO DATA(lv_dummy) ##NEEDED.
*
*        mo_cut->close_ok( CORRESPONDING #( sy ) ).
*
*        cl_abap_unit_assert=>fail( 'CLOSE_OK after an error must be misuse' ).
*
*      CATCH zcx_prc_message_handler_misuse INTO DATA(lx).
*
*        cl_abap_unit_assert=>assert_equals( exp = zcx_prc_message_handler_misuse=>already_closed-msgno
*                                            act = lx->if_t100_message~t100key-msgno ).
*
*    ENDTRY.
*  ENDMETHOD.
*
*  METHOD chaining_returns_self.
*    DATA(lo_returned) = mo_cut->set_failure_header( VALUE #( msgty = 'E'
*                                                             msgid = 'ZX'
*                                                             msgno = '001' )
*
*                          )->add_bapi_result( bapi_line( type = 'I' ) ).
*
*    cl_abap_unit_assert=>assert_equals( exp = mo_cut
*                                        act = lo_returned ).
*  ENDMETHOD.
*ENDCLASS.
