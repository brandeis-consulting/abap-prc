"! <p class="shorttext synchronized">ABAP-PRC: Process error notification</p>
"!
"! One processed object per group: process name + mail address of the objects
"! with errors. The payload holds the group; the prepare step reads the objects
"! with errors and puts the mail into the payload, the send step sends it.
"!
"! <ul>
"! <li>START -> PREPARED: prepare (ZCL_PRC_NOTIF_ERROR_PROC, local)</li>
"! <li>START -> FINISHED: no objects with errors left, nothing to send</li>
"! <li>PREPARED -> FINISHED: send (ZCL_PRC_NOTIF_SEND_STEP)</li>
"! </ul>
"!
"! Notification objects carry no mail address themselves, so they are never
"! reported by a notification (no recursion).
CLASS zcl_prc_notif_error_proc DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_prc_process.

    CONSTANTS co_class_name   TYPE zprc_process_impl_class VALUE 'ZCL_PRC_NOTIF_ERROR_PROC'.
    CONSTANTS co_process_name TYPE zprc_process_name       VALUE 'PRC_ERROR_NOTIFY'.
ENDCLASS.



CLASS zcl_prc_notif_error_proc IMPLEMENTATION.

  METHOD zif_prc_process~get_transitions.
    r_transitions = VALUE #( ( start_state = zif_prc_process~co_start         end_state = zcl_prc_notification=>co_prepared )
                             ( start_state = zif_prc_process~co_start         end_state = zif_prc_process~co_finished )
                             ( start_state = zcl_prc_notification=>co_prepared end_state = zif_prc_process~co_finished ) ).
  ENDMETHOD.

  METHOD zif_prc_process~get_transition_handler.
    CASE i_start_state.
      WHEN zif_prc_process~co_start.
        r_transition_handler = NEW lcl_prepare( ).
      WHEN zcl_prc_notification=>co_prepared.
        r_transition_handler = NEW zcl_prc_notif_send_step( ).
    ENDCASE.
  ENDMETHOD.

  METHOD zif_prc_process~get_url_for_processed_object.
    CLEAR r_relative_url.
  ENDMETHOD.
ENDCLASS.
