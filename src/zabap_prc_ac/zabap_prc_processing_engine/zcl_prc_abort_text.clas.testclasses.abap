"! @testing ZCL_PRC_ABORT_TEXT
CLASS ltc_to_variables DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    "! Rebuilds the text like a message does: trailing blanks of a variable are lost
    METHODS rebuild IMPORTING i_variables   TYPE zcl_prc_abort_text=>ty_variables
                    RETURNING VALUE(r_text) TYPE string.

    METHODS short_text_in_first_variable  FOR TESTING.
    METHODS blank_at_border_is_kept       FOR TESTING.
    METHODS long_text_survives_rebuild    FOR TESTING.
    METHODS long_word_is_split_hard       FOR TESTING.
    METHODS text_beyond_200_is_cut        FOR TESTING.
    METHODS initial_text_gives_initial    FOR TESTING.
ENDCLASS.


CLASS ltc_to_variables IMPLEMENTATION.

  METHOD rebuild.
    r_text = |{ i_variables-v1 }{ i_variables-v2 }{ i_variables-v3 }{ i_variables-v4 }|.
  ENDMETHOD.


  METHOD short_text_in_first_variable.
    DATA(variables) = zcl_prc_abort_text=>to_variables( `Short text` ).
    cl_abap_unit_assert=>assert_equals( act = variables-v1 exp = 'Short text' ).
    cl_abap_unit_assert=>assert_initial( variables-v2 ).
  ENDMETHOD.


  METHOD blank_at_border_is_kept.
    " Blank exactly at position 50: a hard split would lose it
    DATA(text) = |{ repeat( val = `a` occ = 50 ) } posted (update registered)|.
    DATA(variables) = zcl_prc_abort_text=>to_variables( text ).
    cl_abap_unit_assert=>assert_equals( act = rebuild( variables ) exp = text ).
  ENDMETHOD.


  METHOD long_text_survives_rebuild.
    DATA(text) = `Demo Message - BAPI B: Provoked - MESSAGE X in the follow-up of document 0000000017 ` &&
                 `for order ORD0000009 of the run started by the application job`.
    cl_abap_unit_assert=>assert_equals( act = rebuild( zcl_prc_abort_text=>to_variables( text ) ) exp = text ).
  ENDMETHOD.


  METHOD long_word_is_split_hard.
    DATA(text) = repeat( val = `x` occ = 120 ).
    DATA(variables) = zcl_prc_abort_text=>to_variables( text ).
    cl_abap_unit_assert=>assert_equals( act = strlen( variables-v1 ) exp = 50 ).
    cl_abap_unit_assert=>assert_equals( act = rebuild( variables ) exp = text ).
  ENDMETHOD.


  METHOD text_beyond_200_is_cut.
    DATA(text) = repeat( val = `word ` occ = 60 ).        " 300 characters
    DATA(rebuilt) = rebuild( zcl_prc_abort_text=>to_variables( text ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( strlen( rebuilt ) <= 200 ) ).
    cl_abap_unit_assert=>assert_equals( act = rebuilt exp = substring( val = text len = strlen( rebuilt ) ) ).
  ENDMETHOD.


  METHOD initial_text_gives_initial.
    cl_abap_unit_assert=>assert_initial( zcl_prc_abort_text=>to_variables( `` ) ).
  ENDMETHOD.

ENDCLASS.


"! @testing ZCL_PRC_ABORT_TEXT
CLASS ltc_cause_from_analysis DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    METHODS message_x_english          FOR TESTING.
    METHODS message_x_german           FOR TESTING.
    METHODS line_breaks_are_condensed  FOR TESTING.
    METHODS no_marker_gives_analysis   FOR TESTING.
    METHODS no_end_marker_takes_rest   FOR TESTING.
    METHODS initial_gives_initial      FOR TESTING.
ENDCLASS.


CLASS ltc_cause_from_analysis IMPLEMENTATION.

  METHOD message_x_english.
    DATA(analysis) = `Short text of the error message: Demo Message - BAPI B: Provoked - MESSAGE X ` &&
                     `Long text of the error message: Technical information about the message: ` &&
                     `Message class....... ZPRC_DEMO_BAPI_JOB Number.............. 022`.
    cl_abap_unit_assert=>assert_equals( act = zcl_prc_abort_text=>cause_from_analysis( analysis )
                                        exp = `Demo Message - BAPI B: Provoked - MESSAGE X` ).
  ENDMETHOD.


  METHOD message_x_german.
    DATA(analysis) = `Kurztext der Fehlermeldung: Beleg 4711 ist gesperrt ` &&
                     `Langtext der Fehlermeldung: Technische Informationen zur Meldung: ...`.
    cl_abap_unit_assert=>assert_equals( act = zcl_prc_abort_text=>cause_from_analysis( analysis )
                                        exp = `Beleg 4711 ist gesperrt` ).
  ENDMETHOD.


  METHOD line_breaks_are_condensed.
    DATA(analysis) = |Short text of the error message:{ cl_abap_char_utilities=>newline }Order| &&
                     | not found{ cl_abap_char_utilities=>newline }Long text of the error message: x|.
    cl_abap_unit_assert=>assert_equals( act = zcl_prc_abort_text=>cause_from_analysis( analysis )
                                        exp = `Order not found` ).
  ENDMETHOD.


  METHOD no_marker_gives_analysis.
    DATA(analysis) = |Division by zero{ cl_abap_char_utilities=>newline }in method CALCULATE|.
    cl_abap_unit_assert=>assert_equals( act = zcl_prc_abort_text=>cause_from_analysis( analysis )
                                        exp = `Division by zero in method CALCULATE` ).
  ENDMETHOD.


  METHOD no_end_marker_takes_rest.
    cl_abap_unit_assert=>assert_equals(
        act = zcl_prc_abort_text=>cause_from_analysis( `Short text of the error message: Only the message` )
        exp = `Only the message` ).
  ENDMETHOD.


  METHOD initial_gives_initial.
    cl_abap_unit_assert=>assert_initial( zcl_prc_abort_text=>cause_from_analysis( `` ) ).
  ENDMETHOD.

ENDCLASS.
