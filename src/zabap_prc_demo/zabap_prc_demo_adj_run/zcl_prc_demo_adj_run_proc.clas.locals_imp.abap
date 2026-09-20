CLASS lcl_root DEFINITION INHERITING FROM zcl_prc_transition_handlr_base ABSTRACT.
  PROTECTED SECTION.
    METHODS get_message_prefix_for_log REDEFINITION.
ENDCLASS.


CLASS lcl_root IMPLEMENTATION.

  METHOD get_message_prefix_for_log.
    MESSAGE i009(zprc_demo_adjust_run) WITH i_processed_object_ext_id INTO DATA(message_prefix).
    r_message = CORRESPONDING #( sy ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_adjust DEFINITION INHERITING FROM lcl_root.
  PROTECTED SECTION.
    METHODS get_success_message REDEFINITION.
    METHODS perform_transition REDEFINITION.
ENDCLASS.


CLASS lcl_adjust IMPLEMENTATION.
  METHOD perform_transition.
    WAIT UP TO 1 SECONDS.
    IF sy-uzeit MOD 10 = 3.
      MESSAGE e004(zprc_demo_adjust_run) WITH i_processed_object_ext_id INTO DATA(lv_dummy) ##NEEDED.
      get_message_handler( )->add_message_from_sy( ).
    ELSEIF sy-uzeit MOD 10 = 5.
      MESSAGE e005(zprc_demo_adjust_run) WITH i_processed_object_ext_id INTO lv_dummy.
      get_message_handler( )->add_message_from_sy( ).
    ELSE.
      DO 10 TIMES.
        IF sy-uzeit MOD 10 = 3.
          MESSAGE e003(zprc_demo_adjust_run) INTO lv_dummy.
          get_message_handler( )->add_message_from_sy( i_fail_on_error_message = abap_false ).
        ELSE.
          DATA(lv_item_pos) = sy-index * 10.
          MESSAGE s002(zprc_demo_adjust_run) WITH i_processed_object_ext_id lv_item_pos INTO lv_dummy.
          get_message_handler( )->add_message_from_sy( ).
        ENDIF.
      ENDDO.
    ENDIF.
  ENDMETHOD.

  METHOD get_success_message.
    MESSAGE s006(zprc_demo_adjust_run) WITH i_processed_object_ext_id INTO DATA(lv_dummy) ##NEEDED.
    r_message = CORRESPONDING #( sy ).
  ENDMETHOD.
ENDCLASS.
