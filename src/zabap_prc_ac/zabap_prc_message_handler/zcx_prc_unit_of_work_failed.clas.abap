"! <p class="shorttext synchronized">Unit of work failed - signal only, carries no data</p>
"!
"! Raised as soon as the unit of work is known to have failed. Deliberately
"! empty: the failure header and all detail messages live in the message
"! handler, so there is exactly one source of truth for the log.
CLASS zcx_prc_unit_of_work_failed DEFINITION
  PUBLIC INHERITING FROM cx_static_check FINAL CREATE PUBLIC.
protected section.
private section.
ENDCLASS.



CLASS ZCX_PRC_UNIT_OF_WORK_FAILED IMPLEMENTATION.
ENDCLASS.
