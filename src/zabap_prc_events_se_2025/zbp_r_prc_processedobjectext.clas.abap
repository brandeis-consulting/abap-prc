CLASS zbp_r_prc_processedobjectext DEFINITION PUBLIC ABSTRACT FINAL FOR BEHAVIOR OF zr_prc_processedobject.
  PUBLIC SECTION.
    TYPES tt_processed_object_uuid TYPE STANDARD TABLE OF ZR_PRC_ProcessedObject-uuid WITH DEFAULT KEY.
    CLASS-METHODS raise_processed_object IMPORTING it_processed_object_uuid TYPE tt_processed_object_uuid.

ENDCLASS.

CLASS zbp_r_prc_processedobjectext IMPLEMENTATION.
  METHOD raise_processed_object.
    RAISE ENTITY EVENT ZR_PRC_ProcessedObject~zz_objectProcessedTransition
          FROM VALUE #( FOR uuid IN it_processed_object_uuid
                        ( %key-uuid = uuid ) ).
  ENDMETHOD.

ENDCLASS.
