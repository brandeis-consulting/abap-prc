"! <p class="shorttext synchronized">ABAP-PRC: Step layer 5 - expected errors</p>
"!
"! Catches business errors - from the transition, the simulation or the commit,
"! all signalled by ZCX_PRC_UNIT_OF_WORK_FAILED. Rolls back, adds the failure
"! message of the transition as the last error - which makes it the step
"! header - and writes the failed step with all messages of the handler and the
"! next retry data in a new LUW.
CLASS zcl_prc_step_5_expected DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_prc_processing_step.

    METHODS constructor IMPORTING i_inner       TYPE REF TO zif_prc_processing_step
                                  i_step_writer TYPE REF TO zcl_prc_step_writer.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mo_inner       TYPE REF TO zif_prc_processing_step.
    DATA mo_step_writer TYPE REF TO zcl_prc_step_writer.

    "! Adds the failure message of the transition, if it declares one.
    METHODS add_failure_message IMPORTING i_transition      TYPE REF TO zif_prc_transition_handler
                                          i_message_handler TYPE REF TO zif_prc_message_handler.
ENDCLASS.



CLASS zcl_prc_step_5_expected IMPLEMENTATION.

  METHOD constructor.
    mo_inner       = i_inner.
    mo_step_writer = i_step_writer.
  ENDMETHOD.


  METHOD zif_prc_processing_step~execute.
    TRY.
        r_state = mo_inner->execute( EXPORTING i_state           = i_state
                                               i_message_handler = i_message_handler
                                     IMPORTING e_transition      = e_transition ).

      CATCH zcx_prc_unit_of_work_failed.
        " ROLLBACK ENTITIES rolls back nothing without a RAP buffer (e.g. a pure BAPI
        " process). ROLLBACK WORK discards registered update function modules and
        " the SQL of the result layer in every case.
        ROLLBACK ENTITIES.
        ROLLBACK WORK.

        add_failure_message( i_transition      = e_transition
                             i_message_handler = i_message_handler ).

        " The state before the step, only the retry data change
        r_state = mo_step_writer->write( i_start_state     = i_state-State
                                         i_state           = mo_step_writer->with_next_retry( i_state )
                                         i_header          = i_message_handler->get_header( )
                                         i_message_handler = i_message_handler ).
        " The RAP buffer is empty after the rollback, so COMMIT ENTITIES alone
        " would not commit the step written by SQL
        COMMIT ENTITIES.
        COMMIT WORK.
    ENDTRY.
  ENDMETHOD.


  METHOD add_failure_message.
    " The transition is unbound if it could not be instantiated
    IF i_transition IS NOT BOUND.
      RETURN.
    ENDIF.
    DATA(failure) = i_transition->get_failure_message( ).
    IF failure IS INITIAL.
      RETURN.
    ENDIF.

    " As the last error of the step it becomes the header (last of the highest severity)
    MESSAGE ID failure-msgid TYPE 'E' NUMBER failure-msgno
            WITH failure-msgv1 failure-msgv2 failure-msgv3 failure-msgv4
            INTO DATA(message) ##NEEDED.
    TRY.
        i_message_handler->add_message_from_sy( i_fail_on_error_message = abap_false ).
      CATCH zcx_prc_unit_of_work_failed ##NO_HANDLER.
        " Cannot happen with i_fail_on_error_message = abap_false
    ENDTRY.
  ENDMETHOD.

ENDCLASS.

