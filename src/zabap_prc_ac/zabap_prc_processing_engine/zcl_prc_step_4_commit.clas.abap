"! <p class="shorttext synchronized">ABAP-PRC: Step layer 4 - commit</p>
"!
"! Decides whether the LUW of the step can be saved. Sets the local update task
"! before anything is registered, then commits. A failed commit reaches the
"! handler and raises ZCX_PRC_UNIT_OF_WORK_FAILED.
"!
"! Late messages - reported in the save phase without FAILED - arrive only with
"! the commit, after the step was written. They are added to the step in a LUW
"! of their own right after the commit; losing them in between is acceptable.
CLASS zcl_prc_step_4_commit DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_prc_processing_step.

    METHODS constructor IMPORTING i_inner       TYPE REF TO zif_prc_processing_step
                                  i_step_writer TYPE REF TO zcl_prc_step_writer.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mo_inner       TYPE REF TO zif_prc_processing_step.
    DATA mo_step_writer TYPE REF TO zcl_prc_step_writer.

    "! SET UPDATE TASK LOCAL through the released Standard ABAP implementation,
    "! created dynamically. Without it (ABAP Cloud, BTP) the update task is local anyway.
    METHODS set_update_task_local.

    "! Adds the late messages of a successful commit to the step just written.
    METHODS add_late_messages IMPORTING i_state           TYPE zif_prc_processing_engine=>ty_state
                                        i_message_handler TYPE REF TO zif_prc_message_handler
                                        i_reported        TYPE abp_behv_response_tab.
ENDCLASS.



CLASS zcl_prc_step_4_commit IMPLEMENTATION.

  METHOD constructor.
    mo_inner       = i_inner.
    mo_step_writer = i_step_writer.
  ENDMETHOD.


  METHOD zif_prc_processing_step~execute.
    " Before the first update function module is registered: a failing one aborts
    " the session and is caught by the isolation layer
    set_update_task_local( ).

    r_state = mo_inner->execute( EXPORTING i_state           = i_state
                                           i_message_handler = i_message_handler
                                 IMPORTING e_transition      = e_transition ).

    COMMIT ENTITIES RESPONSES FAILED DATA(failed) REPORTED DATA(reported).
    IF sy-subrc = 0.
      " COMMIT ENTITIES does not commit without a RAP buffer: the update function
      " modules of classic BAPIs would never run
      COMMIT WORK.
      add_late_messages( i_state           = r_state
                         i_message_handler = i_message_handler
                         i_reported        = reported ).
      RETURN.
    ENDIF.

    i_message_handler->add_eml_modify_result( i_failed   = failed
                                              i_reported = reported ).
    " A failed commit without FAILED (BO violates the RAP contract) fails the step all the same.
    " Not reachable through a contract-conform RAP BO, therefore not covered by a test.
    MESSAGE e016(zprc_process_message) INTO DATA(message) ##NEEDED.
    i_message_handler->add_message_from_sy( ).
  ENDMETHOD.


  METHOD add_late_messages.
    IF i_reported IS INITIAL.
      RETURN.
    ENDIF.

    DATA(written) = lines( i_message_handler->get_messages( ) ).
    TRY.
        i_message_handler->add_eml_modify_result( i_reported = i_reported ).
      CATCH zcx_prc_unit_of_work_failed ##NO_HANDLER.
        " Cannot happen without FAILED - and the step is committed already
    ENDTRY.

    " Only the messages added now; the others were written with the step
    DATA(messages) = i_message_handler->get_messages( ).
    DATA(late) = VALUE zif_prc_message_handler=>tt_messages( FOR i = written + 1 WHILE i <= lines( messages )
                                                             ( messages[ i ] ) ).
    mo_step_writer->add_messages( i_state    = i_state
                                  i_messages = late ).
    COMMIT WORK.
  ENDMETHOD.


  METHOD set_update_task_local.
    " The name is taken at runtime on purpose: the implementation is Standard ABAP
    " and does not exist in ABAP Cloud (BTP)
    DATA(implementation) = zif_prc_update_task=>co_implementation.
    TRY.
        DATA update_task TYPE REF TO zif_prc_update_task.
        CREATE OBJECT update_task TYPE (implementation).
        update_task->set_local( ).
      CATCH cx_sy_create_object_error ##NO_HANDLER.
        " Not available in ABAP Cloud (BTP): there the update task is always local
    ENDTRY.
  ENDMETHOD.

ENDCLASS.

