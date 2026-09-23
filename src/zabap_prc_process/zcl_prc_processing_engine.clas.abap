CLASS zcl_prc_processing_engine DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS get_instance RETURNING VALUE(r_instance) TYPE REF TO zcl_prc_processing_engine.

    METHODS execute_synchronously IMPORTING it_parameters TYPE if_apj_rt_exec_object=>tt_templ_val OPTIONAL.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-DATA g_instance TYPE REF TO zcl_prc_processing_engine.

    CLASS-METHODS create_process_factory IMPORTING iv_class_name     TYPE csequence
                                         RETURNING VALUE(ro_factory) TYPE REF TO zif_prc_process.

    CLASS-METHODS _ignore_retry_scheduling IMPORTING it_parameters   TYPE if_apj_dt_exec_object=>tt_templ_val
                                           RETURNING VALUE(r_result) TYPE abap_bool.

    TYPES: BEGIN OF ty_selected_state,
             uuid                        TYPE ZR_PRC_ProcessedObject-uuid,
             ExternalProcessedObjectID   TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectID,
             ExternalProcessedObjectUUID TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectUUID,
             runUUID                     TYPE ZR_PRC_ProcessedObject-RunUUID,
             ProcessName                 TYPE ZR_PRC_ProcessedObject-ProcessName,
             FactoryClassName            TYPE ZR_PRC_ProcessedObject-FactoryClassName,
             PayloadJson                 TYPE ZR_PRC_ProcessedObject-PayloadJson,
             state                       TYPE ZR_PRC_ProcessedObject-state,
             queueID                     TYPE ZR_PRC_ProcessedObject-QueueID,
             queuePosition               TYPE ZR_PRC_ProcessedObject-QueuePosition,
             RetryCount                  TYPE ZR_PRC_ProcessedObject-RetryCount,
             RetryDateTime               TYPE ZR_PRC_ProcessedObject-RetryDateTime,
             MessageSeverity             TYPE ZR_PRC_ProcessedStep-MessageSeverity,
             MessageText                 TYPE ZR_PRC_ProcessedStep-MessageText,
             MessageClass                TYPE ZR_PRC_ProcessedStep-MessageClass,
             MessageNumber               TYPE ZR_PRC_ProcessedStep-MessageNumber,
             MessageVariable1            TYPE ZR_PRC_ProcessedStep-MessageVariable1,
             MessageVariable2            TYPE ZR_PRC_ProcessedStep-MessageVariable2,
             MessageVariable3            TYPE ZR_PRC_ProcessedStep-MessageVariable3,
             MessageVariable4            TYPE ZR_PRC_ProcessedStep-MessageVariable4,
           END OF ty_selected_state,
           tt_selected_state TYPE STANDARD TABLE OF ty_selected_state WITH DEFAULT KEY.

    CLASS-METHODS _select_states IMPORTING i_parameters              TYPE if_apj_rt_exec_object=>tt_templ_val
                                           i_ignore_retry_scheduling TYPE abap_bool
                                 EXPORTING e_states                  TYPE tt_selected_state.

    CLASS-METHODS _finalize_and_commit IMPORTING i_message_handler TYPE REF TO zif_prc_message_handler
                                                 i_start_state     TYPE zif_prc_process=>ty_state
                                       CHANGING  c_state           TYPE ty_selected_state
                                       RAISING   cx_bali_runtime.

    CLASS-METHODS _update_processed_object IMPORTING i_start_state            TYPE zif_prc_process=>ty_state
                                                     i_state                  TYPE ty_selected_state
                                                     i_header_message_details TYPE zif_prc_message_handler=>ty_message_details
                                                     i_message_handler        TYPE REF TO zif_prc_message_handler.

    CLASS-METHODS _update_retry_data IMPORTING i_message_handler TYPE REF TO zif_prc_message_handler
                                     CHANGING  c_state           TYPE ty_selected_state.

    CLASS-METHODS _get_end_state IMPORTING i_proposed_end_state TYPE zif_prc_process=>ty_state
                                           i_state              TYPE ty_selected_state

                                 RETURNING VALUE(r_end_state)   TYPE zif_prc_process=>ty_state.

    CLASS-METHODS _update_run
      IMPORTING i_run_uuid TYPE sysuuid_x16.
ENDCLASS.



CLASS zcl_prc_processing_engine IMPLEMENTATION.

  METHOD create_process_factory.
    CREATE OBJECT ro_factory TYPE (iv_class_name).
  ENDMETHOD.

  METHOD execute_synchronously.
    TRY.
        DATA(ignore_retry_scheduling) = _ignore_retry_scheduling( it_parameters ).

        _select_states( EXPORTING i_parameters              = it_parameters
                                  i_ignore_retry_scheduling = ignore_retry_scheduling
                        IMPORTING e_states                  = DATA(states) ).

        DATA(lo_bali_log) = cl_bali_log=>create_with_header( cl_bali_header_setter=>create( object      = 'ZBALI_PRC'
                                                                                            subobject   = 'PRC_RETRY'
                                                                                            external_id = 'ABAP PRC Retry' ) ).
        LOOP AT states INTO DATA(ls_group)
             GROUP BY ( appName = ls_group-processName
                        queueID = ls_group-queueID )
             ASSIGNING FIELD-SYMBOL(<ls_group_key>).

          DATA(lv_queue_failed) = abap_false.
          DATA(lv_queue_failed_ID) = VALUE ty_selected_state-externalprocessedobjectid( ).

          LOOP AT GROUP <ls_group_key> ASSIGNING FIELD-SYMBOL(<fs_state>).
            IF ignore_retry_scheduling = abap_true.
              CLEAR: <fs_state>-RetryCount,
                     <fs_state>-RetryDateTime.
            ENDIF.

            DATA(lo_factory) = create_process_factory( <fs_state>-FactoryClassName ).
            DO.

              DATA(lo_message_handler) = zcl_prc_message_handler=>create_message_handler( lo_bali_log ).
              DATA(start_state) = CONV zif_prc_process=>ty_state( <fs_state>-State ).

              IF lv_queue_failed = abap_true.
                MESSAGE i001(zprc_process_message) WITH lv_queue_failed_id <fs_state>-queueID INTO DATA(lv_dummy) ##NEEDED.
                lo_message_handler->add_message_from_sy( ).
              ELSE.
                TRY.
                    DATA(lo_transition_handler) = lo_factory->get_transition_handler(
                                                      i_start_state      = start_state
                                                      i_processed_object = <fs_state>-ExternalProcessedObjectID ).
                    lo_transition_handler->initialize(
                        i_message_handler           = lo_message_handler
                        i_processed_object_ext_id   = <fs_state>-ExternalProcessedObjectID
                        i_processed_object_ext_uuid = <fs_state>-ExternalProcessedObjectUUID ).

                    DATA(proposed_end_state) = lo_transition_handler->perform_transition(
                                                 EXPORTING i_start_state  = start_state
                                                 CHANGING  c_payload_json = <fs_state>-payloadjson ).

                    <fs_state>-state = _get_end_state( i_proposed_end_state = proposed_end_state
                                                       i_state              = <fs_state> ).

                    DATA(failed) = abap_false.
                  CATCH zcx_prc_unit_of_work_failed.
                    ROLLBACK ENTITIES.
                    failed = abap_true.
                    IF <fs_state>-queueid IS NOT INITIAL.
                      lv_queue_failed = abap_true.
                      lv_queue_failed_ID = <fs_state>-externalprocessedobjectid.
                    ENDIF.
                ENDTRY.
              ENDIF.
              _finalize_and_commit( EXPORTING i_start_state     = start_state
                                              i_message_handler = lo_message_handler
                                    CHANGING  c_state           = <fs_state> ).

              IF <fs_state>-state = zif_prc_process=>co_finished OR failed = abap_true.
                _update_run( <fs_state>-runUUID ).
                EXIT.
              ENDIF.
            ENDDO.

          ENDLOOP.
        ENDLOOP.
      CATCH cx_bali_runtime INTO DATA(lx_bali_runtime).
        ASSERT lx_bali_runtime IS NOT BOUND.
    ENDTRY.
  ENDMETHOD.


  METHOD get_instance.
    IF g_instance IS NOT BOUND.
      g_instance = NEW #( ).
    ENDIF.
    r_instance = g_instance.
  ENDMETHOD.

  METHOD _finalize_and_commit.
    i_message_handler->finalize_and_persist_log( ).
    DATA(header_message) = i_message_handler->get_header( ).
    c_state-MessageSeverity = header_message-msgty.
    c_state-MessageText     = header_message-message_text.

    _update_retry_data( EXPORTING i_message_handler = i_message_handler
                        CHANGING  c_state           = c_state ).
    _update_processed_object( i_state           = c_state
                              i_start_state     = i_start_state
                              i_header_message_details = header_message
                              i_message_handler = i_message_handler ).

    " Call update task local
    COMMIT ENTITIES
        RESPONSES
        FAILED DATA(lt_failed)
        REPORTED DATA(lt_reported).
    ASSERT sy-subrc = 0.
  ENDMETHOD.


  METHOD _get_end_state.
    DATA(lo_factory) = create_process_factory( i_state-FactoryClassName ).
    DATA(transitions) = lo_factory->get_transitions( ).
    DATA lv_potential_state TYPE zif_prc_process=>ty_state.

    " check if target is unique, otherwise leave empty
    LOOP AT transitions INTO DATA(ls_potential_end_state) WHERE start_state = i_state-state.
      IF lv_potential_state IS NOT INITIAL.
        CLEAR lv_potential_state.
        EXIT.
      ENDIF.
      lv_potential_state = ls_potential_end_state-end_state.
    ENDLOOP.

    " if unique, then proposal expected to be empty or equal
    IF lv_potential_state IS INITIAL.
      ASSERT i_proposed_end_state IS NOT INITIAL.
      r_end_state = i_proposed_end_state.
    ELSE.
      ASSERT i_proposed_end_state IS INITIAL OR i_proposed_end_state = lv_potential_state.
      r_end_state = lv_potential_state.
    ENDIF.
  ENDMETHOD.


  METHOD _ignore_retry_scheduling.
    LOOP AT it_parameters TRANSPORTING NO FIELDS WHERE selname = zcl_prc_retry_job=>p_ignore_restart AND low = abap_true.
      RETURN abap_true.
    ENDLOOP.
    RETURN abap_false.
  ENDMETHOD.

  METHOD _select_states.
    DATA(lv_max_retry) = CONV int8( zif_prc_process=>co_max_retry ).
    FINAL(state_finished) = zif_prc_process=>co_finished.
    GET TIME STAMP FIELD DATA(lv_current_timestamp).
    IF i_ignore_retry_scheduling = abap_false.
      DATA(lv_retry_compare_timestamp) = lv_current_timestamp.
    ELSE.
      lv_retry_compare_timestamp = '20991010101010'.
      lv_max_retry += 1.
    ENDIF.

    DATA lt_selected_uuids TYPE RANGE OF ZR_PRC_ProcessedObject-uuid.
    lt_selected_uuids = VALUE #( FOR k IN i_parameters WHERE ( selname = zcl_prc_retry_job=>s_uuid )
                                 ( CORRESPONDING #( k ) ) ).

    DATA lt_selected_process_names TYPE RANGE OF zprc_process_name.
    lt_selected_process_names = VALUE #( FOR k IN i_parameters WHERE ( selname = zcl_prc_retry_job=>c_process_name )
                                 ( CORRESPONDING #( k ) ) ).

    SELECT FROM ZR_PRC_ProcessedObject AS ProcessedObject
      FIELDS uuid,
             ExternalProcessedObjectID,
             ExternalProcessedObjectUUID,
             runUUID,
             ProcessName,
             FactoryClassName,
             PayloadJson,
             state,
             QueueID,
             QueuePosition,
             RetryCount,
             RetryDateTime,
             \_LatestStep-MessageSeverity,
             \_LatestStep-MessageText,
             \_LatestStep-MessageClass,
             \_LatestStep-MessageNumber,
             \_LatestStep-MessageVariable1,
             \_LatestStep-MessageVariable2,
             \_LatestStep-MessageVariable3,
             \_LatestStep-MessageVariable4
      WHERE State <> @state_finished
        AND ( \_LatestStep-MessageSeverity <> 'E' OR RetryDateTime <= @lv_retry_compare_timestamp AND RetryCount < @lv_max_retry )
        AND DoNotProcessBefore  < @lv_current_timestamp
        AND uuid               IN @lt_selected_uuids
        AND ProcessName        IN @lt_selected_process_names
      ORDER BY ProcessName, QueueID, QueuePosition
      INTO TABLE @e_states
      PRIVILEGED ACCESS.
  ENDMETHOD.


  METHOD _update_processed_object.
    MODIFY ENTITIES OF ZR_PRC_ProcessedObject PRIVILEGED
           ENTITY ProcessedObject
           CREATE BY \_ProcessedStep FIELDS ( StartState EndState MessageText MessageClass MessageNumber MessageSeverity MessageVariable1 MessageVariable2 MessageVariable3 MessageVariable4 )
           WITH VALUE #( ( uuid    = i_state-uuid
                           %target = VALUE #( ( %cid             = 'CID_STEP'
                                                StartState       = i_start_state
                                                EndState         = i_state-State
                                                MessageText      = i_header_message_details-message_text
                                                MessageClass     = i_header_message_details-msgid
                                                MessageNumber    = i_header_message_details-msgno
                                                MessageSeverity  = i_header_message_details-msgty
                                                MessageVariable1 = i_header_message_details-msgv1
                                                MessageVariable2 = i_header_message_details-msgv2
                                                MessageVariable3 = i_header_message_details-msgv3
                                                MessageVariable4 = i_header_message_details-msgv4 ) ) ) )
           REPORTED DATA(lt_reported)
           FAILED DATA(lt_failed)
           MAPPED DATA(lt_mapped).
    ASSERT lt_failed IS INITIAL AND lt_reported IS INITIAL.

    DATA(lt_all_messages) = i_message_handler->get_messages( ).
    MODIFY ENTITIES OF ZR_PRC_ProcessedObject PRIVILEGED
           ENTITY ProcessedStep
           CREATE BY \_ProcessedMessage FIELDS ( MessageText MessageClass MessageNumber MessageSeverity MessageVariable1 MessageVariable2 MessageVariable3 MessageVariable4 )
           AUTO FILL CID
           WITH VALUE #( ( StepUUID = lt_mapped-processedstep[ 1 ]-StepUUID
                           %target  = VALUE #( FOR k IN lt_all_messages
                                               ( MessageText      = k-message_text
                                                MessageClass     = k-msgid
                                                MessageNumber    = k-msgno
                                                MessageSeverity  = k-msgty
                                                MessageVariable1 = k-msgv1
                                                MessageVariable2 = k-msgv2
                                                MessageVariable3 = k-msgv3
                                                MessageVariable4 = k-msgv4 ) ) ) )
           REPORTED DATA(lt_reported_message)
           FAILED DATA(lt_failed_message)
           MAPPED DATA(lt_mapped_message).
    ASSERT lt_failed IS INITIAL AND lt_reported IS INITIAL.

    MODIFY ENTITIES OF ZR_PRC_ProcessedObject PRIVILEGED
           ENTITY ProcessedObject
           UPDATE FIELDS ( RetryCount RetryDateTime State ExternalProcessedObjectID LatestStepUUID )
           WITH VALUE #( ( %key-uuid                 = i_state-uuid
                           LatestStepUUID            = lt_mapped-processedstep[ 1 ]-StepUUID
                           RetryCount                = i_state-RetryCount
                           RetryDateTime             = i_state-RetryDateTime
                           State                     = i_state-State
                           ExternalProcessedObjectID = i_state-ExternalProcessedObjectID
                            ) )
           REPORTED lt_reported
           FAILED lt_failed.
    ASSERT lt_failed IS INITIAL AND lt_reported IS INITIAL.
  ENDMETHOD.


  METHOD _update_retry_data.
    IF i_message_handler->has_errors( ) = abap_true.
      GET TIME STAMP FIELD DATA(lv_timestamp).
      CASE c_state-retryCount.
        WHEN 0.
          c_state-retryCount    = 1.
          c_state-retryDatetime = cl_abap_tstmp=>add( tstmp = lv_timestamp
                                                      secs  = 5 * 60 ).
        WHEN 1.
          c_state-retryCount    = 2.
          c_state-retryDatetime = cl_abap_tstmp=>add( tstmp = lv_timestamp
                                                      secs  = 55 * 60 ).
        WHEN 2.
          c_state-retryCount    = 3.
          c_state-retryDatetime = cl_abap_tstmp=>add( tstmp = lv_timestamp
                                                      secs  = 23 * 60 * 60 ).
        WHEN 3.
          c_state-retryCount    = 4.
          c_state-retryDatetime = cl_abap_tstmp=>add( tstmp = lv_timestamp
                                                      secs  = 6 * 60 * 60 ).
        WHEN 4.
          c_state-retryCount = zif_prc_process=>co_max_retry.
          CLEAR c_state-retryDatetime.
      ENDCASE.
    ELSE.
      CLEAR c_state-retryCount.
      CLEAR c_state-retryDatetime.
    ENDIF.
  ENDMETHOD.

  METHOD _update_run.
    IF i_run_uuid IS NOT INITIAL.
      MODIFY ENTITIES OF ZR_PRC_Run PRIVILEGED
             ENTITY Run
             EXECUTE triggerChangedEvent FROM VALUE #( ( %key-uuid = i_run_uuid ) ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
