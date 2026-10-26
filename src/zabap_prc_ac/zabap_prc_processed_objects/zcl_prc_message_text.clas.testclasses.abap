"! The displayed text comes from the message key in the logon language, not from the
"! persisted text (which is in the language of the processing user). Free text is
"! shown as persisted.
CLASS ltc_translate DEFINITION FINAL FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    CONSTANTS co_stored TYPE string VALUE `Text in another language`.

    METHODS t100_from_key_not_stored FOR TESTING.
    METHODS free_text_as_stored      FOR TESTING.
    METHODS no_class_as_stored       FOR TESTING.
ENDCLASS.


CLASS ltc_translate IMPLEMENTATION.

  METHOD t100_from_key_not_stored.
    MESSAGE s017(zprc_process_message) WITH 'A' INTO DATA(lv_expected).

    DATA(lv_text) = zcl_prc_message_text=>translate(
                        i_message     = VALUE #( msgid = 'ZPRC_PROCESS_MESSAGE' msgno = '017' msgv1 = 'A' )
                        i_stored_text = co_stored ).

    cl_abap_unit_assert=>assert_equals( act = CONV string( lv_text ) exp = lv_expected
                                        msg = 'Text of the message key in the logon language' ).
    cl_abap_unit_assert=>assert_differs( act = CONV string( lv_text ) exp = co_stored ).
  ENDMETHOD.

  METHOD free_text_as_stored.
    DATA(lv_text) = zcl_prc_message_text=>translate(
                        i_message     = VALUE #( msgid = 'SY' msgno = '499' msgv1 = 'Free' )
                        i_stored_text = co_stored ).
    cl_abap_unit_assert=>assert_equals( act = CONV string( lv_text ) exp = co_stored ).
  ENDMETHOD.

  METHOD no_class_as_stored.
    DATA(lv_text) = zcl_prc_message_text=>translate( i_message     = VALUE #( )
                                                     i_stored_text = co_stored ).
    cl_abap_unit_assert=>assert_equals( act = CONV string( lv_text ) exp = co_stored ).
  ENDMETHOD.
ENDCLASS.
