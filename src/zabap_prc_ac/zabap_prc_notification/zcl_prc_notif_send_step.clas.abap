"! <p class="shorttext synchronized">ABAP-PRC: Notification - send step</p>
"!
"! Transition PREPARED -> FINISHED of both notification processes: sends the
"! notification the prepare step put into the payload via BAdI
"! ZPRC_NOTIFICATION_CHANNEL (filter CHANNEL = MAIL; fallback class
"! ZCL_PRC_NOTIF_CHANNEL_MAIL) and stores the time it was sent. A failure is an
"! error step with retry; resume sends the prepared notification again.
CLASS zcl_prc_notif_send_step DEFINITION
  PUBLIC FINAL
  INHERITING FROM zcl_prc_transition_handlr_base
  CREATE PUBLIC.

  PROTECTED SECTION.
    METHODS perform_transition REDEFINITION.
    METHODS get_success_message REDEFINITION.
    METHODS get_failure_message REDEFINITION.

  PRIVATE SECTION.
    DATA m_recipient TYPE string.

    "! Sends via every active implementation of the channel.
    METHODS _send IMPORTING i_notification TYPE zif_prc_notification_channel=>ty_notification
                  RAISING   zcx_prc_unit_of_work_failed.
ENDCLASS.



CLASS zcl_prc_notif_send_step IMPLEMENTATION.

  METHOD perform_transition.
    DATA ls_payload TYPE zcl_prc_notification=>ty_payload.

    IF zcl_prc_notification=>payload_from_json( EXPORTING i_json    = c_payload_json
                                                IMPORTING e_payload = ls_payload ) = abap_false
       OR ls_payload-notification-recipient IS INITIAL.
      MESSAGE e007(zprc_notification) INTO DATA(lv_dummy) ##NEEDED.
      get_message_handler( )->add_message_from_sy( ).
    ENDIF.

    m_recipient = ls_payload-notification-recipient.
    _send( ls_payload-notification ).

    GET TIME STAMP FIELD ls_payload-notification-sent_at.
    c_payload_json = zcl_prc_notification=>payload_to_json( ls_payload ).
    r_new_state = zif_prc_process=>co_finished.
  ENDMETHOD.

  METHOD _send.
    DATA lo_channel TYPE REF TO zprc_notification_channel.

    DATA(lo_message_handler) = get_message_handler( ).
    TRY.
        " the group (mail address) decides the channel
        GET BADI lo_channel FILTERS channel = zif_prc_notification_channel=>co_channel_mail.
        CALL BADI lo_channel->send EXPORTING i_notification    = i_notification
                                             i_message_handler = lo_message_handler.
      CATCH cx_badi INTO DATA(lo_badi_error).
        lo_message_handler->add_exception( lo_badi_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD get_success_message.
    " the recipient may be longer than one message variable: spread over &1-&4
    DATA lv_vars TYPE c LENGTH 200.
    lv_vars = m_recipient.
    MESSAGE s003(zprc_notification) WITH lv_vars(50) lv_vars+50(50) lv_vars+100(50) lv_vars+150(50)
            INTO DATA(lv_dummy) ##NEEDED.
    r_message = sy_message( ).
  ENDMETHOD.

  METHOD get_failure_message.
    " Notification to &1&2&3&4 could not be sent (006 if the recipient is unknown);
    " the cause stays in the additional messages
    r_message = zcl_prc_notification=>send_failure_message( m_recipient ).
  ENDMETHOD.
ENDCLASS.
