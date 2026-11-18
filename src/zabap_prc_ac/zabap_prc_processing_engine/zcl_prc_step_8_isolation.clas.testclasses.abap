"! @testing ZCL_PRC_STEP_8_ISOLATION
CLASS ltc_abort_header DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    METHODS without_dump_is_abort      FOR TESTING.
    METHODS runtime_error_is_abort     FOR TESTING.
    METHODS success_is_no_abort        FOR TESTING.
    METHODS old_program_error_is_no_abort FOR TESTING.
    METHODS other_class_is_no_abort    FOR TESTING.
ENDCLASS.


CLASS ltc_abort_header IMPLEMENTATION.

  METHOD without_dump_is_abort.
    cl_abap_unit_assert=>assert_true(
        zcl_prc_step_8_isolation=>is_abort_header( i_message_class = 'ZPRC_PROCESS_MESSAGE' i_message_number = '019' ) ).
  ENDMETHOD.


  METHOD runtime_error_is_abort.
    " The header written with a short dump - the log layer must not load the process for it
    cl_abap_unit_assert=>assert_true(
        zcl_prc_step_8_isolation=>is_abort_header( i_message_class = 'ZPRC_PROCESS_MESSAGE' i_message_number = '025' ) ).
  ENDMETHOD.


  METHOD success_is_no_abort.
    cl_abap_unit_assert=>assert_false(
        zcl_prc_step_8_isolation=>is_abort_header( i_message_class = 'ZPRC_PROCESS_MESSAGE' i_message_number = '017' ) ).
  ENDMETHOD.


  METHOD old_program_error_is_no_abort.
    " 018 is no longer written by this layer
    cl_abap_unit_assert=>assert_false(
        zcl_prc_step_8_isolation=>is_abort_header( i_message_class = 'ZPRC_PROCESS_MESSAGE' i_message_number = '018' ) ).
  ENDMETHOD.


  METHOD other_class_is_no_abort.
    cl_abap_unit_assert=>assert_false(
        zcl_prc_step_8_isolation=>is_abort_header( i_message_class = 'ZPRC_TEST_PROC' i_message_number = '025' ) ).
  ENDMETHOD.

ENDCLASS.
