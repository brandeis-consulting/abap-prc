"! <p class="shorttext synchronized">ABAP-PRC: Local update task</p>
"!
"! SET UPDATE TASK LOCAL is not available in ABAP Cloud. The implementation lives
"! in a Standard ABAP package, is released (C1) and is created dynamically. In
"! ABAP Cloud (BTP) the implementation does not exist - there the update task is
"! always local.
INTERFACE zif_prc_update_task PUBLIC.

  CONSTANTS co_implementation TYPE string VALUE `ZCL_PRC_UPDATE_TASK_LOCAL`.

  "! Sets the local update task for the current LUW. Call before the first
  "! update function module is registered.
  METHODS set_local.

ENDINTERFACE.
