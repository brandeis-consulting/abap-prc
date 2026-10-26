"! <p class="shorttext synchronized">ABAP-PRC: Writes the PRC persistence</p>
"!
"! The only write path to the PRC tables. Used by the unmanaged save of the
"! processed object BO and directly by the processing engine. It takes the
"! derived types the RAP saver receives, so both callers share one code path.
"!
"! Writes per SQL and derives everything that used to be a determination:
"! admin fields, ETag, severity codes, LatestStepUUID and StepTotal.
"! It neither commits nor raises events.
INTERFACE zif_prc_db_writer PUBLIC.

  TYPES ty_create TYPE zbp_prc_processed_object=>ty_create.
  TYPES ty_update TYPE zbp_prc_processed_object=>ty_update.
  TYPES ty_delete TYPE zbp_prc_processed_object=>ty_delete.

  "! Writes one change set.
  "!
  "! @parameter i_create                  | New instances of all three entities with their final keys.
  "! @parameter i_update                  | Changed instances, always complete rows (BO: with full data).
  "! @parameter i_delete                  | Deleted instances; an object takes its steps and messages along.
  "! @raising   cx_sy_create_object_error | The process class of an object cannot be instantiated.
  METHODS save IMPORTING i_create TYPE ty_create OPTIONAL
                         i_update TYPE ty_update OPTIONAL
                         i_delete TYPE ty_delete OPTIONAL
               RAISING   cx_sy_create_object_error.

ENDINTERFACE.
