"! <p class="shorttext synchronized">ABAP-PRC: Process run completed notification</p>
"!
"! One processed object per run, created by ZCL_PRC_RUN_JOB when the job ends.
"! The payload holds the run; the prepare step reads the result of the run and
"! the mail address of the user who started it, the send step sends the mail.
"!
"! <ul>
"! <li>START -> PREPARED: prepare (ZCL_PRC_NOTIF_RUN_PROC, local)</li>
"! <li>PREPARED -> FINISHED: send (ZCL_PRC_NOTIF_SEND_STEP)</li>
"! </ul>
"!
"! Without mail address of the user the prepare step fails (ZPRC_NOTIFICATION/004);
"! maintain the address and resume.
CLASS zcl_prc_notif_run_proc DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_prc_process.

    CONSTANTS co_class_name   TYPE zprc_process_impl_class VALUE 'ZCL_PRC_NOTIF_RUN_PROC'.
    CONSTANTS co_process_name TYPE zprc_process_name       VALUE 'PRC_RUN_COMPLETED'.

    "! Creates the notification of a finished run (without processing it).
    "!
    "! @parameter i_run_uuid         | The run.
    "! @parameter i_application_name | Application of the run, part of the readable ID.
    "! @parameter i_job_start        | Start of the run, part of the readable ID.
    CLASS-METHODS create_notification IMPORTING i_run_uuid         TYPE sysuuid_x16
                                                i_application_name TYPE zprc_run_app_name
                                                i_job_start        TYPE tzntstmpl
                                      RETURNING VALUE(r_object)    TYPE zcl_prc_processing_api=>tt_create_processed_objects.
ENDCLASS.



CLASS zcl_prc_notif_run_proc IMPLEMENTATION.

  METHOD zif_prc_process~get_transitions.
    r_transitions = VALUE #( ( start_state = zif_prc_process~co_start         end_state = zcl_prc_notification=>co_prepared )
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

  METHOD create_notification.
    r_object = VALUE #( ( processName         = co_process_name
                          factoryClassName    = co_class_name
                          processedObject     = zcl_prc_notification=>object_id(
                                                    |{ i_application_name } { zcl_prc_notification=>timestamp_text( i_job_start ) }| )
                          processedObjectUUID = i_run_uuid
                          payloadJson         = zcl_prc_notification=>payload_to_json( VALUE #( run_uuid = i_run_uuid ) ) ) ).
  ENDMETHOD.
ENDCLASS.
