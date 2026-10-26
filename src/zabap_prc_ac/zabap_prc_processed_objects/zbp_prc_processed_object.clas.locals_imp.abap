CLASS lhc_ProcessedObject DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PUBLIC SECTION.
    CLASS-DATA gt_processed_objects  TYPE STANDARD TABLE OF ZR_PRC_ProcessedObjectTP-uuid WITH DEFAULT KEY.
    "! Objects whose changed event is raised in the next save, without a change of their own
    CLASS-DATA gt_trigger_events_for TYPE STANDARD TABLE OF ZR_PRC_ProcessedObjectTP-uuid WITH DEFAULT KEY.

  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION IMPORTING keys REQUEST requested_authorizations FOR ProcessedObject RESULT result.
    METHODS lock FOR LOCK IMPORTING keys FOR LOCK ProcessedObject.
    METHODS precheck_createprocessedobject FOR PRECHECK IMPORTING keys FOR ACTION ProcessedObject~createProcessedObject.
    METHODS createProcessedObject FOR MODIFY IMPORTING keys FOR ACTION ProcessedObject~createProcessedObject.
    METHODS resumeProcessing FOR MODIFY IMPORTING keys FOR ACTION ProcessedObject~resumeProcessing." RESULT result.
    METHODS triggerChangedEvent FOR MODIFY IMPORTING keys FOR ACTION ProcessedObject~triggerChangedEvent.
    METHODS get_instance_features FOR INSTANCE FEATURES IMPORTING keys REQUEST requested_features FOR ProcessedObject RESULT result.
ENDCLASS.


CLASS lhc_ProcessedObject IMPLEMENTATION.
  METHOD get_instance_authorizations.
    READ ENTITIES OF ZR_PRC_ProcessedObjectTP IN LOCAL MODE
         ENTITY ProcessedObject
         FIELDS ( ProcessName )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_processed_objects)
         FAILED failed.

    LOOP AT keys INTO DATA(key).
      ASSIGN lt_processed_objects[ KEY id
                                   uuid = key-uuid ] TO FIELD-SYMBOL(<ls_po>).
      IF sy-subrc <> 0.
        " Instance not readable: deny all requested operations
        APPEND VALUE #( %tky                        = key-%tky
                        %update                     = if_abap_behv=>auth-unauthorized
                        %delete                     = if_abap_behv=>auth-unauthorized
                        %action-resumeProcessing    = if_abap_behv=>auth-unauthorized
                        %action-triggerChangedEvent = if_abap_behv=>auth-unauthorized )
               TO result.
        CONTINUE.
      ENDIF.

      " Only requested operations are checked, the others stay initial
      APPEND VALUE #(
          %tky                        = key-%tky
          %update                     = COND #( WHEN requested_authorizations-%update = if_abap_behv=>mk-on
                                                THEN zcl_prc_auth_process=>get_behv_authorization(
                                                         i_process_name = <ls_po>-ProcessName
                                                         i_activity     = zcl_prc_auth_process=>co_activity-change ) )
          %delete                     = COND #( WHEN requested_authorizations-%delete = if_abap_behv=>mk-on
                                                THEN zcl_prc_auth_process=>get_behv_authorization(
                                                         i_process_name = <ls_po>-ProcessName
                                                         i_activity     = zcl_prc_auth_process=>co_activity-delete ) )
          %action-resumeProcessing    = COND #( WHEN requested_authorizations-%action-resumeProcessing = if_abap_behv=>mk-on
                                                THEN zcl_prc_auth_process=>get_behv_authorization(
                                                         i_process_name = <ls_po>-ProcessName
                                                         i_activity     = zcl_prc_auth_process=>co_activity-execute ) )
          %action-triggerChangedEvent = COND #( WHEN requested_authorizations-%action-triggerChangedEvent = if_abap_behv=>mk-on
                                                THEN zcl_prc_auth_process=>get_behv_authorization(
                                                         i_process_name = <ls_po>-ProcessName
                                                         i_activity     = zcl_prc_auth_process=>co_activity-change ) ) )
             TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD lock.
    " Same lock as the processing engine, so BO and engine collide
    LOOP AT keys INTO DATA(key).
      TRY.
          IF zcl_prc_object_lock=>enqueue( key-UUID ) = abap_true.
            CONTINUE.
          ENDIF.
          DATA(message) = new_message( id       = 'ZPRC_PROCESS_MESSAGE'
                                       number   = '009'
                                       severity = if_abap_behv_message=>severity-error ).
        CATCH cx_abap_lock_failure.
          message = new_message( id       = 'ZPRC_PROCESS_MESSAGE'
                                 number   = '010'
                                 severity = if_abap_behv_message=>severity-error
                                 v1       = zcl_prc_object_lock=>co_lock_object ).
      ENDTRY.

      " RAP accepts only LOCKED as cause of a failed lock
      APPEND VALUE #( UUID        = key-UUID
                      %fail-cause = if_abap_behv=>cause-locked ) TO failed-processedobject.
      APPEND VALUE #( UUID = key-UUID
                      %msg = message ) TO reported-processedobject.
    ENDLOOP.
  ENDMETHOD.

  METHOD precheck_createprocessedobject.
    " Everybody may call the action, the process name decides (ZPRC_PROC, activity 01).
    " Privileged callers pass, because ZPRC_PROC is in the authorization context.
    LOOP AT keys INTO DATA(key).
      IF zcl_prc_auth_process=>is_authorized( i_process_name = key-%param-processName
                                              i_activity     = zcl_prc_auth_process=>co_activity-create ) = abap_false.
        APPEND VALUE #( %cid = key-%cid ) TO failed-processedobject.
        APPEND VALUE #( %cid = key-%cid
                        %msg = new_message( id       = 'ZPRC_PROCESS_MESSAGE'
                                            number   = '004'
                                            severity = if_abap_behv_message=>severity-error
                                            v1       = key-%param-processName ) )
               TO reported-processedobject.
        CONTINUE.
      ENDIF.

      " The process class must be loadable, the save phase must not fail on it.
      " Via the loader: a syntax error is reported here instead of a short dump of the caller.
      zcl_prc_process_loader=>get_process( EXPORTING i_class_name = key-%param-factoryClassName
                                           IMPORTING e_error      = DATA(ls_error) ).
      IF ls_error IS NOT INITIAL.
        APPEND VALUE #( %cid = key-%cid ) TO failed-processedobject.
        " Process class &1 cannot be loaded: &2&3&4
        APPEND VALUE #( %cid = key-%cid
                        %msg = new_message( id       = ls_error-msgid
                                            number   = ls_error-msgno
                                            severity = if_abap_behv_message=>severity-error
                                            v1       = ls_error-msgv1
                                            v2       = ls_error-msgv2
                                            v3       = ls_error-msgv3
                                            v4       = ls_error-msgv4 ) )
               TO reported-processedobject.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD createProcessedObject.
    DATA lt_create TYPE TABLE FOR CREATE zr_prc_ProcessedObjectTP\\ProcessedObject.

    LOOP AT keys ASSIGNING FIELD-SYMBOL(<ls_key>).
      APPEND VALUE #( %cid                        = <ls_key>-%cid
                      RunUUID                     = <ls_key>-%param-runUUID
                      ProcessName                 = <ls_key>-%param-processName
                      payloadJson                 = <ls_key>-%param-payloadJson
                      FactoryClassName            = <ls_key>-%param-factoryClassName
                      ExternalProcessedObjectID   = <ls_key>-%param-processedObject
                      ExternalProcessedObjectUUID = <ls_key>-%param-processedObjectUUID
                      MailAddress                 = <ls_key>-%param-mailAddress
                      DoNotProcessBefore          = <ls_key>-%param-doNotProcessBefore
                      queueID                     = <ls_key>-%param-queueID
                      queuePosition               = <ls_key>-%param-queuePosition
                      State                       = zif_prc_process=>co_start )
             TO lt_create.
    ENDLOOP.

    MODIFY ENTITIES OF zr_prc_ProcessedObjectTP
           IN LOCAL MODE
           ENTITY ProcessedObject
           CREATE FIELDS ( RunUUID ProcessName PayloadJson MailAddress DoNotProcessBefore QueueID QueuePosition FactoryClassName State ExternalProcessedObjectID ExternalProcessedObjectUUID )
           WITH lt_create
           MAPPED   DATA(ls_mapped)
           FAILED   DATA(ls_failed)
           REPORTED DATA(ls_reported).

    mapped-ProcessedObject   = ls_mapped-ProcessedObject.
    failed-ProcessedObject   = ls_failed-ProcessedObject.
    reported-ProcessedObject = ls_reported-ProcessedObject.
  ENDMETHOD.

  METHOD resumeProcessing.
    " Collected until the save: several calls before one save must all be resumed
    gt_processed_objects = VALUE #( BASE gt_processed_objects FOR k IN keys
                                    ( k-uuid ) ).

    MODIFY ENTITIES OF ZR_PRC_ProcessedObjectTP IN LOCAL MODE
           ENTITY ProcessedObject UPDATE FIELDS ( RetryCount RetryDateTime )
           WITH VALUE #( FOR k IN keys
                         ( %key-uuid = k-uuid RetryCount = 0 RetryDateTime = 0 )  ).
  ENDMETHOD.

  METHOD triggerChangedEvent.
    gt_trigger_events_for = VALUE #( BASE gt_trigger_events_for FOR k IN keys ( k-uuid ) ).
  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF zr_prc_ProcessedObjectTP IN LOCAL MODE
         ENTITY ProcessedObject
         FIELDS ( State DoNotProcessBefore )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_processed_objects)
         FAILED failed.

    GET TIME STAMP FIELD DATA(lv_current_timestamp).

    result = VALUE #(
        FOR ls_po IN lt_processed_objects
        ( %tky                     = ls_po-%tky
          %action-resumeProcessing = COND #( WHEN ls_po-State = zif_prc_process=>co_finished OR ls_po-DoNotProcessBefore > lv_current_timestamp
                                             THEN if_abap_behv=>fc-o-disabled
                                             ELSE if_abap_behv=>fc-o-enabled ) ) ).
  ENDMETHOD.
ENDCLASS.


CLASS lsc_ProcessedObject DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.
ENDCLASS.


CLASS lsc_ProcessedObject IMPLEMENTATION.
  METHOD save_modified.
    " Same write path as the processing engine. The process class was checked in the
    " precheck of createProcessedObject, so a create object error here is a real dump.
    zcl_prc_db_writer=>create( )->save( i_create = create
                                        i_update = update
                                        i_delete = delete ).

    IF lhc_processedobject=>gt_processed_objects IS NOT INITIAL.
      zcl_prc_processing_api=>get_instance( )->process_asynchronously_bgpf(
          VALUE #( FOR k IN lhc_processedobject=>gt_processed_objects
                   ( selname = zcl_prc_retry_job=>s_uuid sign = 'I' option = 'EQ' low = k ) ) ).
    ENDIF.
    " Triggered once per save
    CLEAR lhc_processedobject=>gt_processed_objects.

    TRY.
        " Changed objects plus objects whose event was triggered explicitly
        DATA lt_processed_object_uuid TYPE STANDARD TABLE OF zr_prc_processedobjecttp-uuid WITH DEFAULT KEY.
        lt_processed_object_uuid = VALUE #( BASE VALUE #( FOR l IN update-processedobject ( l-uuid ) )
                                            FOR u IN lhc_processedobject=>gt_trigger_events_for ( u ) ).
        IF lt_processed_object_uuid IS NOT INITIAL.
          CALL METHOD ('ZBP_R_PRC_PROCESSEDOBJECTEXT')=>raise_processed_object
            EXPORTING it_processed_object_uuid = lt_processed_object_uuid.
        ENDIF.
      CATCH cx_sy_dyn_call_illegal_class
            cx_sy_dyn_call_illegal_method.
        " nothing to do, the event raiser class is not available in this installation
    ENDTRY.
    " Raised once per save
    CLEAR lhc_processedobject=>gt_trigger_events_for.
  ENDMETHOD.
ENDCLASS.
