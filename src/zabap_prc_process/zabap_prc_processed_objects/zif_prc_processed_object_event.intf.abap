INTERFACE zif_prc_processed_object_event
  PUBLIC.

  TYPES tt_processed_object_uuid TYPE STANDARD TABLE OF ZR_PRC_ProcessedObject-uuid WITH DEFAULT KEY.

  CLASS-METHODS raise_processed_object IMPORTING it_processed_object_uuid TYPE tt_processed_object_uuid.

ENDINTERFACE.
