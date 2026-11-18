"! <p class="shorttext synchronized">ABAP-PRC: Step layer 3 - write result</p>
"!
"! Decides what is persisted after a successful transition: new state, payload,
"! retry reset, the step, all messages of the handler and the step header.
"! Writes within the running LUW, the commit is the next layer.
"!
"! The step header is chosen here, where success is known (the save
"! simulation passed), by ZCL_PRC_STEP_HEADER=>FOR_SUCCESS. It is handed to the
"! step writer only, not to the message handler: it reaches the persistence
"! with the commit of the step. If the commit fails, it is rolled back with
"! the step and does not show up among the messages of the failed step.
"!
"! <h2>Findings</h2>
"! An error in the handler without a failure is a finding (I_FAIL_STEP =
"! ABAP_FALSE) - every other way of adding an error raises. A transition with
"! findings has to end in its start state (X -> X), otherwise the step fails
"! with ZPRC_PROCESS_MESSAGE/024 (HAS_FINDINGS, also used by
"! ZCL_PRC_TRANSITION_HANDLR_TEST). The step is written with the end state and
"! payload of the transition, the last error as header
"! (ZCL_PRC_STEP_HEADER=>FOR_FINDINGS) and the next retry data, and committed
"! with all changes of the transition. The retry data stop the step loop -
"! X -> X would run endlessly otherwise - and keep the object erroneous until
"! it is resumed.
"!
"! <h2>Simulation</h2>
"! In a simulation run (Simulation = X) the changes of the transition are
"! rolled back (ROLLBACK ENTITIES, ROLLBACK WORK) before the step is written:
"! the commit of the next layer saves the step only. The PRC persistence is
"! written directly, not through the RAP buffer or the update task, so the
"! step is not affected by the rollback. Findings end the object in FINISHED
"! (ZCL_PRC_STEP_WRITER->WITH_NEXT_RETRY).
CLASS zcl_prc_step_3_result DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_prc_processing_step.

    METHODS constructor IMPORTING i_inner       TYPE REF TO zif_prc_processing_step
                                  i_step_writer TYPE REF TO zcl_prc_step_writer.

    "! Whether a transition that did not fail ended with findings. The one place
    "! of this rule, used by this layer and by ZCL_PRC_TRANSITION_HANDLR_TEST.
    "!
    "! @parameter i_start_state               | Start state of the transition.
    "! @parameter i_end_state                 | End state of the transition.
    "! @parameter i_message_handler           | Handler of the step.
    "! @parameter r_has_findings              | ABAP_TRUE if the handler contains an error.
    "! @raising   zcx_prc_unit_of_work_failed | Findings, but not back to the start state (024).
    CLASS-METHODS has_findings IMPORTING i_start_state         TYPE zif_prc_process=>ty_state
                                         i_end_state           TYPE zif_prc_process=>ty_state
                                         i_message_handler     TYPE REF TO zif_prc_message_handler
                               RETURNING VALUE(r_has_findings) TYPE abap_bool
                               RAISING   zcx_prc_unit_of_work_failed.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mo_inner       TYPE REF TO zif_prc_processing_step.
    DATA mo_step_writer TYPE REF TO zcl_prc_step_writer.
ENDCLASS.



CLASS zcl_prc_step_3_result IMPLEMENTATION.

  METHOD constructor.
    mo_inner       = i_inner.
    mo_step_writer = i_step_writer.
  ENDMETHOD.


  METHOD has_findings.
    " The transition did not fail, so its errors are findings
    r_has_findings = i_message_handler->has_errors( ).

    " Only a transition back to its start state may end with findings
    IF r_has_findings = abap_true AND i_end_state <> i_start_state.
      MESSAGE e024(zprc_process_message) WITH i_start_state i_end_state
              INTO DATA(wrong_end_state) ##NEEDED.
      i_message_handler->add_message_from_sy( ).
    ENDIF.
  ENDMETHOD.


  METHOD zif_prc_processing_step~execute.
    r_state = mo_inner->execute( EXPORTING i_state           = i_state
                                           i_message_handler = i_message_handler
                                 IMPORTING e_transition      = e_transition ).

    " Simulation: only the step is saved, never the changes of the transition
    IF i_state-Simulation = abap_true.
      ROLLBACK ENTITIES.
      ROLLBACK WORK.
    ENDIF.

    IF has_findings( i_start_state     = i_state-State
                     i_end_state       = r_state-State
                     i_message_handler = i_message_handler ) = abap_true.
      r_state = mo_step_writer->write( i_start_state     = i_state-State
                                       i_state           = mo_step_writer->with_next_retry( r_state )
                                       i_header          = zcl_prc_step_header=>for_findings( i_message_handler )
                                       i_message_handler = i_message_handler ).
      RETURN.
    ENDIF.

    DATA(header) = zcl_prc_step_header=>for_success( i_transition      = e_transition
                                                     i_message_handler = i_message_handler ).

    r_state = mo_step_writer->write( i_start_state     = i_state-State
                                     i_state           = VALUE #( BASE r_state
                                                                  RetryCount    = 0
                                                                  RetryDateTime = 0 )
                                     i_header          = header
                                     i_message_handler = i_message_handler ).
  ENDMETHOD.

ENDCLASS.
