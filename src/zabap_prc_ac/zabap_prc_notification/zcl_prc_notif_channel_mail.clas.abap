"! <p class="shorttext synchronized">ABAP-PRC: Notification channel mail</p>
"!
"! Sends a prepared notification as HTML mail (CL_BCS_MAIL_MESSAGE). Errors of
"! the mail service are reported into the message handler and fail the step,
"! so the send step is retried and can be resumed.
CLASS zcl_prc_notif_channel_mail DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_prc_notification_channel.

    "! Sender until the process configuration (Nr. 18) provides one
    CONSTANTS co_sender TYPE string VALUE `no_reply@abap-processing-center.de`.

  PRIVATE SECTION.
    METHODS _set_importance_high IMPORTING io_mail TYPE REF TO cl_bcs_mail_message.
ENDCLASS.



CLASS zcl_prc_notif_channel_mail IMPLEMENTATION.

  METHOD zif_prc_notification_channel~send.
    TRY.
        DATA(lo_mail) = cl_bcs_mail_message=>create_instance( ).
        _set_importance_high( lo_mail ).
        lo_mail->set_sender( CONV #( co_sender ) ).
        lo_mail->add_recipient( CONV #( condense( i_notification-recipient ) ) ).
        lo_mail->set_subject( CONV #( i_notification-subject ) ).
        lo_mail->set_main( cl_bcs_mail_textpart=>create_text_html( i_notification-body_html ) ).
        lo_mail->send( IMPORTING ev_mail_status = DATA(lv_mail_status) ).
      CATCH cx_bcs_mail INTO DATA(lo_error).
        i_message_handler->add_exception( lo_error ).
    ENDTRY.

    IF lv_mail_status = 'E'.
      MESSAGE e010(zprc_notification) WITH lv_mail_status INTO DATA(lv_dummy) ##NEEDED.
      i_message_handler->add_message_from_sy( ).
    ENDIF.
  ENDMETHOD.

  METHOD _set_importance_high.
    " SET_IMPORTANCE does not exist on 2023 - release switch by dynamic call
    TRY.
        CALL METHOD io_mail->('SET_IMPORTANCE')
          EXPORTING iv_importance = 1.
      CATCH cx_sy_dyn_call_error ##NO_HANDLER.
        " older release: normal importance
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
