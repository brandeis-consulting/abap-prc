CLASS zbp_prc_processed_object DEFINITION PUBLIC ABSTRACT FINAL FOR BEHAVIOR OF zr_prc_processedobjecttp
  GLOBAL FRIENDS zif_prc_db_writer.

  PROTECTED SECTION.
    "! Change set of the unmanaged save, also used by the processing engine.
    "! Exposed to the DB writer only; REQUEST FOR CHANGE is available in
    "! implementation classes of the BO only.
    TYPES ty_create TYPE REQUEST FOR CHANGE zr_prc_processedobjecttp.
    TYPES ty_update TYPE REQUEST FOR CHANGE zr_prc_processedobjecttp.
    TYPES ty_delete TYPE REQUEST FOR DELETE zr_prc_processedobjecttp.

  PRIVATE SECTION.
ENDCLASS.



CLASS zbp_prc_processed_object IMPLEMENTATION.
ENDCLASS.
