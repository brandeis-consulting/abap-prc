"! <p class="shorttext synchronized">ABAP-PRC: Abort and short dump texts in messages</p>
"!
"! Texts of an aborted step session - abort text, error analysis of the short dump -
"! end up in message variables:
"! <ul>
"! <li>TO_VARIABLES - a long text in the four message variables, split at blanks</li>
"! <li>CAUSE_FROM_ANALYSIS - the cause of a runtime error from the error analysis</li>
"! </ul>
CLASS zcl_prc_abort_text DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES ty_variable TYPE c LENGTH 50.
    TYPES: BEGIN OF ty_variables,
             v1 TYPE ty_variable,
             v2 TYPE ty_variable,
             v3 TYPE ty_variable,
             v4 TYPE ty_variable,
           END OF ty_variables.

    "! Spreads a text over the four message variables (50 characters each, 200 in total).
    "! A variable loses its trailing blanks when the message is built, so the text is
    "! split before a blank: the blank leads the next variable and is kept.
    "! A word longer than 50 characters is split hard. Text beyond 200 characters is cut.
    "!
    "! @parameter i_text      | The text, e.g. an abort text or an error analysis
    "! @parameter r_variables | The four message variables
    CLASS-METHODS to_variables
      IMPORTING i_text             TYPE csequence
      RETURNING VALUE(r_variables) TYPE ty_variables.

    "! The cause of a runtime error from the error analysis of its short dump.
    "! For MESSAGE_TYPE_X and MESSAGE_TYPE_A the analysis contains the text of the
    "! message between "Short text of the error message:" and "Long text of the error
    "! message:" (English) or the German counterparts - that text is returned. For other
    "! runtime errors, or an analysis in another language, the condensed analysis.
    "!
    "! @parameter i_analysis | Error analysis of the short dump (may contain line breaks)
    "! @parameter r_cause    | The cause; initial if the analysis is initial
    CLASS-METHODS cause_from_analysis
      IMPORTING i_analysis     TYPE csequence
      RETURNING VALUE(r_cause) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES: BEGIN OF ty_markers,
             start TYPE string,
             end   TYPE string,
           END OF ty_markers,
           tt_markers TYPE STANDARD TABLE OF ty_markers WITH EMPTY KEY.

    "! Labels around the message text in the error analysis, per language
    CLASS-METHODS markers RETURNING VALUE(r_markers) TYPE tt_markers.
ENDCLASS.



CLASS zcl_prc_abort_text IMPLEMENTATION.

  METHOD to_variables.
    DATA parts TYPE STANDARD TABLE OF ty_variable WITH EMPTY KEY.
    DATA(rest) = CONV string( i_text ).

    WHILE rest IS NOT INITIAL AND lines( parts ) < 4.
      IF strlen( rest ) <= 50.
        APPEND rest TO parts.
        CLEAR rest.
      ELSE.
        " Last blank within the first 50 characters: split before it
        DATA(split) = find( val = substring( val = rest len = 50 ) sub = ` ` occ = -1 ).
        IF split <= 0.
          split = 50.
        ENDIF.
        APPEND substring( val = rest len = split ) TO parts.
        rest = substring( val = rest off = split ).
      ENDIF.
    ENDWHILE.

    r_variables = VALUE #( v1 = VALUE #( parts[ 1 ] OPTIONAL )
                           v2 = VALUE #( parts[ 2 ] OPTIONAL )
                           v3 = VALUE #( parts[ 3 ] OPTIONAL )
                           v4 = VALUE #( parts[ 4 ] OPTIONAL ) ).
  ENDMETHOD.


  METHOD cause_from_analysis.
    DATA(analysis) = condense( replace( val  = CONV string( i_analysis )
                                        sub  = cl_abap_char_utilities=>newline
                                        with = ` `
                                        occ  = 0 ) ).
    r_cause = analysis.
    CHECK analysis IS NOT INITIAL.

    LOOP AT markers( ) INTO DATA(marker).
      DATA(start) = find( val = analysis sub = marker-start case = abap_false ).
      CHECK start >= 0.
      DATA(text) = substring( val = analysis off = start + strlen( marker-start ) ).
      DATA(end) = find( val = text sub = marker-end case = abap_false ).
      IF end >= 0.
        text = substring( val = text len = end ).
      ENDIF.
      text = condense( text ).
      IF text IS NOT INITIAL.
        r_cause = text.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD markers.
    r_markers = VALUE #( ( start = `Short text of the error message:` end = `Long text of the error message:` )
                         ( start = `Kurztext der Fehlermeldung:`      end = `Langtext der Fehlermeldung:` ) ).
  ENDMETHOD.

ENDCLASS.
