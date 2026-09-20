"! <p class="shorttext synchronized">Converts RAP and BAPI responses into SYMSG</p>
"!
"! Stateless and without dependencies, so it can be reused anywhere someone
"! consumes a RAP BO or a BAPI, regardless of the surrounding framework.
CLASS zcl_prc_message_mapper DEFINITION PUBLIC FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    TYPES tt_messages TYPE STANDARD TABLE OF symsg WITH EMPTY KEY.

    "! Wraps a plain text into message SY 499.
    "!
    "! Uses CL_MESSAGE_HELPER to distribute the text word-wise across the four
    "! message variables, so up to roughly 200 characters survive readably.
    "! Longer texts are truncated.
    "!
    "! The result has no T100 key of its own, so it is not translatable - the
    "! text is frozen in the language it was passed in.
    "!
    "! @parameter text   | Text without a message class.
    "! @parameter msgty  | Message type to be applied.
    "! @parameter result | Message SY 499 with filled variables.
    CLASS-METHODS from_text      IMPORTING !text         TYPE string
                msgty         TYPE symsgty
      RETURNING VALUE(result) TYPE symsg.

    "! Extracts all messages from an EML REPORTED response.
    "!
    "! Handles both shapes: the BO specific structure of MODIFY ENTITIES, whose
    "! components are one table per entity plus %OTHER, and the flat
    "! ABP_BEHV_RESPONSE_TAB of the dynamic COMMIT ENTITIES form.
    "!
    "! T100 based messages keep message class, number and variables. Free text
    "! messages created by NEW_MESSAGE_WITH_TEXT are mapped to SY 499 with the
    "! text distributed across the four variables.
    "!
    "! @parameter reported | REPORTED response of any supported shape.
    "! @parameter result   | Extracted messages, empty if none.
    CLASS-METHODS from_reported      IMPORTING !reported     TYPE any
      RETURNING VALUE(result) TYPE tt_messages.


    "! Converts a BAPI return table into SYMSG.
    "!
    "! @parameter bapiret | Return table of a BAPI call.
    "! @parameter result  | Converted messages in the original order.
    CLASS-METHODS from_bapiret      IMPORTING bapiret       TYPE zif_prc_message_handler=>tt_bapiret2
      RETURNING VALUE(result) TYPE tt_messages.

    "! Checks whether an EML FAILED response contains any entry.
    "!
    "! Handles both the BO specific structure and ABP_BEHV_RESPONSE_TAB, where
    "! the entry tables sit behind data references and have to be dereferenced.
    "!
    "! @parameter failed | FAILED response of any supported shape.
    "! @parameter result | ABAP_TRUE if at least one instance failed.
    CLASS-METHODS is_failed
      IMPORTING !failed       TYPE any
      RETURNING VALUE(result) TYPE abap_bool.

  PRIVATE SECTION.
    "! Reads %MSG from every row of one derived response table.
    "!
    "! Rows without %MSG are skipped, which silently covers FAILED tables.
    "!
    "! @parameter entries | Derived table of one entity.
    "! @parameter result  | Message table the findings are appended to.
    CLASS-METHODS collect
      IMPORTING !entries TYPE ANY TABLE
      CHANGING  !result  TYPE tt_messages.

    "! Converts a single behavior message into SYMSG.
    "!
    "! @parameter message | Message reference taken from %MSG.
    "! @parameter result  | Converted message.
    CLASS-METHODS to_symsg
      IMPORTING !message      TYPE REF TO if_abap_behv_message
      RETURNING VALUE(result) TYPE symsg.

    "! Maps a RAP severity to a classic message type.
    "!
    "! @parameter severity | Severity as defined by IF_ABAP_BEHV_MESSAGE.
    "! @parameter result   | E, W, S or I. Unknown values map to I.
    CLASS-METHODS to_msgty
      IMPORTING severity      TYPE if_abap_behv_message=>t_severity
      RETURNING VALUE(result) TYPE symsgty.

ENDCLASS.



CLASS ZCL_PRC_MESSAGE_MAPPER IMPLEMENTATION.


  METHOD from_reported.
    FIELD-SYMBOLS <tab>       TYPE ANY TABLE.
    FIELD-SYMBOLS <responses> TYPE abp_behv_response_tab.

    DATA(lo_type) = cl_abap_typedescr=>describe_by_data( reported ).

    CASE lo_type->kind.
      WHEN cl_abap_typedescr=>kind_struct.
        LOOP AT CAST cl_abap_structdescr( lo_type )->components INTO DATA(ls_comp).
          ASSIGN COMPONENT ls_comp-name OF STRUCTURE reported TO FIELD-SYMBOL(<any>).
          IF sy-subrc <> 0.
            CONTINUE.
          ENDIF.
          IF cl_abap_typedescr=>describe_by_data( <any> )->kind
             <> cl_abap_typedescr=>kind_table.
            CONTINUE.
          ENDIF.
          ASSIGN <any> TO <tab>.
          IF sy-subrc <> 0.
            CONTINUE.
          ENDIF.
          collect( EXPORTING entries = <tab>
                   CHANGING  result  = result ).
        ENDLOOP.

      WHEN cl_abap_typedescr=>kind_table.
        ASSIGN reported TO <responses>.
        IF sy-subrc <> 0.
          RETURN.
        ENDIF.
        LOOP AT <responses> INTO DATA(ls_resp).
          IF ls_resp-entries IS NOT BOUND.
            CONTINUE.
          ENDIF.
          ASSIGN ls_resp-entries->* TO <tab>.
          IF sy-subrc <> 0.
            CONTINUE.
          ENDIF.
          collect( EXPORTING entries = <tab>
                   CHANGING  result  = result ).
        ENDLOOP.
    ENDCASE.
  ENDMETHOD.


  METHOD collect.
    DATA lo_msg TYPE REF TO if_abap_behv_message.

    LOOP AT entries ASSIGNING FIELD-SYMBOL(<line>).
      ASSIGN COMPONENT '%MSG' OF STRUCTURE <line> TO FIELD-SYMBOL(<ref>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      lo_msg ?= <ref>.
      IF lo_msg IS NOT BOUND.
        CONTINUE.
      ENDIF.
      APPEND to_symsg( lo_msg ) TO result.
    ENDLOOP.
  ENDMETHOD.


  METHOD to_symsg.
    DATA(lv_msgty) = to_msgty( message->m_severity ).
    DATA(ls_t100)  = message->if_t100_message~t100key.

    IF ls_t100-msgid IS INITIAL.
      result = from_text( text  = message->if_message~get_text( )
                          msgty = lv_msgty ).
      RETURN.
    ENDIF.

    result = VALUE #( msgty = lv_msgty
                      msgid = ls_t100-msgid
                      msgno = ls_t100-msgno
                      msgv1 = message->if_t100_dyn_msg~msgv1
                      msgv2 = message->if_t100_dyn_msg~msgv2
                      msgv3 = message->if_t100_dyn_msg~msgv3
                      msgv4 = message->if_t100_dyn_msg~msgv4 ).
  ENDMETHOD.


  METHOD from_text.
    cl_message_helper=>set_msg_vars_for_clike( text ).
    result = VALUE #( msgty = msgty
                      msgid = 'SY'
                      msgno = '499'
                      msgv1 = sy-msgv1
                      msgv2 = sy-msgv2
                      msgv3 = sy-msgv3
                      msgv4 = sy-msgv4 ).
  ENDMETHOD.


  METHOD to_msgty.
    result = SWITCH #( severity
                       WHEN if_abap_behv_message=>severity-error       THEN 'E'
                       WHEN if_abap_behv_message=>severity-warning     THEN 'W'
                       WHEN if_abap_behv_message=>severity-success     THEN 'S'
                       WHEN if_abap_behv_message=>severity-information THEN 'I'
                       ELSE                                                 'I' ).
  ENDMETHOD.


  METHOD from_bapiret.
    LOOP AT bapiret INTO DATA(ls_ret).
      IF ls_ret-id IS INITIAL.
        APPEND from_text( text  = CONV string( ls_ret-message )
                          msgty = ls_ret-type ) TO result.
      ELSE.
        APPEND VALUE #( msgty = ls_ret-type
                        msgid = ls_ret-id
                        msgno = ls_ret-number
                        msgv1 = ls_ret-message_v1
                        msgv2 = ls_ret-message_v2
                        msgv3 = ls_ret-message_v3
                        msgv4 = ls_ret-message_v4 ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD is_failed.
    FIELD-SYMBOLS <responses> TYPE abp_behv_response_tab.
    FIELD-SYMBOLS <tab>       TYPE ANY TABLE.

    DATA(lo_type) = cl_abap_typedescr=>describe_by_data( failed ).

    CASE lo_type->kind.
      WHEN cl_abap_typedescr=>kind_struct.
        result = xsdbool( failed IS NOT INITIAL ).

      WHEN cl_abap_typedescr=>kind_table.
        ASSIGN failed TO <responses>.
        IF sy-subrc <> 0.
          RETURN.
        ENDIF.
        LOOP AT <responses> INTO DATA(ls_resp).
          IF ls_resp-entries IS NOT BOUND.
            CONTINUE.
          ENDIF.
          ASSIGN ls_resp-entries->* TO <tab>.
          IF sy-subrc <> 0 OR <tab> IS INITIAL.
            CONTINUE.
          ENDIF.
          result = abap_true.
          RETURN.
        ENDLOOP.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
