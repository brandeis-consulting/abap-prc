CLASS ltc_db_writer DEFINITION DEFERRED.
CLASS ltc_remaining_steps DEFINITION DEFERRED.
CLASS zcl_prc_db_writer DEFINITION LOCAL FRIENDS ltc_db_writer ltc_remaining_steps.

"! Black box tests of the write API against database test doubles
CLASS ltc_db_writer DEFINITION FINAL FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    CONSTANTS: o1 TYPE sysuuid_x16 VALUE '00000000000000000000000000000001',
               s1 TYPE sysuuid_x16 VALUE '00000000000000000000000000000011',
               s2 TYPE sysuuid_x16 VALUE '00000000000000000000000000000012',
               s3 TYPE sysuuid_x16 VALUE '00000000000000000000000000000013',
               m1 TYPE sysuuid_x16 VALUE '00000000000000000000000000000021'.
    " START -> A -> B1|B2 -> FINISHED: longest path 3
    CONSTANTS branching TYPE zprc_process_impl_class VALUE 'LTD_BRANCHING'.
    " START -> A -> START (loop) | FINISHED: longest path without loop 2
    CONSTANTS looping   TYPE zprc_process_impl_class VALUE 'LTD_LOOPING'.

    TYPES: BEGIN OF ty_code,
             msgty                 TYPE zprc_message_severity,
             message_severity_code TYPE zprc_message_severity_code,
           END OF ty_code,
           tt_code TYPE STANDARD TABLE OF ty_code WITH EMPTY KEY.

    CLASS-DATA environment TYPE REF TO if_osql_test_environment.
    DATA cut TYPE REF TO zif_prc_db_writer.

    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup.

    METHODS create_fills_admin_fields   FOR TESTING RAISING cx_static_check.
    METHODS severity_codes              FOR TESTING RAISING cx_static_check.
    METHODS step_total_after_first_step FOR TESTING RAISING cx_static_check.
    METHODS step_total_when_finished    FOR TESTING RAISING cx_static_check.
    METHODS step_total_with_loop        FOR TESTING RAISING cx_static_check.
    METHODS update_writes_full_row      FOR TESTING RAISING cx_static_check.
    METHODS delete_takes_children_along FOR TESTING RAISING cx_static_check.

    METHODS given_object IMPORTING i_state   TYPE zprc_state        DEFAULT 'START'
                                   i_payload TYPE zprc_payload_json OPTIONAL.
    METHODS read_object  RETURNING VALUE(r_object) TYPE zprc_proc_object.
ENDCLASS.


CLASS ltc_db_writer IMPLEMENTATION.

  METHOD class_setup.
    environment = cl_osql_test_environment=>create(
                      i_dependency_list = VALUE #( ( 'ZPRC_PROC_OBJECT' ) ( 'ZPRC_PROC_STEP' ) ( 'ZPRC_PROC_MSG' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    environment->destroy( ).
  ENDMETHOD.

  METHOD setup.
    environment->clear_doubles( ).
    DATA(writer) = NEW zcl_prc_db_writer( ).
    writer->mt_processes = VALUE #(
        ( class_name  = branching
          transitions = VALUE #( ( start_state = 'START' end_state = 'A' )
                                 ( start_state = 'A'     end_state = 'B1' )
                                 ( start_state = 'A'     end_state = 'B2' )
                                 ( start_state = 'B1'    end_state = 'FINISHED' )
                                 ( start_state = 'B2'    end_state = 'FINISHED' ) ) )
        ( class_name  = looping
          transitions = VALUE #( ( start_state = 'START' end_state = 'A' )
                                 ( start_state = 'A'     end_state = 'START' )
                                 ( start_state = 'A'     end_state = 'FINISHED' ) ) ) ).
    cut = writer.
  ENDMETHOD.

  METHOD given_object.
    DATA objects TYPE STANDARD TABLE OF zprc_proc_object WITH EMPTY KEY.
    objects = VALUE #( ( uuid = o1 state = i_state factory_class_name = branching payload_json = i_payload ) ).
    environment->insert_test_data( objects ).
  ENDMETHOD.

  METHOD read_object.
    SELECT SINGLE FROM zprc_proc_object FIELDS * WHERE uuid = @o1 INTO @r_object.
  ENDMETHOD.

  METHOD create_fills_admin_fields.
    cut->save( i_create = VALUE #( processedobject = VALUE #( ( UUID             = o1
                                                                ProcessName      = 'P'
                                                                FactoryClassName = branching
                                                                State            = 'START' ) ) ) ).

    DATA(object) = read_object( ).
    cl_abap_unit_assert=>assert_not_initial( object-created_at ).
    cl_abap_unit_assert=>assert_equals( exp = cl_abap_context_info=>get_user_technical_name( ) act = object-created_by ).
    cl_abap_unit_assert=>assert_equals( exp = object-created_at act = object-local_last_changed_at ).
    cl_abap_unit_assert=>assert_equals( exp = 3 act = object-step_total ).
  ENDMETHOD.

  METHOD severity_codes.
    " Severity codes are derived for messages (the step header is a message since Nr. 15 B)
    given_object( ).
    cut->save( i_create = VALUE #( processedmessage = VALUE #(
        ( UUID = '000000000000000000000000000000E1' ProcessedStepUUID = s1 ProcessedObjectUUID = o1 MessageSeverity = 'E' )
        ( UUID = '000000000000000000000000000000E2' ProcessedStepUUID = s1 ProcessedObjectUUID = o1 MessageSeverity = 'W' )
        ( UUID = '000000000000000000000000000000E3' ProcessedStepUUID = s1 ProcessedObjectUUID = o1 MessageSeverity = 'S' )
        ( UUID = '000000000000000000000000000000E4' ProcessedStepUUID = s1 ProcessedObjectUUID = o1 MessageSeverity = 'I' )
        ( UUID = '000000000000000000000000000000E5' ProcessedStepUUID = s1 ProcessedObjectUUID = o1 MessageSeverity = 'A' ) ) ) ).

    DATA codes TYPE tt_code.
    SELECT FROM zprc_proc_msg FIELDS msgty, message_severity_code ORDER BY msgty INTO TABLE @codes.
    cl_abap_unit_assert=>assert_equals( exp = VALUE tt_code( ( msgty = 'A' message_severity_code = 1 )
                                                             ( msgty = 'E' message_severity_code = 1 )
                                                             ( msgty = 'I' message_severity_code = 5 )
                                                             ( msgty = 'S' message_severity_code = 3 )
                                                             ( msgty = 'W' message_severity_code = 2 ) )
                                        act = codes ).
  ENDMETHOD.

  METHOD step_total_after_first_step.
    given_object( ).
    cut->save(
        i_create = VALUE #( processedstep   = VALUE #( ( StepUUID = s1 ProcessedObjectUUID = o1
                                                         StartState = 'START' EndState = 'A' ) ) )
        i_update = VALUE #( processedobject = VALUE #( ( UUID = o1 FactoryClassName = branching State = 'A' ) ) ) ).

    DATA(object) = read_object( ).
    cl_abap_unit_assert=>assert_equals( exp = s1 act = object-latest_step_uuid ).
    cl_abap_unit_assert=>assert_equals( exp = 3  act = object-step_total ).  " 1 done + 2 remaining
  ENDMETHOD.

  METHOD step_total_when_finished.
    given_object( i_state = 'B1' ).
    DATA steps TYPE STANDARD TABLE OF zprc_proc_step WITH EMPTY KEY.
    steps = VALUE #( ( step_uuid = s1 processed_object_uuid = o1 start_state = 'START' end_state = 'A' )
                     ( step_uuid = s2 processed_object_uuid = o1 start_state = 'A'     end_state = 'B1' ) ).
    environment->insert_test_data( steps ).

    cut->save(
        i_create = VALUE #( processedstep   = VALUE #( ( StepUUID = s3 ProcessedObjectUUID = o1
                                                         StartState = 'B1' EndState = 'FINISHED' ) ) )
        i_update = VALUE #( processedobject = VALUE #( ( UUID = o1 FactoryClassName = branching State = 'FINISHED' ) ) ) ).

    cl_abap_unit_assert=>assert_equals( exp = 3 act = read_object( )-step_total ).
  ENDMETHOD.

  METHOD step_total_with_loop.
    cut->save( i_create = VALUE #( processedobject = VALUE #( ( UUID             = o1
                                                                ProcessName      = 'P'
                                                                FactoryClassName = looping
                                                                State            = 'START' ) ) ) ).

    cl_abap_unit_assert=>assert_equals( exp = 2 act = read_object( )-step_total ).
  ENDMETHOD.

  METHOD update_writes_full_row.
    given_object( i_payload = '{"old":true}' ).
    cut->save( i_update = VALUE #( processedobject = VALUE #( ( UUID             = o1
                                                                FactoryClassName = branching
                                                                State            = 'A'
                                                                PayloadJson      = '{"new":true}' ) ) ) ).

    DATA(object) = read_object( ).
    cl_abap_unit_assert=>assert_equals( exp = 'A'            act = object-state ).
    cl_abap_unit_assert=>assert_equals( exp = '{"new":true}' act = object-payload_json ).
  ENDMETHOD.

  METHOD delete_takes_children_along.
    given_object( ).
    cut->save( i_create = VALUE #(
        processedstep    = VALUE #( ( StepUUID = s1 ProcessedObjectUUID = o1 ) )
        processedmessage = VALUE #( ( UUID = m1 ProcessedStepUUID = s1 ProcessedObjectUUID = o1 ) ) ) ).

    cut->save( i_delete = VALUE #( processedobject = VALUE #( ( UUID = o1 ) ) ) ).

    SELECT COUNT(*) FROM zprc_proc_object INTO @DATA(objects).
    SELECT COUNT(*) FROM zprc_proc_step   INTO @DATA(steps).
    SELECT COUNT(*) FROM zprc_proc_msg    INTO @DATA(messages).
    cl_abap_unit_assert=>assert_equals( exp = 0 act = objects + steps + messages ).
  ENDMETHOD.

ENDCLASS.


"! Longest path without loops from a state to FINISHED, counted in transitions
CLASS ltc_remaining_steps DEFINITION FINAL FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_prc_db_writer.
    METHODS setup.
    METHODS finished_needs_none      FOR TESTING.
    METHODS linear                   FOR TESTING.
    METHODS shortcut_to_finished     FOR TESTING.
    METHODS fork_takes_longer_branch FOR TESTING.
    METHODS fork_and_join            FOR TESTING.
    METHODS short_branch_taken       FOR TESTING.
    METHODS loop_back_is_ignored     FOR TESTING.
    METHODS self_loop_is_ignored     FOR TESTING.
    METHODS dead_end                 FOR TESTING.
ENDCLASS.


CLASS ltc_remaining_steps IMPLEMENTATION.

  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD finished_needs_none.
    cl_abap_unit_assert=>assert_equals( exp = 0 act = cut->get_remaining_steps(
        i_state       = 'FINISHED'
        i_transitions = VALUE #( ( start_state = 'START' end_state = 'FINISHED' ) ) ) ).
  ENDMETHOD.

  METHOD linear.
    " START -> A -> FINISHED
    cl_abap_unit_assert=>assert_equals( exp = 2 act = cut->get_remaining_steps(
        i_state       = 'START'
        i_transitions = VALUE #( ( start_state = 'START' end_state = 'A' )
                                 ( start_state = 'A'     end_state = 'FINISHED' ) ) ) ).
  ENDMETHOD.

  METHOD shortcut_to_finished.
    " START -> A -> FINISHED  |  START -> FINISHED
    cl_abap_unit_assert=>assert_equals( exp = 2 act = cut->get_remaining_steps(
        i_state       = 'START'
        i_transitions = VALUE #( ( start_state = 'START' end_state = 'A' )
                                 ( start_state = 'A'     end_state = 'FINISHED' )
                                 ( start_state = 'START' end_state = 'FINISHED' ) ) ) ).
  ENDMETHOD.

  METHOD fork_takes_longer_branch.
    " START -> A -> FINISHED  |  START -> B1 -> B2 -> FINISHED
    cl_abap_unit_assert=>assert_equals( exp = 3 act = cut->get_remaining_steps(
        i_state       = 'START'
        i_transitions = VALUE #( ( start_state = 'START' end_state = 'A' )
                                 ( start_state = 'A'     end_state = 'FINISHED' )
                                 ( start_state = 'START' end_state = 'B1' )
                                 ( start_state = 'B1'    end_state = 'B2' )
                                 ( start_state = 'B2'    end_state = 'FINISHED' ) ) ) ).
  ENDMETHOD.

  METHOD fork_and_join.
    " START -> A -> C  |  START -> B1 -> B2 -> C;  C -> FINISHED
    cl_abap_unit_assert=>assert_equals( exp = 4 act = cut->get_remaining_steps(
        i_state       = 'START'
        i_transitions = VALUE #( ( start_state = 'START' end_state = 'A' )
                                 ( start_state = 'A'     end_state = 'C' )
                                 ( start_state = 'START' end_state = 'B1' )
                                 ( start_state = 'B1'    end_state = 'B2' )
                                 ( start_state = 'B2'    end_state = 'C' )
                                 ( start_state = 'C'     end_state = 'FINISHED' ) ) ) ).
  ENDMETHOD.

  METHOD short_branch_taken.
    " Same graph as fork_and_join, but the short branch A is already taken
    cl_abap_unit_assert=>assert_equals( exp = 2 act = cut->get_remaining_steps(
        i_state       = 'A'
        i_transitions = VALUE #( ( start_state = 'START' end_state = 'A' )
                                 ( start_state = 'A'     end_state = 'C' )
                                 ( start_state = 'START' end_state = 'B1' )
                                 ( start_state = 'B1'    end_state = 'B2' )
                                 ( start_state = 'B2'    end_state = 'C' )
                                 ( start_state = 'C'     end_state = 'FINISHED' ) ) ) ).
  ENDMETHOD.

  METHOD loop_back_is_ignored.
    " START -> A -> B -> FINISHED, B -> A loops back
    cl_abap_unit_assert=>assert_equals( exp = 3 act = cut->get_remaining_steps(
        i_state       = 'START'
        i_transitions = VALUE #( ( start_state = 'START' end_state = 'A' )
                                 ( start_state = 'A'     end_state = 'B' )
                                 ( start_state = 'B'     end_state = 'A' )
                                 ( start_state = 'B'     end_state = 'FINISHED' ) ) ) ).
  ENDMETHOD.

  METHOD self_loop_is_ignored.
    " START -> A -> FINISHED, A -> A
    cl_abap_unit_assert=>assert_equals( exp = 2 act = cut->get_remaining_steps(
        i_state       = 'START'
        i_transitions = VALUE #( ( start_state = 'START' end_state = 'A' )
                                 ( start_state = 'A'     end_state = 'A' )
                                 ( start_state = 'A'     end_state = 'FINISHED' ) ) ) ).
  ENDMETHOD.

  METHOD dead_end.
    " START -> A, A has no way out
    cl_abap_unit_assert=>assert_equals( exp = 1 act = cut->get_remaining_steps(
        i_state       = 'START'
        i_transitions = VALUE #( ( start_state = 'START' end_state = 'A' ) ) ) ).
  ENDMETHOD.

ENDCLASS.
