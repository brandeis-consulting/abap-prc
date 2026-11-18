"! <p class="shorttext synchronized">ABAP-PRC: Rule for simulation runs</p>
"!
"! The one place of the rule whether a process may run in a simulation: the
"! process allows it (ZIF_PRC_PROCESS~SUPPORTS_SIMULATION) and knows no states
"! but START and FINISHED - one step, START to FINISHED, or START to START with
"! findings. A simulation is over after one step, so a process with further
"! states would never reach its end.
"!
"! Used before the first object exists (ZCL_PRC_RUN_JOB, run aborted) and by
"! the engine before a transition is performed (step FINISHED with error, the
"! transition is not called).
CLASS zcl_prc_simulation DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    "! Why the process may not run in a simulation.
    "!
    "! @parameter i_process    | The process.
    "! @parameter i_class_name | Class of the process, for the message.
    "! @parameter r_message    | Reason (ZPRC_PROCESS_MESSAGE/026 or 027); initial if allowed.
    CLASS-METHODS check IMPORTING i_process        TYPE REF TO zif_prc_process
                                  i_class_name     TYPE zprc_process_impl_class
                        RETURNING VALUE(r_message) TYPE symsg.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_prc_simulation IMPLEMENTATION.

  METHOD check.
    IF i_process IS NOT BOUND OR i_process->supports_simulation( ) = abap_false.
      " Process class &1 does not allow simulation; nothing was processed
      MESSAGE e026(zprc_process_message) WITH i_class_name INTO DATA(not_allowed) ##NEEDED.
      r_message = VALUE #( msgid = sy-msgid msgty = sy-msgty msgno = sy-msgno msgv1 = sy-msgv1 ).
      RETURN.
    ENDIF.

    DATA(transitions) = i_process->get_transitions( ).
    LOOP AT transitions TRANSPORTING NO FIELDS
         WHERE    start_state <> zif_prc_process=>co_start
               OR (     end_state <> zif_prc_process=>co_start
                    AND end_state <> zif_prc_process=>co_finished ).
      " Simulation needs a process with the states START and FINISHED only (&1)
      MESSAGE e027(zprc_process_message) WITH i_class_name INTO DATA(more_states) ##NEEDED.
      r_message = VALUE #( msgid = sy-msgid msgty = sy-msgty msgno = sy-msgno msgv1 = sy-msgv1 ).
      RETURN.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
