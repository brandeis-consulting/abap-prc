CLASS lhc_Message DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PUBLIC SECTION.
    TYPES tt_group_keys TYPE TABLE FOR KEY OF zr_prc_messagetp.

    "! Groups whose changed event is raised in the save phase
    CLASS-DATA gt_trigger_events_for TYPE tt_group_keys.

  PRIVATE SECTION.
    TYPES ty_group_key  TYPE STRUCTURE FOR KEY OF zr_prc_messagetp.
    TYPES: BEGIN OF ty_object_of_group,
             group TYPE ty_group_key,
             uuid  TYPE sysuuid_x16,
           END OF ty_object_of_group,
           tt_objects_of_group TYPE STANDARD TABLE OF ty_object_of_group WITH EMPTY KEY.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Message RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Message RESULT result.

    METHODS resumeProcessing FOR MODIFY
      IMPORTING keys FOR ACTION Message~resumeProcessing RESULT result.

    METHODS triggerChangedEvent FOR MODIFY
      IMPORTING keys FOR ACTION Message~triggerChangedEvent.

    "! Processed objects of the given message groups
    METHODS objects_of_groups IMPORTING i_keys           TYPE tt_group_keys
                              RETURNING VALUE(r_objects) TYPE tt_objects_of_group.
ENDCLASS.

CLASS lhc_Message IMPLEMENTATION.

  METHOD get_instance_features.
    READ ENTITIES OF zr_prc_messagetp IN LOCAL MODE
         ENTITY Message
         FIELDS ( MessageSeverity )
         WITH CORRESPONDING #( keys )
         RESULT DATA(messages).

    result = VALUE #( FOR msg IN messages
                        ( %tky                     = msg-%tky
                          %action-resumeProcessing = COND #( WHEN msg-MessageSeverity <> 'E'
                                                             THEN if_abap_behv=>fc-o-disabled
                                                             ELSE if_abap_behv=>fc-o-enabled ) ) ).
  ENDMETHOD.

  METHOD get_instance_authorizations.
    " Same check as the processed object BO for resume (ZPRC_PROC, activity 16):
    " all objects of a group belong to its process. The resume itself is checked
    " again per object by the processed object BO.
    LOOP AT keys INTO DATA(key).
      APPEND VALUE #( %tky                     = key-%tky
                      %action-resumeProcessing = COND #(
                          WHEN requested_authorizations-%action-resumeProcessing = if_abap_behv=>mk-on
                          THEN zcl_prc_auth_process=>get_behv_authorization(
                                   i_process_name = key-ProcessName
                                   i_activity     = zcl_prc_auth_process=>co_activity-execute ) ) )
             TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD resumeProcessing.
    DATA(objects) = objects_of_groups( CORRESPONDING #( keys ) ).

    " Not privileged: the authorization of the processed object BO applies per object
    MODIFY ENTITIES OF zr_prc_processedobjecttp
      ENTITY ProcessedObject
        EXECUTE resumeProcessing
        FROM VALUE #( FOR o IN objects ( %key-UUID = o-uuid ) )
      FAILED DATA(exec_failed)
      REPORTED DATA(exec_reported) ##NEEDED.

    " Tell the user about objects that were not resumed
    LOOP AT keys INTO DATA(key).
      DATA(group) = CORRESPONDING ty_group_key( key ).
      DATA(total) = 0.
      DATA(not_resumed) = 0.
      LOOP AT objects INTO DATA(object) WHERE group = group.
        total += 1.
        IF line_exists( exec_failed-processedobject[ UUID = object-uuid ] ).
          not_resumed += 1.
        ENDIF.
      ENDLOOP.

      IF not_resumed > 0.
        APPEND VALUE #( %tky = key-%tky
                        %msg = new_message( id       = 'ZPRC_PROCESS_MESSAGE'
                                            number   = '020'
                                            severity = COND #( WHEN not_resumed = total
                                                               THEN if_abap_behv_message=>severity-error
                                                               ELSE if_abap_behv_message=>severity-warning )
                                            v1       = not_resumed
                                            v2       = total ) )
               TO reported-message.
      ENDIF.
      IF not_resumed = total.
        APPEND VALUE #( %tky = key-%tky ) TO failed-message.
      ENDIF.
    ENDLOOP.

    READ ENTITIES OF zr_prc_messagetp IN LOCAL MODE
         ENTITY Message ALL FIELDS WITH CORRESPONDING #( keys )
         RESULT DATA(messages).
    LOOP AT messages INTO DATA(message).
      IF NOT line_exists( failed-message[ %tky = message-%tky ] ).
        APPEND VALUE #( %tky = message-%tky %param = CORRESPONDING #( message ) ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD triggerChangedEvent.
    gt_trigger_events_for = VALUE #( BASE gt_trigger_events_for FOR k IN keys ( CORRESPONDING #( k ) ) ).
  ENDMETHOD.

  METHOD objects_of_groups.
    READ ENTITIES OF zr_prc_messagetp IN LOCAL MODE
      ENTITY Message BY \_ObjectsForMessage
        FIELDS ( ProcessedObjectUUID )
        WITH CORRESPONDING #( i_keys )
      RESULT DATA(objects)
      LINK DATA(links).

    LOOP AT links INTO DATA(link).
      APPEND VALUE #( group = CORRESPONDING #( link-source )
                      uuid  = objects[ StepUUID = link-target-StepUUID ]-ProcessedObjectUUID )
             TO r_objects.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZR_PRC_MESSAGE DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save_modified    REDEFINITION.
    METHODS cleanup_finalize REDEFINITION.
ENDCLASS.

CLASS lsc_ZR_PRC_MESSAGE IMPLEMENTATION.

  METHOD save_modified.
    " Nothing to save: the group is read-only, the objects save themselves.
    " Only the changed event for side effects - raised by the extension class, which
    " exists from 2025 and on BTP (package ZABAP_PRC_EVENTS_SE_2025).
    IF lhc_message=>gt_trigger_events_for IS NOT INITIAL.
      TRY.
          CALL METHOD ('ZBP_R_PRC_MESSAGEEXT')=>raise_message
            EXPORTING it_group_keys = lhc_message=>gt_trigger_events_for.
        CATCH cx_sy_dyn_call_illegal_class
              cx_sy_dyn_call_illegal_method.
          " nothing to do, the event raiser class is not available in this installation
      ENDTRY.
    ENDIF.
    " Raised once per save
    CLEAR lhc_message=>gt_trigger_events_for.
  ENDMETHOD.

  METHOD cleanup_finalize.
    CLEAR lhc_message=>gt_trigger_events_for.
  ENDMETHOD.

ENDCLASS.
