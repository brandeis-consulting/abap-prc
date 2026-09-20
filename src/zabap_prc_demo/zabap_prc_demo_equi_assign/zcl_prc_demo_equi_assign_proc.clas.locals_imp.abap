CLASS lcl_root DEFINITION INHERITING FROM zcl_prc_transition_handlr_base ABSTRACT.
  PROTECTED SECTION.
    METHODS get_message_prefix_for_log REDEFINITION.

    DATA mv_processed_object TYPE zr_prc_processedobject-ExternalProcessedObjectID.
ENDCLASS.


CLASS lcl_root IMPLEMENTATION.

  METHOD get_message_prefix_for_log.
    MESSAGE i009(zprc_demo_api_equi) WITH mv_processed_object INTO DATA(message_prefix).
    r_message = CORRESPONDING #( sy ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_validate DEFINITION INHERITING FROM lcl_root.
  PROTECTED SECTION.
    METHODS get_success_message REDEFINITION.
    METHODS get_failure_message REDEFINITION.
    METHODS perform_transition REDEFINITION.
ENDCLASS.


CLASS lcl_validate IMPLEMENTATION.
  METHOD perform_transition.
    WAIT UP TO 1 SECONDS.
    CASE sy-uzeit MOD 4.
      WHEN 1.
        MESSAGE e003(zprc_demo_event_equi) INTO DATA(lv_dummy_message) ##NEEDED.
        get_message_handler( )->add_message_from_sy( ).
      WHEN 2.
        MESSAGE e004(zprc_demo_event_equi) INTO lv_dummy_message ##NEEDED.
        get_message_handler( )->add_message_from_sy( ).
    ENDCASE.
  ENDMETHOD.

  METHOD get_failure_message.
    MESSAGE e002(zprc_demo_event_equi) INTO DATA(lv_dummy_message) ##NEEDED.
    r_message = CORRESPONDING #( sy ).
  ENDMETHOD.

  METHOD get_success_message.
    MESSAGE s001(zprc_demo_event_equi) INTO DATA(lv_dummy_message) ##NEEDED.
    r_message = CORRESPONDING #( sy ).
  ENDMETHOD.
ENDCLASS.
.
