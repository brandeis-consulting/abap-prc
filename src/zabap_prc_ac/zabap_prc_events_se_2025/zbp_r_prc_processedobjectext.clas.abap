"! Raises the events of the processed object (from 2025). Called dynamically by the
"! saver of ZBP_PRC_PROCESSED_OBJECT - keep the signature in sync with that call.
CLASS zbp_r_prc_processedobjectext DEFINITION PUBLIC ABSTRACT FINAL FOR BEHAVIOR OF zr_prc_processedobjecttp.
  PUBLIC SECTION.
    TYPES tt_uuids TYPE STANDARD TABLE OF ZR_PRC_ProcessedObjectTP-uuid WITH EMPTY KEY.

    "! @parameter i_uuids | Processed objects whose changed event is raised
    CLASS-METHODS raise_processed_object IMPORTING i_uuids TYPE tt_uuids.

ENDCLASS.

CLASS zbp_r_prc_processedobjectext IMPLEMENTATION.
  METHOD raise_processed_object.
    RAISE ENTITY EVENT ZR_PRC_ProcessedObjectTP~zz_objectProcessedTransition
          FROM VALUE #( FOR uuid IN i_uuids
                        ( %key-uuid = uuid ) ).
  ENDMETHOD.

ENDCLASS.
