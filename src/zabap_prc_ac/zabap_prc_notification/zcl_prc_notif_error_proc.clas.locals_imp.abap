"! Prepare step: reads the objects with errors of the group and puts the mail
"! into the payload. Without objects with errors the notification is finished.
CLASS lcl_prepare DEFINITION INHERITING FROM zcl_prc_transition_handlr_base FINAL.
  PROTECTED SECTION.
    METHODS perform_transition REDEFINITION.
    METHODS get_success_message REDEFINITION.

  PRIVATE SECTION.
    DATA m_count        TYPE i.
    DATA m_process_name TYPE zprc_process_name.
ENDCLASS.


CLASS lcl_prepare IMPLEMENTATION.

  METHOD perform_transition.
    DATA ls_payload TYPE zcl_prc_notification=>ty_payload.
    DATA lv_mail    TYPE zprc_mail_address.
    DATA lt_rows    TYPE zcl_prc_notification=>tt_rows.

    IF zcl_prc_notification=>payload_from_json( EXPORTING i_json    = c_payload_json
                                                IMPORTING e_payload = ls_payload ) = abap_false
       OR ls_payload-process_name IS INITIAL
       OR ls_payload-mail_address IS INITIAL.
      MESSAGE e007(zprc_notification) INTO DATA(lv_dummy) ##NEEDED.
      get_message_handler( )->add_message_from_sy( ).
    ENDIF.

    m_process_name = ls_payload-process_name.
    lv_mail = ls_payload-mail_address.

    " MessageText = header of the latest step, as shown in the list of processed steps
    SELECT FROM ZI_PRC_ProcessedObject
      FIELDS UUID, ExternalProcessedObjectID, MessageText, LastChangedAt
      WHERE ProcessName     = @ls_payload-process_name
        AND MailAddress     = @lv_mail
        AND MessageSeverity = 'E'
      ORDER BY LastChangedAt DESCENDING
      INTO TABLE @DATA(lt_objects).

    m_count = lines( lt_objects ).
    IF m_count = 0.
      r_new_state = zif_prc_process=>co_finished.
      RETURN.
    ENDIF.

    DATA(lv_launchpad_url) = zcl_prc_notification=>launchpad_url( ).
    IF lv_launchpad_url IS INITIAL.
      MESSAGE w008(zprc_notification) INTO lv_dummy.
      get_message_handler( )->add_message_from_sy( ).
    ENDIF.

    LOOP AT lt_objects INTO DATA(ls_object) TO zcl_prc_notification=>co_max_rows.
      APPEND VALUE #( ( zcl_prc_notification=>html_link(
                            i_launchpad_url = lv_launchpad_url
                            i_intent        = `ABAP_PRC_ProcessedObject-show`
                            i_parameters    = |UUID={ zcl_prc_notification=>uuid_text( ls_object-UUID ) }|
                            i_text          = ls_object-ExternalProcessedObjectID ) )
                      ( zcl_prc_notification=>html( ls_object-MessageText ) )
                      ( zcl_prc_notification=>html( zcl_prc_notification=>timestamp_text( ls_object-LastChangedAt ) ) ) )
             TO lt_rows.
    ENDLOOP.

    DATA(lv_content) = |<p>The following objects of process <strong>{ zcl_prc_notification=>html( m_process_name ) }</strong> | &&
                       |could not be processed successfully.</p>| &&
                       zcl_prc_notification=>html_table( i_header = VALUE #( ( `Object` ) ( `Message` ) ( `Last processed` ) )
                                                         i_rows   = lt_rows ).
    IF m_count > zcl_prc_notification=>co_max_rows.
      lv_content &&= |<p>... and { m_count - zcl_prc_notification=>co_max_rows } more.</p>|.
    ENDIF.
    lv_content &&= |<p>| && zcl_prc_notification=>html_link(
                                  i_launchpad_url = lv_launchpad_url
                                  i_intent        = `ABAP_PRC_ProcessedObject-show`
                                  i_parameters    = |ProcessName={ m_process_name }&MessageSeverity=E|
                                  i_text          = `Show all objects with errors in the Processing Center` ) &&
                   |</p><p><strong>Action required:</strong> please resolve the errors and resume the processing.</p>|.

    ls_payload-notification = VALUE #(
        recipient = ls_payload-mail_address
        subject   = |ABAP Processing Center: { m_count } objects of process { m_process_name } with errors|
        body_html = zcl_prc_notification=>html_document( i_headline = |Errors in process { m_process_name }|
                                                         i_content  = lv_content ) ).

    c_payload_json = zcl_prc_notification=>payload_to_json( ls_payload ).
    r_new_state = zcl_prc_notification=>co_prepared.
  ENDMETHOD.

  METHOD get_success_message.
    IF m_count = 0.
      MESSAGE s002(zprc_notification) WITH m_process_name INTO DATA(lv_dummy) ##NEEDED.
    ELSE.
      MESSAGE s001(zprc_notification) WITH m_count m_process_name INTO lv_dummy.
    ENDIF.
    r_message = sy_message( ).
  ENDMETHOD.
ENDCLASS.
