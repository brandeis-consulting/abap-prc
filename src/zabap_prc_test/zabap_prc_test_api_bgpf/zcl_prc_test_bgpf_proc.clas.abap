"! <p class="shorttext synchronized">PRC Test: Prozess START -> FINISHED (bgPF)</p>
"!
"! Minimaler Testprozess: eine einzige Transition von START nach FINISHED,
"! die nichts tut ausser eine "performed"-Nachricht zu melden.
CLASS zcl_prc_test_bgpf_proc DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_prc_process.

    ALIASES tt_transition FOR zif_prc_process~tt_transition.

    CONSTANTS co_class_name   TYPE zprc_process_impl_class VALUE 'ZCL_PRC_TEST_BGPF_PROC'.
    CONSTANTS co_process_name TYPE zprc_process_name       VALUE 'PRC_TEST_BGPF_ADJ_NUM'.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.



CLASS zcl_prc_test_bgpf_proc IMPLEMENTATION.

  METHOD zif_prc_process~get_transitions.
    rt_transitions = VALUE tt_transition( ( start_state = zif_prc_process~co_start
                                            end_state   = zif_prc_process~co_finished ) ).
  ENDMETHOD.


  METHOD zif_prc_process~get_transition_handler.
    CASE i_start_state.
      WHEN zif_prc_process~co_start.
        ro_transition_handler = NEW lcl_start_to_finish( ).
      WHEN OTHERS.
        " FINISHED hat keine Transition, alles andere ist unerwartet
        ASSERT 1 = 2.
    ENDCASE.
  ENDMETHOD.


  METHOD zif_prc_process~get_url_for_processed_object.
    CLEAR rv_relative_url.
  ENDMETHOD.

ENDCLASS.
