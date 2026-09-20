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
    IF sy-uzeit MOD 10 = 1.
      MESSAGE e001(zprc_demo_api_equi) INTO DATA(lv_dummy_message) ##NEEDED.
      get_message_handler( )->add_message_from_sy( ).
    ENDIF.
  ENDMETHOD.

  METHOD get_failure_message.
    MESSAGE e010(zprc_demo_api_equi) INTO DATA(lv_dummy_message) ##NEEDED.
    r_message = CORRESPONDING #( sy ).
  ENDMETHOD.

  METHOD get_success_message.
    MESSAGE s002(zprc_demo_api_equi) INTO DATA(lv_dummy_message) ##NEEDED.
    r_message = CORRESPONDING #( sy ).
  ENDMETHOD.
ENDCLASS.


CLASS lcl_create_equi DEFINITION INHERITING FROM lcl_root.
  PROTECTED SECTION.
    METHODS get_failure_message REDEFINITION.
    METHODS perform_transition REDEFINITION.
    METHODS get_success_message REDEFINITION.
ENDCLASS.


CLASS lcl_create_equi IMPLEMENTATION.
  METHOD perform_transition.
    WAIT UP TO 1 SECONDS.
    IF sy-uzeit MOD 10 = 1.
      MESSAGE e003(zprc_demo_api_equi) INTO DATA(lv_dummy_message) ##NEEDED.
      get_message_handler( )->add_message_from_sy( ).
    ENDIF.
  ENDMETHOD.

  METHOD get_failure_message.
    MESSAGE e011(zprc_demo_api_equi) INTO DATA(lv_dummy_message) ##NEEDED.
    r_message = CORRESPONDING #( sy ).
  ENDMETHOD.

  METHOD get_success_message.
    MESSAGE s004(zprc_demo_api_equi) INTO DATA(lv_dummy_message) ##NEEDED.
    r_message = CORRESPONDING #( sy ).
  ENDMETHOD.
ENDCLASS.


CLASS lcl_link_serial DEFINITION INHERITING FROM lcl_root.
  PROTECTED SECTION.
    METHODS get_success_message REDEFINITION.
    METHODS perform_transition REDEFINITION.
ENDCLASS.


CLASS lcl_link_serial IMPLEMENTATION.
  METHOD perform_transition.
    WAIT UP TO 1 SECONDS.
    IF sy-uzeit MOD 10 = 1.
      MESSAGE e005(zprc_demo_api_equi) INTO DATA(lv_dummy_message) ##NEEDED.
      get_message_handler( )->add_message_from_sy( ).
    ENDIF.
  ENDMETHOD.

  METHOD get_success_message.
    MESSAGE s006(zprc_demo_api_equi) INTO DATA(lv_dummy_message) ##NEEDED.
    r_message = CORRESPONDING #( sy ).
  ENDMETHOD.
ENDCLASS.


CLASS lcl_check_install DEFINITION INHERITING FROM lcl_root.
  PROTECTED SECTION.
    METHODS get_success_message REDEFINITION.
    METHODS perform_transition REDEFINITION.
    DATA: mv_next_state TYPE zif_prc_process=>ty_state.
ENDCLASS.

CLASS lcl_check_install IMPLEMENTATION.
  METHOD perform_transition.
    WAIT UP TO 1 SECONDS.

    IF sy-uzeit MOD 2 = 0.
      r_new_state = zif_prc_process=>co_finished.
    ELSE.
      r_new_state = zcl_prc_demo_create_equi_proc=>co_install_equi.
    ENDIF.
      mv_next_state = r_new_state.
  ENDMETHOD.

  METHOD get_success_message.
    IF mv_next_state = zcl_prc_demo_create_equi_proc=>co_install_equi.
      MESSAGE s013(zprc_demo_api_equi) INTO DATA(lv_dummy_message) ##NEEDED.
    ELSE.
      MESSAGE s012(zprc_demo_api_equi) INTO lv_dummy_message ##NEEDED.
    ENDIF.
    r_message = CORRESPONDING #( sy ).
  ENDMETHOD.
ENDCLASS.



CLASS lcl_install_equi DEFINITION INHERITING FROM lcl_root.
  PROTECTED SECTION.
    METHODS perform_transition REDEFINITION.
    METHODS get_success_message REDEFINITION.
ENDCLASS.


CLASS lcl_install_equi IMPLEMENTATION.
  METHOD perform_transition.
    WAIT UP TO 1 SECONDS.
    IF sy-uzeit MOD 10 = 1.
      MESSAGE e007(zprc_demo_api_equi) INTO DATA(lv_dummy_message) ##NEEDED.
      get_message_handler( )->add_message_from_sy( ).
    ENDIF.
  ENDMETHOD.

  METHOD get_success_message.
    MESSAGE s008(zprc_demo_api_equi) INTO DATA(lv_dummy_message) ##NEEDED.
    r_message = CORRESPONDING #( sy ).
  ENDMETHOD.
ENDCLASS.
