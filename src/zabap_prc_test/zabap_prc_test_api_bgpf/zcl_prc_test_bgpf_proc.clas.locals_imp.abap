CLASS lcl_start_to_finish DEFINITION INHERITING FROM zcl_prc_transition_handlr_base.
  PROTECTED SECTION.
    METHODS perform_transition  REDEFINITION.
    METHODS get_success_message REDEFINITION.
ENDCLASS.


CLASS lcl_start_to_finish IMPLEMENTATION.

  METHOD perform_transition.
  ENDMETHOD.

  METHOD get_success_message.
    MESSAGE s001(zprc_test_bgpf) WITH i_processed_object_ext_id INTO DATA(lv_dummy_message) ##NEEDED.
    r_message = CORRESPONDING #( sy ).
  ENDMETHOD.

ENDCLASS.
