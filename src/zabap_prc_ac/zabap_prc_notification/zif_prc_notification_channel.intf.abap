"! <p class="shorttext synchronized">ABAP-PRC: Notification channel</p>
"!
"! Sends a notification that the Processing Center has already prepared in its
"! own format (recipient, subject, HTML body). A channel only transports it.
"!
"! Interface of BAdI ZPRC_NOTIFICATION_CHANNEL, filter CHANNEL. The PRC ships
"! the mail channel (ZCL_PRC_NOTIF_CHANNEL_MAIL).
INTERFACE zif_prc_notification_channel
  PUBLIC.

  " Marker: this interface is a BAdI interface
  INTERFACES if_badi_interface.

  "! BAdI filter value of the mail channel
  CONSTANTS co_channel_mail TYPE string VALUE `MAIL`.

  " Notification in the format of the Processing Center: recipient (e.g. a mail
  " address), subject, complete HTML document and the time the send step sent it.
  TYPES: BEGIN OF ty_notification,
           recipient TYPE string,
           subject   TYPE string,
           body_html TYPE string,
           sent_at   TYPE tzntstmpl,
         END OF ty_notification.

  "! Sends the notification.
  "!
  "! Report every problem into the message handler (ADD_EXCEPTION,
  "! ADD_MESSAGE_FROM_SY); a failure raises out of the handler and the send step
  "! is written as error with retry. Do not commit - the engine does that.
  "!
  "! @parameter i_notification        | Prepared notification.
  "! @parameter i_message_handler     | Message handler of the send step.
  "! @raising   zcx_prc_unit_of_work_failed | Raised by the message handler on failure.
  METHODS send IMPORTING i_notification    TYPE ty_notification
                         i_message_handler TYPE REF TO zif_prc_message_handler
               RAISING   zcx_prc_unit_of_work_failed.

ENDINTERFACE.
