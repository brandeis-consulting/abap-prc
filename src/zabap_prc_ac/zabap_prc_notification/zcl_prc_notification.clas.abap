"! <p class="shorttext synchronized">ABAP-PRC: Notification format and helpers</p>
"!
"! The parts both notification processes share: the payload, the HTML frame of
"! every PRC mail, HTML escaping and links into the Fiori launchpad.
"!
"! A notification is one processed object per group. Its payload holds the group
"! (set when the object is created) and, after the prepare step, the complete
"! notification; the send step adds the time it was sent.
CLASS zcl_prc_notification DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! States of both notification processes
    CONSTANTS co_prepared TYPE zif_prc_process=>ty_state VALUE 'PREPARED'.

    "! Path of the Fiori launchpad behind the system URL (on premise)
    CONSTANTS co_launchpad_path TYPE string VALUE `/sap/bc/ui2/flp`.

    "! Maximum number of rows in a mail: the payload (and the mail in it) stays small
    CONSTANTS co_max_rows TYPE i VALUE 50.

    TYPES: BEGIN OF ty_payload,
             process_name TYPE zprc_process_name,
             mail_address TYPE string,
             run_uuid     TYPE sysuuid_x16,
             notification TYPE zif_prc_notification_channel=>ty_notification,
           END OF ty_payload.

    TYPES tt_cells TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    TYPES tt_rows TYPE STANDARD TABLE OF tt_cells WITH EMPTY KEY.

    "! Reads the payload; ABAP_FALSE if it is not a notification payload.
    "!
    "! @parameter i_json    | Payload of the processed object.
    "! @parameter e_payload | Group (process name + mail address, or run) and notification.
    "! @parameter r_success | ABAP_TRUE if the payload could be read.
    CLASS-METHODS payload_from_json IMPORTING i_json           TYPE zprc_payload_json
                                    EXPORTING e_payload        TYPE ty_payload
                                    RETURNING VALUE(r_success) TYPE abap_bool.

    CLASS-METHODS payload_to_json IMPORTING i_payload     TYPE ty_payload
                                  RETURNING VALUE(r_json) TYPE zprc_payload_json.

    "! External ID of a notification object: readable, cut to 50 characters.
    "! The group itself is in the payload.
    "!
    "! @parameter i_text | Readable group, e.g. process name / mail address.
    "! @parameter r_id   | External ID.
    CLASS-METHODS object_id IMPORTING i_text      TYPE string
                            RETURNING VALUE(r_id) TYPE za_prc_createprocessedobject-processedobject.

    "! Text escaped for HTML.
    CLASS-METHODS html IMPORTING i_text        TYPE csequence
                       RETURNING VALUE(r_html) TYPE string.

    "! Complete HTML document in the layout of the Processing Center.
    "!
    "! @parameter i_headline | Headline (text, escaped here).
    "! @parameter i_content  | Content (HTML, not escaped).
    "! @parameter r_html     | HTML document.
    CLASS-METHODS html_document IMPORTING i_headline    TYPE csequence
                                          i_content     TYPE string
                                RETURNING VALUE(r_html) TYPE string.

    "! Table in the layout of the Processing Center.
    "!
    "! @parameter i_header | Column titles (text).
    "! @parameter i_rows   | Cells per row (HTML, not escaped).
    "! @parameter r_html   | HTML table.
    CLASS-METHODS html_table IMPORTING i_header      TYPE tt_cells
                                       i_rows        TYPE tt_rows
                             RETURNING VALUE(r_html) TYPE string.

    "! Base URL of the Fiori launchpad; initial if the system URL is unknown.
    "! Cloud: CL_ABAP_CONTEXT_INFO; on premise/private cloud: ZIF_PRC_SYSTEM_URL (Standard ABAP).
    CLASS-METHODS launchpad_url RETURNING VALUE(r_url) TYPE string.

    "! HTML link to an app; just the text if there is no launchpad URL.
    "!
    "! @parameter i_launchpad_url | From LAUNCHPAD_URL.
    "! @parameter i_intent        | Semantic object and action, e.g. ABAP_PRC_Run-show.
    "! @parameter i_parameters    | Intent parameters, e.g. UUID=....
    "! @parameter i_text          | Link text (escaped here).
    "! @parameter r_html          | Link.
    CLASS-METHODS html_link IMPORTING i_launchpad_url TYPE string
                                      i_intent        TYPE string
                                      i_parameters    TYPE string
                                      i_text          TYPE csequence
                            RETURNING VALUE(r_html)   TYPE string.

    "! Header of a send step that failed: names the recipient if known.
    "!
    "! @parameter i_recipient | Recipient of the notification; may be initial.
    "! @parameter r_message   | 011 with the recipient spread over &1-&4, else 006.
    CLASS-METHODS send_failure_message IMPORTING i_recipient      TYPE string
                                       RETURNING VALUE(r_message) TYPE symsg.

    "! Timestamp as text in UTC, without fractions.
    CLASS-METHODS timestamp_text IMPORTING i_timestamp   TYPE tzntstmpl
                                 RETURNING VALUE(r_text) TYPE string.

    "! UUID in the hyphenated form the OData services expect.
    CLASS-METHODS uuid_text IMPORTING i_uuid        TYPE sysuuid_x16
                            RETURNING VALUE(r_text) TYPE string.
ENDCLASS.



CLASS zcl_prc_notification IMPLEMENTATION.

  METHOD payload_from_json.
    CLEAR e_payload.
    TRY.
        xco_cp_json=>data->from_string( i_json )->write_to( REF #( e_payload ) ).
        r_success = abap_true.
      CATCH cx_root ##CATCH_ALL.
        r_success = abap_false.
    ENDTRY.
  ENDMETHOD.

  METHOD payload_to_json.
    r_json = xco_cp_json=>data->from_abap( i_payload )->to_string( ).
  ENDMETHOD.

  METHOD object_id.
    r_id = i_text.
  ENDMETHOD.

  METHOD html.
    r_html = escape( val = i_text format = cl_abap_format=>e_html_text ).
  ENDMETHOD.

  METHOD html_document.
    " styles once in the head: keeps the payload small (rows carry no inline styles)
    r_html = |<!DOCTYPE html><html><head><style>| &&
             |body \{ font-family: Arial, sans-serif; font-size: 14px; \}| &&
             |h2 \{ color: #0078D4; font-size: 18px; \}| &&
             |table \{ border-collapse: collapse; width: 100%; \}| &&
             |th \{ background-color: #0078D4; color: white; padding: 8px; border: 1px solid #d1d1d1; text-align: left; \}| &&
             |td \{ background-color: #f8f9fa; padding: 8px; border: 1px solid #d1d1d1; \}| &&
             |.note \{ color: #6a6d70; font-size: 12px; \}| &&
             |</style></head><body>| &&
             |<h2>{ html( i_headline ) }</h2>| &&
             i_content &&
             |<p class="note">This is an automatically generated message from the | &&
             |ABAP Processing Center. Please do not reply.</p>| &&
             |</body></html>|.
  ENDMETHOD.

  METHOD html_table.
    r_html = |<table><thead><tr>|.
    LOOP AT i_header INTO DATA(lv_title).
      r_html &&= |<th>{ html( lv_title ) }</th>|.
    ENDLOOP.
    r_html &&= |</tr></thead><tbody>|.
    LOOP AT i_rows INTO DATA(lt_cells).
      r_html &&= |<tr>|.
      LOOP AT lt_cells INTO DATA(lv_cell).
        r_html &&= |<td>{ lv_cell }</td>|.
      ENDLOOP.
      r_html &&= |</tr>|.
    ENDLOOP.
    r_html &&= |</tbody></table>|.
  ENDMETHOD.

  METHOD launchpad_url.
    DATA lv_system_url TYPE string.
    DATA lo_system_url TYPE REF TO zif_prc_system_url.

    TRY.
        lv_system_url = cl_abap_context_info=>get_system_url( ).
      CATCH cx_abap_context_info_error ##NO_HANDLER.
        " try the Standard ABAP implementation below
    ENDTRY.

    IF lv_system_url IS INITIAL.
      " On premise/private cloud the cloud system URL is empty; the ICM knows the host
      TRY.
          CREATE OBJECT lo_system_url TYPE (zif_prc_system_url=>co_implementation).
          lv_system_url = lo_system_url->get_system_url( ).
        CATCH cx_sy_create_object_error ##NO_HANDLER.
          " not installed (ABAP Cloud, BTP): mail without links (warning 008)
      ENDTRY.
    ENDIF.

    IF lv_system_url IS INITIAL.
      RETURN.
    ENDIF.
    IF lv_system_url NP 'http*'.
      lv_system_url = |https://{ lv_system_url }|.
    ENDIF.
    r_url = |{ lv_system_url }{ co_launchpad_path }|.
  ENDMETHOD.

  METHOD html_link.
    IF i_launchpad_url IS INITIAL.
      r_html = html( i_text ).
      RETURN.
    ENDIF.
    " attribute value: quotes must be escaped too (E_HTML_TEXT does not)
    DATA(lv_href) = escape( val    = |{ i_launchpad_url }#{ i_intent }?{ i_parameters }|
                            format = cl_abap_format=>e_html_attr ).
    r_html = |<a href="{ lv_href }">{ html( i_text ) }</a>|.
  ENDMETHOD.

  METHOD send_failure_message.
    IF i_recipient IS INITIAL.
      " Notification could not be sent
      r_message = VALUE #( msgty = 'E' msgid = 'ZPRC_NOTIFICATION' msgno = '006' ).
      RETURN.
    ENDIF.
    " the recipient may be longer than one message variable: spread over &1-&4
    DATA lv_vars TYPE c LENGTH 200.
    lv_vars = i_recipient.
    " Notification to &1&2&3&4 could not be sent
    r_message = VALUE #( msgty = 'E' msgid = 'ZPRC_NOTIFICATION' msgno = '011'
                         msgv1 = lv_vars(50) msgv2 = lv_vars+50(50)
                         msgv3 = lv_vars+100(50) msgv4 = lv_vars+150(50) ).
  ENDMETHOD.

  METHOD timestamp_text.
    DATA lv_timestamp TYPE timestamp.
    " cut off fractional seconds instead of rounding
    lv_timestamp = trunc( i_timestamp ).
    r_text = |{ lv_timestamp TIMESTAMP = ISO TIMEZONE = 'UTC' } UTC|.
  ENDMETHOD.

  METHOD uuid_text.
    DATA(lv_hex) = to_lower( CONV string( i_uuid ) ).
    r_text = |{ lv_hex(8) }-{ lv_hex+8(4) }-{ lv_hex+12(4) }-{ lv_hex+16(4) }-{ lv_hex+20(12) }|.
  ENDMETHOD.
ENDCLASS.
