CLASS ltc_restrict_to_authorized DEFINITION DEFERRED.
CLASS zcl_prc_retry_job DEFINITION LOCAL FRIENDS ltc_restrict_to_authorized.

"! Filter of the retry job: only processes the job user may resume (ZPRC_PROC 16)
CLASS ltc_restrict_to_authorized DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS c_allowed     TYPE zprc_process_name VALUE 'ZPRC_AUTH_TEST_A'.
    CONSTANTS c_not_allowed TYPE zprc_process_name VALUE 'ZPRC_AUTH_TEST_B'.

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

    METHODS _restrict
      IMPORTING i_activity TYPE csequence.

    METHODS _process_names
      IMPORTING it_parameters    TYPE if_apj_rt_exec_object=>tt_templ_val
      RETURNING VALUE(r_names)   TYPE string_table.
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

    DATA lt_process_names TYPE STANDARD TABLE OF zi_prc_processnamevh WITH EMPTY KEY.
    lt_process_names = VALUE #( ( ProcessName = c_allowed ) ( ProcessName = c_not_allowed ) ).
    sql_environment->insert_test_data( lt_process_names ).

    cut = NEW #( ).
  ENDMETHOD.

  METHOD teardown.
    cl_aunit_authority_check=>get_controller( )->reset( ).
  ENDMETHOD.

  METHOD _restrict.
    DATA(authorization) = VALUE cl_aunit_auth_check_types_def=>authorization(
        ( fieldname = 'ZPRCNAME' fieldvalues = VALUE #( ( lower_value = c_allowed ) ) )
        ( fieldname = 'ACTVT'    fieldvalues = VALUE #( ( lower_value = i_activity ) ) ) ).

    DATA(auth_objset) = cl_aunit_authority_check=>create_auth_object_set(
        VALUE #( ( role_authorizations = VALUE #( ( object         = 'ZPRC_PROC'
                                                    authorizations = VALUE #( ( authorization ) ) ) )
                   users               = VALUE #( ( sy-uname ) ) ) ) ).

    TRY.
        cl_aunit_authority_check=>get_controller( )->restrict_authorizations_to( auth_objset ).
      CATCH cx_abap_auth_check_exception INTO DATA(error).
        cl_abap_unit_assert=>fail( msg = |Restricting authorizations failed: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD _process_names.
    r_names = VALUE #( FOR p IN it_parameters WHERE ( selname = zcl_prc_retry_job=>c_process_name )
                       ( CONV string( p-low ) ) ).
  ENDMETHOD.

  METHOD only_authorized_kept.
    _restrict( '16' ).

    DATA(lt_result) = cut->_restrict_to_authorized(
        VALUE #( ( selname = zcl_prc_retry_job=>c_process_name kind = 'S' sign = 'I' option = 'CP' low = 'ZPRC_AUTH_TEST*' ) ) ).

    cl_abap_unit_assert=>assert_equals( act = _process_names( lt_result )
                                        exp = VALUE string_table( ( CONV #( c_allowed ) ) )
                                        msg = 'Only the authorized process expected' ).
  ENDMETHOD.

  METHOD empty_selection_means_all.
    " No S_PROC means all processes: the result must be restricted to the authorized ones
    _restrict( '16' ).

    DATA(lt_result) = cut->_restrict_to_authorized( VALUE #( ) ).

    cl_abap_unit_assert=>assert_equals( act = _process_names( lt_result )
                                        exp = VALUE string_table( ( CONV #( c_allowed ) ) )
                                        msg = 'Empty S_PROC must be restricted to the authorized process' ).
  ENDMETHOD.

  METHOD none_authorized_empty.
    " Display (03) does not allow resume (16): nothing to process
    _restrict( '03' ).

    DATA(lt_result) = cut->_restrict_to_authorized(
        VALUE #( ( selname = zcl_prc_retry_job=>s_uuid kind = 'S' sign = 'I' option = 'EQ' low = 'ANY' ) ) ).

    cl_abap_unit_assert=>assert_initial( act = lt_result
                                         msg = 'No parameters expected: an empty S_PROC would mean all processes' ).
  ENDMETHOD.

  METHOD other_parameters_kept.
    _restrict( '16' ).

    DATA(lt_result) = cut->_restrict_to_authorized(
        VALUE #( ( selname = zcl_prc_retry_job=>s_uuid         kind = 'S' sign = 'I' option = 'EQ' low = 'ANY' )
                 ( selname = zcl_prc_retry_job=>p_ignore_restart kind = 'P' sign = 'I' option = 'EQ' low = 'X' ) ) ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( lt_result[ selname = zcl_prc_retry_job=>s_uuid low = 'ANY' ] ) )
        msg = 'S_UUID must be kept' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( lt_result[ selname = zcl_prc_retry_job=>p_ignore_restart low = 'X' ] ) )
        msg = 'P_IGNR must be kept' ).
  ENDMETHOD.
ENDCLASS.
