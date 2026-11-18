"! <p class="shorttext synchronized">ABAP-PRC: Message text in the logon language (calc. exit)</p>
"!
"! Calculated element MESSAGETEXTTRANSLATED: the text of a persisted message in the
"! logon language of the user, built from message class, number and variables.
"! The persisted MESSAGETEXT stays in the language of the processing user and is
"! used for search and filter. Free text (SY/499, or no message class) is shown as
"! persisted.
"!
"! Entities with the message fields (steps, messages, message groups) are translated
"! row by row; for processed objects (only LATESTSTEPUUID) the header message of the
"! latest step is read first.
CLASS zcl_prc_message_text DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_sadl_exit_calc_element_read.

    "! Name of the calculated element in the consumption views
    CONSTANTS co_element TYPE string VALUE `MESSAGETEXTTRANSLATED`.

    "! Text of the message in the logon language; the persisted text for free text.
    "!
    "! @parameter i_message     | Message class, number, type and variables.
    "! @parameter i_stored_text | Text as persisted (language of the processing user).
    "! @parameter r_text        | Text to display.
    CLASS-METHODS translate IMPORTING i_message     TYPE symsg
                                      i_stored_text TYPE csequence
                            RETURNING VALUE(r_text) TYPE zprc_message_text.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_header,
             step_uuid TYPE sysuuid_x16,
             message   TYPE symsg,
             text      TYPE zprc_message_text,
           END OF ty_header,
           tt_header TYPE HASHED TABLE OF ty_header WITH UNIQUE KEY step_uuid.

    "! Header messages of the given steps
    CLASS-METHODS read_headers IMPORTING i_original_data   TYPE STANDARD TABLE
                               RETURNING VALUE(r_headers) TYPE tt_header.

    "! Message class, number and variables of a row with the message fields;
    "! fields the row does not have stay initial.
    CLASS-METHODS message_of IMPORTING i_row            TYPE any
                             RETURNING VALUE(r_message) TYPE symsg.
ENDCLASS.



CLASS zcl_prc_message_text IMPLEMENTATION.

  METHOD translate.
    IF    i_message-msgid IS INITIAL
       OR ( i_message-msgid = 'SY' AND i_message-msgno = '499' ).
      r_text = i_stored_text.
      RETURN.
    ENDIF.

    MESSAGE ID i_message-msgid TYPE 'I' NUMBER i_message-msgno
            WITH i_message-msgv1 i_message-msgv2 i_message-msgv3 i_message-msgv4
            INTO DATA(text).
    r_text = COND #( WHEN text IS INITIAL THEN i_stored_text ELSE text ).
  ENDMETHOD.


  METHOD read_headers.
    DATA steps TYPE RANGE OF sysuuid_x16.
    LOOP AT i_original_data ASSIGNING FIELD-SYMBOL(<original>).
      ASSIGN COMPONENT 'LATESTSTEPUUID' OF STRUCTURE <original> TO FIELD-SYMBOL(<step>).
      IF sy-subrc = 0 AND <step> IS NOT INITIAL.
        INSERT VALUE #( sign = 'I' option = 'EQ' low = <step> ) INTO TABLE steps.
      ENDIF.
    ENDLOOP.
    IF steps IS INITIAL.
      RETURN.
    ENDIF.

    SELECT FROM ZI_PRC_ProcessedMessage
      FIELDS ProcessedStepUUID, MessageClass, MessageNumber, MessageVariable1, MessageVariable2,
             MessageVariable3, MessageVariable4, MessageText
      WHERE ProcessedStepUUID IN @steps
        AND IsHeader          = @abap_true
      INTO TABLE @DATA(messages).
    LOOP AT messages INTO DATA(message).
      INSERT VALUE #( step_uuid = message-ProcessedStepUUID
                      message   = VALUE #( msgid = message-MessageClass     msgno = message-MessageNumber
                                           msgv1 = message-MessageVariable1 msgv2 = message-MessageVariable2
                                           msgv3 = message-MessageVariable3 msgv4 = message-MessageVariable4 )
                      text      = message-MessageText ) INTO TABLE r_headers.
    ENDLOOP.
  ENDMETHOD.


  METHOD message_of.
    ASSIGN COMPONENT 'MESSAGECLASS' OF STRUCTURE i_row TO FIELD-SYMBOL(<value>).
    IF sy-subrc = 0.
      r_message-msgid = <value>.
    ENDIF.
    ASSIGN COMPONENT 'MESSAGENUMBER' OF STRUCTURE i_row TO <value>.
    IF sy-subrc = 0.
      r_message-msgno = <value>.
    ENDIF.
    ASSIGN COMPONENT 'MESSAGEVARIABLE1' OF STRUCTURE i_row TO <value>.
    IF sy-subrc = 0.
      r_message-msgv1 = <value>.
    ENDIF.
    ASSIGN COMPONENT 'MESSAGEVARIABLE2' OF STRUCTURE i_row TO <value>.
    IF sy-subrc = 0.
      r_message-msgv2 = <value>.
    ENDIF.
    ASSIGN COMPONENT 'MESSAGEVARIABLE3' OF STRUCTURE i_row TO <value>.
    IF sy-subrc = 0.
      r_message-msgv3 = <value>.
    ENDIF.
    ASSIGN COMPONENT 'MESSAGEVARIABLE4' OF STRUCTURE i_row TO <value>.
    IF sy-subrc = 0.
      r_message-msgv4 = <value>.
    ENDIF.
  ENDMETHOD.


  METHOD if_sadl_exit_calc_element_read~get_calculation_info.
    CASE iv_entity.
      WHEN 'ZC_PRC_PROCESSEDOBJECTTP' OR 'ZC_PRC_PROCESSEDOBJECT'.
        INSERT `LATESTSTEPUUID`   INTO TABLE et_requested_orig_elements.
        INSERT `MESSAGETEXT`      INTO TABLE et_requested_orig_elements.
      WHEN OTHERS.
        INSERT `MESSAGECLASS`     INTO TABLE et_requested_orig_elements.
        INSERT `MESSAGENUMBER`    INTO TABLE et_requested_orig_elements.
        INSERT `MESSAGEVARIABLE1` INTO TABLE et_requested_orig_elements.
        INSERT `MESSAGEVARIABLE2` INTO TABLE et_requested_orig_elements.
        INSERT `MESSAGEVARIABLE3` INTO TABLE et_requested_orig_elements.
        INSERT `MESSAGEVARIABLE4` INTO TABLE et_requested_orig_elements.
        INSERT `MESSAGETEXT`      INTO TABLE et_requested_orig_elements.
    ENDCASE.
  ENDMETHOD.


  METHOD if_sadl_exit_calc_element_read~calculate.
    DATA(headers) = read_headers( it_original_data ).

    LOOP AT ct_calculated_data ASSIGNING FIELD-SYMBOL(<calculated>).
      ASSIGN it_original_data[ sy-tabix ] TO FIELD-SYMBOL(<original>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      ASSIGN COMPONENT co_element OF STRUCTURE <calculated> TO FIELD-SYMBOL(<text>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      ASSIGN COMPONENT 'MESSAGETEXT' OF STRUCTURE <original> TO FIELD-SYMBOL(<stored>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      " Processed object: header message of the latest step
      ASSIGN COMPONENT 'LATESTSTEPUUID' OF STRUCTURE <original> TO FIELD-SYMBOL(<step>).
      IF sy-subrc = 0.
        DATA(header) = VALUE #( headers[ step_uuid = <step> ] OPTIONAL ).
        <text> = COND zprc_message_text( WHEN header IS INITIAL
                                         THEN <stored>
                                         ELSE translate( i_message     = header-message
                                                         i_stored_text = header-text ) ).
        CONTINUE.
      ENDIF.

      " Step, message, message group: message fields of the row
      <text> = translate( i_message     = message_of( <original> )
                          i_stored_text = <stored> ).
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
