CLASS zcl_prc_demo_equi_assign_proc DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_prc_process.

    ALIASES tt_transition FOR zif_prc_process~tt_transition.
    ALIASES ty_state      FOR zif_prc_process~ty_state.

    CONSTANTS co_class_name    TYPE zprc_process_impl_class VALUE 'ZCL_PRC_DEMO_EQUI_ASSIGN_PROC'.
    CONSTANTS co_process_name  TYPE zprc_process_name VALUE 'DEMO_EQUI_ASSIGN_CONTRACT'.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.



CLASS zcl_prc_demo_equi_assign_proc IMPLEMENTATION.


  METHOD zif_prc_process~get_transitions.
    rt_transitions = VALUE tt_transition( ( start_state = zif_prc_process~co_start  end_state   = zif_prc_process~co_finished ) ).
  ENDMETHOD.


  METHOD zif_prc_process~get_transition_handler.
    CASE i_start_state.
      WHEN zif_prc_process~co_start.
        ro_transition_handler = NEW lcl_assign_to_srv_ctr( ).
      WHEN OTHERS.
        " unexpected state
        ASSERT 1 = 2.
    ENDCASE.
  ENDMETHOD.


  METHOD zif_prc_process~get_url_for_processed_object.
    RETURN |#ABAP_PRC_Demo_Equipment-show&/Equipment(Identifier='{ iv_processed_object }',IsActiveEntity=true)|.
  ENDMETHOD.
ENDCLASS.
