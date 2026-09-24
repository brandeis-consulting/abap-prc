CLASS lcl_root DEFINITION INHERITING FROM zcl_prc_transition_handlr_base ABSTRACT.
  PROTECTED SECTION.
    METHODS get_message_prefix_for_log REDEFINITION.
ENDCLASS.


CLASS lcl_root IMPLEMENTATION.

  METHOD get_message_prefix_for_log.
    MESSAGE i009(zprc_demo_api_equi) WITH i_processed_object_ext_id INTO DATA(message_prefix).
    r_message = CORRESPONDING #( sy ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_assign_to_srv_ctr DEFINITION INHERITING FROM lcl_root.
  PROTECTED SECTION.
    METHODS get_success_message REDEFINITION.
    METHODS get_failure_message REDEFINITION.
    METHODS perform_transition REDEFINITION.
ENDCLASS.


CLASS lcl_assign_to_srv_ctr IMPLEMENTATION.
  METHOD perform_transition.
    DATA(lv_equipment_id) = i_processed_object_ext_id.

    UPDATE zprc_demo_sc_itm
      SET equipment_id = ''
      WHERE equipment_id = @lv_equipment_id.

    IF sy-subrc <> 0.
      MESSAGE e002(zprc_demo_event_equi) WITH i_processed_object_ext_id INTO DATA(lv_dummy_message) ##NEEDED.
      get_message_handler( )->add_message_from_sy( ).
    ENDIF.
  ENDMETHOD.

  METHOD get_failure_message.
    MESSAGE e002(zprc_demo_event_equi) INTO DATA(lv_dummy_message) ##NEEDED.
    r_message = CORRESPONDING #( sy ).
  ENDMETHOD.

  METHOD get_success_message.
    MESSAGE s001(zprc_demo_event_equi) WITH i_processed_object_ext_id INTO DATA(lv_dummy_message) ##NEEDED.
    r_message = CORRESPONDING #( sy ).
  ENDMETHOD.
ENDCLASS.
