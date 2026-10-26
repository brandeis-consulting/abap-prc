"! <p class="shorttext synchronized">ABAP-PRC: Step layer 2 - simulation</p>
"!
"! Decides whether the RAP buffer of the process class can be saved:
"! COMMIT ENTITIES IN SIMULATION MODE runs FINALIZE and CHECK_BEFORE_SAVE only.
"! Safe for pure BAPI steps, an empty buffer simply passes. A failure reaches
"! the handler and raises ZCX_PRC_UNIT_OF_WORK_FAILED.
CLASS zcl_prc_step_2_simulation DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_prc_processing_step.

    METHODS constructor IMPORTING i_inner TYPE REF TO zif_prc_processing_step.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mo_inner TYPE REF TO zif_prc_processing_step.
ENDCLASS.



CLASS zcl_prc_step_2_simulation IMPLEMENTATION.

  METHOD constructor.
    mo_inner = i_inner.
  ENDMETHOD.


  METHOD zif_prc_processing_step~execute.
    r_state = mo_inner->execute( EXPORTING i_state           = i_state
                                           i_message_handler = i_message_handler
                                 IMPORTING e_transition      = e_transition ).

    COMMIT ENTITIES IN SIMULATION MODE
           RESPONSES
           FAILED   DATA(failed)
           REPORTED DATA(reported).
    DATA(saveable) = xsdbool( sy-subrc = 0 ).

    i_message_handler->add_eml_modify_result( i_failed   = failed
                                              i_reported = reported ).
    IF saveable = abap_false.
      " Not saveable without FAILED (BO violates the RAP contract) fails the step all the same.
      " Not reachable through a contract-conform RAP BO, therefore not covered by a test.
      MESSAGE e015(zprc_process_message) INTO DATA(message) ##NEEDED.
      i_message_handler->add_message_from_sy( ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.

