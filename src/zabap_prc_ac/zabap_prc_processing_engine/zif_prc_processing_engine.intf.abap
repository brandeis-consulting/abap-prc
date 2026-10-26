"! <p class="shorttext synchronized">ABAP-PRC: Types of the processing engine</p>
"!
"! The state passed through all levels is the complete processed object - no
"! additional result flags. What a step did can be read from the state itself.
INTERFACE zif_prc_processing_engine PUBLIC.

  TYPES ty_state TYPE zr_prc_processedobject.
  TYPES tt_state TYPE STANDARD TABLE OF ty_state WITH EMPTY KEY.

  "! Selection parameters of a processing (UUIDs, process names, ignore retry
  "! scheduling). Refers to the parameter table of the application job framework,
  "! so jobs can pass their parameters unchanged; callers use this name only.
  TYPES tt_parameters TYPE if_apj_rt_exec_object=>tt_templ_val.

ENDINTERFACE.
