CLASS ltc_restrict_to_authorized DEFINITION DEFERRED.
CLASS zcl_prc_retry_job DEFINITION LOCAL FRIENDS ltc_restrict_to_authorized.

"! Filter of the retry job: only processes the job user may resume (ZPRC_PROC 16)
CLASS ltc_restrict_to_authorized DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS co_allowed     TYPE zprc_process_name VALUE 'ZPRC_AUTH_TEST_A'.
    CONSTANTS co_not_allowed TYPE zprc_process_name VALUE 'ZPRC_AUTH_TEST_B'.

    CLASS-DATA sql_environment TYPE REF TO if_osql_test_environment.

    DATA cut TYPE REF TO zcl_prc_retry_job.

    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup.
    METHODS teardown.

    METHODS only_authorized_kept      FOR TESTING.
    METHODS empty_selection_means_all FOR TESTING.
    METHODS none_authorized_empty     FOR TESTING.
    METHODS other_parameters_kept     FOR TESTING.

    "! Gives the user ZPRC_PROC for process CO_ALLOWED with the given activity only
    METHODS allow_activity
      IMPORTING i_activity TYPE csequence.

    METHODS process_names_in
      IMPORTING i_parameters   TYPE if_apj_rt_exec_object=>tt_templ_val
      RETURNING VALUE(r_names) TYPE string_table.
ENDCLASS.


CLASS ltc_restrict_to_authorized IMPLEMENTATION.
  METHOD class_setup.
    sql_environment = cl_osql_test_environment=>create( i_dependency_list = VALUE #( ( 'ZI_PRC_PROCESSNAMEVH' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    sql_environment->destroy( ).
  ENDMETHOD.

  METHOD setup.
    sql_environment->clear_doubles( ).

    DATA process_names TYPE STANDARD TABLE OF zi_prc_processnamevh WITH EMPTY KEY.
    process_names = VALUE #( ( ProcessName = co_allowed ) ( ProcessName = co_not_allowed ) ).
    sql_environment->insert_test_data( process_names ).

    cut = NEW #( ).
  ENDMETHOD.

  METHOD teardown.
    cl_aunit_authority_check=>get_controller( )->reset( ).
  ENDMETHOD.

  METHOD allow_activity.
    DATA(authorization) = VALUE cl_aunit_auth_check_types_def=>authorization(
        ( fieldname = 'ZPRCNAME' fieldvalues = VALUE #( ( lower_value = co_allowed ) ) )
        ( fieldname = 'ACTVT'    fieldvalues = VALUE #( ( lower_value = i_activity ) ) ) ).

    DATA(auth_objset) = cl_aunit_authority_check=>create_auth_object_set(
        VALUE #( ( role_authorizations = VALUE #( ( object         = zcl_prc_auth_process=>co_auth_object
                                                    authorizations = VALUE #( ( authorization ) ) ) )
                   users               = VALUE #( ( sy-uname ) ) ) ) ).

    TRY.
        cl_aunit_authority_check=>get_controller( )->restrict_authorizations_to( auth_objset ).
      CATCH cx_abap_auth_check_exception INTO DATA(error).
        cl_abap_unit_assert=>fail( msg = |Restricting authorizations failed: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD process_names_in.
    r_names = VALUE #( FOR p IN i_parameters WHERE ( selname = zcl_prc_retry_job=>co_parameter-process_name )
                       ( CONV string( p-low ) ) ).
  ENDMETHOD.

  METHOD only_authorized_kept.
    allow_activity( '16' ).

    DATA(result) = cut->restrict_to_authorized(
        VALUE #( ( selname = zcl_prc_retry_job=>co_parameter-process_name
                   kind = 'S' sign = 'I' option = 'CP' low = 'ZPRC_AUTH_TEST*' ) ) ).

    cl_abap_unit_assert=>assert_equals( act = process_names_in( result )
                                        exp = VALUE string_table( ( CONV #( co_allowed ) ) )
                                        msg = 'Only the authorized process expected' ).
  ENDMETHOD.

  METHOD empty_selection_means_all.
    " No S_PROC means all processes: the result must be restricted to the authorized ones
    allow_activity( '16' ).

    DATA(result) = cut->restrict_to_authorized( VALUE #( ) ).

    cl_abap_unit_assert=>assert_equals( act = process_names_in( result )
                                        exp = VALUE string_table( ( CONV #( co_allowed ) ) )
                                        msg = 'Empty S_PROC must be restricted to the authorized process' ).
  ENDMETHOD.

  METHOD none_authorized_empty.
    " Display (03) does not allow resume (16): nothing to process
    allow_activity( '03' ).

    DATA(result) = cut->restrict_to_authorized(
        VALUE #( ( selname = zcl_prc_retry_job=>co_parameter-uuid kind = 'S' sign = 'I' option = 'EQ' low = 'ANY' ) ) ).

    cl_abap_unit_assert=>assert_initial( act = result
                                         msg = 'No parameters expected: an empty S_PROC would mean all processes' ).
  ENDMETHOD.

  METHOD other_parameters_kept.
    allow_activity( '16' ).

    DATA(result) = cut->restrict_to_authorized(
        VALUE #( ( selname = zcl_prc_retry_job=>co_parameter-uuid           kind = 'S' sign = 'I' option = 'EQ' low = 'ANY' )
                 ( selname = zcl_prc_retry_job=>co_parameter-ignore_restart kind = 'P' sign = 'I' option = 'EQ' low = 'X' ) ) ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( result[ selname = zcl_prc_retry_job=>co_parameter-uuid low = 'ANY' ] ) )
        msg = 'S_UUID must be kept' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( result[ selname = zcl_prc_retry_job=>co_parameter-ignore_restart low = 'X' ] ) )
        msg = 'P_IGNR must be kept' ).
  ENDMETHOD.
ENDCLASS.
