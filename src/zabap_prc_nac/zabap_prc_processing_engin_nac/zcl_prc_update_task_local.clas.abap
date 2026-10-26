"! <p class="shorttext synchronized">ABAP-PRC: Local update task (Standard ABAP, C1)</p>
"!
"! SET UPDATE TASK LOCAL for the processing engine, which is ABAP Cloud and
"! cannot use the statement itself. Standard ABAP, released (C1), created
"! dynamically by the engine via ZIF_PRC_UPDATE_TASK=>CO_IMPLEMENTATION. Does not
"! exist in ABAP Cloud (BTP), where the update task is always local.
CLASS zcl_prc_update_task_local DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_prc_update_task.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_prc_update_task_local IMPLEMENTATION.

  METHOD zif_prc_update_task~set_local.
    SET UPDATE TASK LOCAL.
  ENDMETHOD.

ENDCLASS.

