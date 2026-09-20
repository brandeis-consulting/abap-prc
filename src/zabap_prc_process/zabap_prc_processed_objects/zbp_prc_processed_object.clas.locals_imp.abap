CLASS lhc_processedmessage DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS messageSeverityCode FOR DETERMINE ON SAVE IMPORTING keys FOR ProcessedMessage~messageSeverityCode.

ENDCLASS.

CLASS lhc_processedmessage IMPLEMENTATION.

  METHOD messageSeverityCode.
    READ ENTITIES OF ZR_PRC_ProcessedObject IN LOCAL MODE
       ENTITY ProcessedMessage
       FIELDS ( MessageSeverity )
       WITH VALUE #( FOR ls_key IN keys
                     ( %key-uuid = ls_key-uuid ) )
       RESULT DATA(lt_steps).

    MODIFY ENTITIES OF ZR_PRC_ProcessedObject IN LOCAL MODE
           ENTITY ProcessedMessage
           UPDATE FIELDS ( MessageSeverityCode ) WITH VALUE #(
               FOR ls_step IN lt_steps
               ( %tky                         = ls_step-%tky
                 MessageSeverityCode          = COND #( WHEN ls_step-MessageSeverity = 'E' THEN 1
                                                        WHEN ls_step-MessageSeverity = 'W' THEN 2
                                                        WHEN ls_step-MessageSeverity = 'S' THEN 3
                                                        WHEN ls_step-MessageSeverity = 'I' THEN 5 ) ) ).
  ENDMETHOD.

ENDCLASS.

CLASS lhc_processedstep DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS messageSeverityCode FOR DETERMINE ON SAVE keys FOR ProcessedStep~messageSeverityCode.

ENDCLASS.

CLASS lhc_processedstep IMPLEMENTATION.
  METHOD messageSeverityCode.
    READ ENTITIES OF ZR_PRC_ProcessedObject IN LOCAL MODE
         ENTITY ProcessedStep
         FIELDS ( MessageSeverity )
         WITH VALUE #( FOR ls_key IN keys
                       ( %key-StepUUID = ls_key-StepUUID ) )
         RESULT DATA(lt_steps).

    MODIFY ENTITIES OF ZR_PRC_ProcessedObject IN LOCAL MODE
           ENTITY ProcessedStep
           UPDATE FIELDS ( MessageSeverityCode ) WITH VALUE #(
               FOR ls_step IN lt_steps
               ( %tky                         = ls_step-%tky
                 MessageSeverityCode          = COND #( WHEN ls_step-MessageSeverity = 'E' THEN 1
                                                        WHEN ls_step-MessageSeverity = 'W' THEN 2
                                                        WHEN ls_step-MessageSeverity = 'S' THEN 3
                                                        WHEN ls_step-MessageSeverity = 'I' THEN 5 ) ) ).
  ENDMETHOD.

ENDCLASS.

CLASS lhc_ProcessedObject DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PUBLIC SECTION.
    CLASS-DATA gt_processed_objects         TYPE STANDARD TABLE OF ZR_PRC_ProcessedObject-uuid WITH DEFAULT KEY.

  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION IMPORTING keys REQUEST requested_authorizations FOR ProcessedObject RESULT result.
    METHODS createProcessedObject FOR MODIFY IMPORTING keys FOR ACTION ProcessedObject~createProcessedObject.
    METHODS resumeProcessing FOR MODIFY IMPORTING keys FOR ACTION ProcessedObject~resumeProcessing." RESULT result.
    METHODS get_instance_features FOR INSTANCE FEATURES IMPORTING keys REQUEST requested_features FOR ProcessedObject RESULT result.
    METHODS determinesteptotal FOR DETERMINE ON SAVE IMPORTING keys FOR processedobject~determinesteptotal.

    METHODS _determine_step_total IMPORTING i_processed_object_uuid TYPE sysuuid_x16
                                  RETURNING VALUE(rv_step_total)    TYPE int8.
ENDCLASS.


CLASS lhc_ProcessedObject IMPLEMENTATION.
  METHOD get_instance_authorizations.

    READ ENTITIES OF ZR_PRC_ProcessedObject IN LOCAL MODE
         ENTITY ProcessedObject
         FIELDS ( ProcessName )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_processed_objects)
         FAILED failed.

    LOOP AT keys INTO DATA(key).

      " Determine the ProcessName for the current instance
      ASSIGN lt_processed_objects[ KEY id
                                   uuid = key-uuid ] TO FIELD-SYMBOL(<ls_po>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      " Check authorization for the resumeProcessing action (ACTVT 16 = Execute)
      AUTHORITY-CHECK OBJECT 'ZPRC_PROC'
                     ID 'ZPRCNAME' FIELD <ls_po>-ProcessName
                     ID 'ACTVT'     FIELD '16'.
      IF sy-subrc = 0.
        DATA(lv_resume_processing) = if_abap_behv=>auth-allowed.
      ELSE.
        lv_resume_processing = if_abap_behv=>auth-unauthorized.
      ENDIF.

      " Fill the result table with the determined authorization
      APPEND VALUE #( %tky                     = key-%tky
                      %action-resumeProcessing = lv_resume_processing )
             TO result.

    ENDLOOP.

  ENDMETHOD.

  METHOD createProcessedObject.
    DATA lt_create TYPE TABLE FOR CREATE zr_prc_ProcessedObject\\ProcessedObject.

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

    MODIFY ENTITIES OF zr_prc_ProcessedObject
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
    gt_processed_objects = VALUE #( FOR k IN keys
                                    ( k-uuid ) ).

    MODIFY ENTITIES OF ZR_PRC_ProcessedObject IN LOCAL MODE
           ENTITY ProcessedObject UPDATE FIELDS ( RetryCount RetryDateTime )
           WITH VALUE #( FOR k IN keys
                         ( %key-uuid = k-uuid RetryCount = 0 RetryDateTime = 0 )  ).
  ENDMETHOD.


  METHOD get_instance_features.
    READ ENTITIES OF zr_prc_ProcessedObject IN LOCAL MODE
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

  METHOD determineStepTotal.
    LOOP AT keys INTO DATA(key).
      DATA(lv_step_total) = _determine_step_total( key-%key-uuid ).

      MODIFY ENTITIES OF ZR_PRC_ProcessedObject IN LOCAL MODE
             ENTITY ProcessedObject
             UPDATE FIELDS ( StepTotal ) WITH VALUE #( ( %tky = key-%tky StepTotal = lv_step_total ) ).

    ENDLOOP.
  ENDMETHOD.

  METHOD _determine_step_total.
    READ ENTITIES OF ZR_PRC_ProcessedObject IN LOCAL MODE
         ENTITY ProcessedObject
         FIELDS ( FactoryClassName State )
         WITH VALUE #( ( %key-uuid = i_processed_object_uuid ) )
         RESULT DATA(lt_processed_object).

    IF lt_processed_object IS INITIAL.
      RETURN.
    ENDIF.

    DATA(i_factory_class_name) = lt_processed_object[ 1 ]-FactoryClassName.
    DATA(i_current_state)      = lt_processed_object[ 1 ]-State.

    " get the current number of persisted transitions
    SELECT SINGLE FROM ZI_PRC_ProcessedObjectAggr WITH PRIVILEGED ACCESS
      FIELDS StepCounter
      WHERE ProcessedObjectUUID = @i_processed_object_uuid
      INTO @rv_step_total.
    SELECT SINGLE FROM ZR_PRC_ProcessedObject WITH PRIVILEGED ACCESS
      FIELDS State
      WHERE uuid = @i_processed_object_uuid
      INTO @DATA(i_start_state).

    " get the shortest way to state finish
    DATA ro_factory TYPE REF TO zif_prc_process.
    CREATE OBJECT ro_factory TYPE (i_factory_class_name).
    DATA(transitions) = ro_factory->get_transitions( ).
    DATA next_transitions LIKE transitions.
    DATA(current_transitions) = VALUE zif_prc_process=>tt_transition( ).

    LOOP AT transitions INTO DATA(transition) WHERE start_state = i_current_state.
      INSERT transition INTO TABLE current_transitions.
    ENDLOOP.

    IF i_start_state <> i_current_state AND i_start_state IS NOT INITIAL.
      rv_step_total += 1.
      IF i_current_state = zif_prc_process=>co_finished.
        RETURN.
      ENDIF.
    ENDIF.
    DO.
      ASSERT rv_step_total < 100000. " prevent infinity loops
      rv_step_total += 1.
      CLEAR next_transitions.
      LOOP AT current_transitions INTO DATA(current_transition).
        IF current_transition-end_state = zif_prc_process=>co_finished.
          CONTINUE.
        ENDIF.
        LOOP AT transitions INTO transition WHERE start_state = current_transition-end_state.
          INSERT transition INTO TABLE next_transitions.
        ENDLOOP.
      ENDLOOP.
      IF next_transitions IS INITIAL.
        RETURN.
      ELSE.
        current_transitions = next_transitions.
      ENDIF.
    ENDDO.
  ENDMETHOD.
ENDCLASS.


CLASS lsc_ProcessedObject DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.
ENDCLASS.


CLASS lsc_ProcessedObject IMPLEMENTATION.
  METHOD save_modified.
    IF lhc_processedobject=>gt_processed_objects IS NOT INITIAL.
      zcl_prc_processing_api=>get_instance( )->execute_asynch_for_proc_obj( lhc_processedobject=>gt_processed_objects ).
    ENDIF.

    TRY.
        DATA lt_processed_object_uuid TYPE STANDARD TABLE OF zr_prc_processedobject-uuid WITH DEFAULT KEY.
        lt_processed_object_uuid = VALUE #( FOR k IN update-processedobject
                                            ( k-uuid ) ).
        CALL METHOD ('ZBP_R_PRC_PROCESSEDOBJECTEXT')=>raise_processed_object
          EXPORTING
            it_processed_object_uuid = lt_processed_object_uuid.
      CATCH cx_sy_dyn_call_illegal_class
            cx_sy_dyn_call_illegal_method.
        " nothing to do, the event raiser class is not available in this installation
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
