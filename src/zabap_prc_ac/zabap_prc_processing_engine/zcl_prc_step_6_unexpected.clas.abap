"! <p class="shorttext synchronized">ABAP-PRC: Step layer 6 - unexpected errors</p>
"!
"! Catches every other exception - an implementation error of the process class
"! or a violated process definition. Rolls back, adds the exception text as
"! error message and writes the failed step with all messages of the handler
"! and the next retry data in a new LUW.
CLASS zcl_prc_step_6_unexpected DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_prc_processing_step.

    METHODS constructor IMPORTING i_inner       TYPE REF TO zif_prc_processing_step
                                  i_step_writer TYPE REF TO zcl_prc_step_writer.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mo_inner       TYPE REF TO zif_prc_processing_step.
    DATA mo_step_writer TYPE REF TO zcl_prc_step_writer.
ENDCLASS.



CLASS zcl_prc_step_6_unexpected IMPLEMENTATION.

  METHOD constructor.
    mo_inner       = i_inner.
    mo_step_writer = i_step_writer.
  ENDMETHOD.


  METHOD zif_prc_processing_step~execute.
    TRY.
        r_state = mo_inner->execute( EXPORTING i_state           = i_state
                                               i_message_handler = i_message_handler
                                     IMPORTING e_transition      = e_transition ).

      CATCH cx_root INTO DATA(error).
        " ROLLBACK ENTITIES rolls back nothing without a RAP buffer (e.g. a pure BAPI
        " process). ROLLBACK WORK discards registered update function modules and
        " the SQL of the result layer in every case.
        ROLLBACK ENTITIES.
        ROLLBACK WORK.

        TRY.
            " Recorded without failing the handler: the failure is decided here.
            " Keeps the T100 key and the PREVIOUS chain of the exception.
            i_message_handler->add_exception( i_exception             = error
                                              i_fail_on_error_message = abap_false ).
            " A failed step never gets an S/W/I header - also not from an exception
            " that carries a weaker severity (IF_T100_DYN_MSG / IF_ABAP_BEHV_MESSAGE)
            IF i_message_handler->get_header( )-msgty <> 'E'.
              MESSAGE e002(zprc_process_message) INTO DATA(message) ##NEEDED.
              i_message_handler->add_message_from_sy( i_fail_on_error_message = abap_false ).
            ENDIF.
          CATCH zcx_prc_unit_of_work_failed ##NO_HANDLER.
            " Not raised with I_FAIL_ON_ERROR_MESSAGE = abap_false; required by the signature
        ENDTRY.

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

ENDCLASS.

