CLASS lhc_Message DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Message RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Message RESULT result.

    METHODS resumeProcessing FOR MODIFY
      IMPORTING keys FOR ACTION Message~resumeProcessing RESULT result.

ENDCLASS.

CLASS lhc_Message IMPLEMENTATION.

  METHOD get_instance_features.
    READ ENTITIES OF zr_prc_message IN LOCAL MODE
         ENTITY Message
         FIELDS ( MessageSeverity )
         WITH CORRESPONDING #( keys )
         RESULT DATA(messages).

    result = VALUE #( FOR msg IN messages
                        ( %tky                      = msg-%tky
                          %action-resumeProcessing = COND #( WHEN msg-MessageSeverity <> 'E'
                                                                THEN if_abap_behv=>fc-o-disabled
                                                                ELSE if_abap_behv=>fc-o-enabled ) ) ).
  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD resumeProcessing.
    " Read the associated processed objects of the message
    READ ENTITIES OF zr_prc_message IN LOCAL MODE
      ENTITY Message BY \_ObjectsForMessage
        FIELDS ( ProcessedObjectUUID )
        WITH CORRESPONDING #( keys )
      RESULT DATA(objects_for_message).

    " Trigger restartProcessing on ZR_PRC_ProcessedObject for each processed object UUID
    MODIFY ENTITIES OF zr_prc_processedobject
      ENTITY ProcessedObject
        EXECUTE resumeProcessing
        FROM VALUE #( FOR o IN objects_for_message
                        ( %key-UUID = o-ProcessedObjectUUID ) )
      FAILED DATA(exec_failed)
      REPORTED DATA(exec_reported).
  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZR_PRC_MESSAGE DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZR_PRC_MESSAGE IMPLEMENTATION.

  METHOD save_modified.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
