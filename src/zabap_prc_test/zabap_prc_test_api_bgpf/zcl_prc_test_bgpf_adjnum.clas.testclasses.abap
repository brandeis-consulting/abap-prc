CLASS ltc_adjust_numbers_bgpf DEFINITION FINAL
  FOR TESTING RISK LEVEL harmless DURATION MEDIUM.

  PRIVATE SECTION.
    TYPES ty_id     TYPE zr_prc_test_bgpf-ID.
    TYPES ty_ext_id TYPE zr_prc_processedobject-ExternalProcessedObjectID.

    CONSTANTS c_max_wait_cycles TYPE i VALUE 20.

    DATA mt_created_ids TYPE STANDARD TABLE OF ty_id WITH EMPTY KEY.

    METHODS teardown.

    METHODS instance_processed_via_bgpf FOR TESTING.
    METHODS create_instance RETURNING VALUE(r_id) TYPE ty_id.

    METHODS wait_for_finished
      IMPORTING i_ext_id       TYPE ty_ext_id
      RETURNING VALUE(r_state) TYPE zif_prc_process=>ty_state.
ENDCLASS.


CLASS ltc_control_bgpf_direct DEFINITION FINAL
  FOR TESTING RISK LEVEL harmless DURATION MEDIUM.

  PRIVATE SECTION.
    METHODS teardown.
    METHODS processed_via_bgpf_directly FOR TESTING.
ENDCLASS.


CLASS lcl_helper DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS wait_for_finished
      IMPORTING i_ext_id       TYPE zr_prc_processedobject-ExternalProcessedObjectID
                i_max_cycles   TYPE i
      RETURNING VALUE(r_state) TYPE zif_prc_process=>ty_state.

    CLASS-METHODS assert_performed_message
      IMPORTING i_ext_id TYPE zr_prc_processedobject-ExternalProcessedObjectID.

    CLASS-METHODS delete_processed_objects.
ENDCLASS.


CLASS lcl_helper IMPLEMENTATION.

  METHOD wait_for_finished.
    DO i_max_cycles TIMES.
      SELECT SINGLE State FROM zr_prc_processedobject
        WHERE ProcessName               = @zcl_prc_test_bgpf_proc=>co_process_name
          AND ExternalProcessedObjectID = @i_ext_id
        INTO @r_state.
      IF r_state = zif_prc_process=>co_finished.
        RETURN.
      ENDIF.
      WAIT UP TO '0.5' SECONDS.
    ENDDO.
  ENDMETHOD.

  METHOD assert_performed_message.
    SELECT SINGLE UUID FROM zr_prc_processedobject
      WHERE ProcessName               = @zcl_prc_test_bgpf_proc=>co_process_name
        AND ExternalProcessedObjectID = @i_ext_id
      INTO @DATA(lv_uuid).

    SELECT COUNT( * ) FROM zr_prc_processedmessage
      WHERE ProcessedObjectUUID = @lv_uuid
        AND MessageClass        = 'ZPRC_TEST_BGPF'
        AND MessageNumber       = '001'
      INTO @DATA(lv_count).

    cl_abap_unit_assert=>assert_differs( act = lv_count
                                         exp = 0
                                         msg = |Nachricht ZPRC_TEST_BGPF/001 (performed) fehlt fuer { i_ext_id }| ).
  ENDMETHOD.

  METHOD delete_processed_objects.
    SELECT UUID FROM zr_prc_processedobject
      WHERE ProcessName = @zcl_prc_test_bgpf_proc=>co_process_name
      INTO TABLE @DATA(lt_existing).
    CHECK lt_existing IS NOT INITIAL.

    MODIFY ENTITIES OF zr_prc_processedobject
           ENTITY ProcessedObject
           DELETE FROM VALUE #( FOR k IN lt_existing ( %key-uuid = k-uuid ) ).
    COMMIT ENTITIES.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_adjust_numbers_bgpf IMPLEMENTATION.

  METHOD instance_processed_via_bgpf.
    DATA(lv_id) = create_instance( ).
    cl_abap_unit_assert=>assert_not_initial( act = lv_id
                                             msg = 'Keine finale ID aus adjust_numbers erhalten' ).
    SELECT SINGLE @abap_true FROM zr_prc_test_bgpf WHERE ID = @lv_id INTO @DATA(lv_exists).
    cl_abap_unit_assert=>assert_true( act = lv_exists
                                      msg = |BO-Instanz { lv_id } wurde nicht gespeichert| ).

    DATA(lv_ext_id) = CONV ty_ext_id( lv_id ).

    DATA(lv_state) = wait_for_finished( lv_ext_id ).

    cl_abap_unit_assert=>assert_equals( act = lv_state
                                        exp = zif_prc_process=>co_finished
                                        msg = |Processed Object { lv_ext_id } nicht FINISHED (Status: { lv_state })| ).

    lcl_helper=>assert_performed_message( lv_ext_id ).
  ENDMETHOD.

  METHOD create_instance.
    MODIFY ENTITIES OF zr_prc_test_bgpf
           ENTITY TestBgpf
           CREATE FROM VALUE #( ( %cid = 'NEW_1' ) )
           MAPPED DATA(ls_mapped)
           FAILED DATA(ls_failed)
           REPORTED DATA(ls_reported) ##NEEDED.

    cl_abap_unit_assert=>assert_initial( act = ls_failed
                                         msg = 'CREATE fehlgeschlagen' ).

    DATA(lv_pid) = ls_mapped-testbgpf[ 1 ]-%pid.
    DATA ls_final_key TYPE STRUCTURE FOR KEY OF zr_prc_test_bgpf.

    COMMIT ENTITIES BEGIN
           RESPONSE OF zr_prc_test_bgpf
           FAILED DATA(ls_commit_failed)
           REPORTED DATA(ls_commit_reported) ##NEEDED.

      CONVERT KEY OF zr_prc_test_bgpf
              FROM lv_pid
              TO ls_final_key.

    COMMIT ENTITIES END.

    cl_abap_unit_assert=>assert_initial( act = ls_commit_failed
                                         msg = 'COMMIT ENTITIES fehlgeschlagen' ).

    r_id = ls_final_key-ID.
    INSERT r_id INTO TABLE mt_created_ids.
  ENDMETHOD.

  METHOD wait_for_finished.
    r_state = lcl_helper=>wait_for_finished( i_ext_id     = i_ext_id
                                             i_max_cycles = c_max_wait_cycles ).
  ENDMETHOD.

  METHOD teardown.
    IF mt_created_ids IS NOT INITIAL.
      MODIFY ENTITIES OF zr_prc_test_bgpf
             ENTITY TestBgpf
             DELETE FROM VALUE #( FOR lv_id IN mt_created_ids ( ID = lv_id ) ).
      COMMIT ENTITIES.
      CLEAR mt_created_ids.
    ENDIF.

    lcl_helper=>delete_processed_objects( ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_control_bgpf_direct IMPLEMENTATION.

  METHOD processed_via_bgpf_directly.
    GET TIME STAMP FIELD DATA(lv_ts).
    DATA(lv_ext_id) = CONV zr_prc_processedobject-ExternalProcessedObjectID( |CTRL{ lv_ts }| ).

    zcl_prc_processing_api=>get_instance( )->create_processed_objects(
        i_create_processed_objects = VALUE #( ( processName      = zcl_prc_test_bgpf_proc=>co_process_name
                                                factoryClassName = zcl_prc_test_bgpf_proc=>co_class_name
                                                processedObject  = lv_ext_id ) )
        i_perform_commit           = abap_false
        i_trigger_processing       = zcl_prc_processing_api=>execution_mode-bgpf_execution ).
    COMMIT WORK AND WAIT.

    DATA(lv_state) = lcl_helper=>wait_for_finished( i_ext_id     = lv_ext_id
                                                    i_max_cycles = 20 ).

    cl_abap_unit_assert=>assert_equals( act = lv_state
                                        exp = zif_prc_process=>co_finished
                                        msg = |Kontrolle: { lv_ext_id } nicht FINISHED (Status: { lv_state })| ).

    lcl_helper=>assert_performed_message( lv_ext_id ).
  ENDMETHOD.

  METHOD teardown.
    lcl_helper=>delete_processed_objects( ).
  ENDMETHOD.

ENDCLASS.
