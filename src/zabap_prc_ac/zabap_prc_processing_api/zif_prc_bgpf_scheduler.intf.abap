"! <p class="shorttext synchronized">Schedules processing via bgPF</p>
"! Seam between the PRC and the background processing framework (processing API),
"! so tests can replace the scheduling and simulate its errors
"! (ZCL_PRC_BGPF_SCHED_INJECTOR).
INTERFACE zif_prc_bgpf_scheduler PUBLIC.

  "! Schedules the processing of the selected objects as bgPF process. No COMMIT
  "! inside: the process starts with the commit of the caller's LUW.
  "!
  "! @parameter i_parameters | UUIDs, process names, ignore retry scheduling
  "! @raising   cx_bgmc      | The bgPF process could not be scheduled
  METHODS schedule
    IMPORTING i_parameters TYPE zif_prc_processing_engine=>tt_parameters
    RAISING   cx_bgmc.

ENDINTERFACE.
