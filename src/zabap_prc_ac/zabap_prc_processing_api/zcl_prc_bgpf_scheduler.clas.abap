"! <p class="shorttext synchronized">Schedules processing via bgPF</p>
"! Production implementation of ZIF_PRC_BGPF_SCHEDULER (background processing
"! framework). Tests replace it via ZCL_PRC_BGPF_SCHED_INJECTOR.
CLASS zcl_prc_bgpf_scheduler DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE
  GLOBAL FRIENDS zcl_prc_bgpf_sched_injector.

  PUBLIC SECTION.
    INTERFACES zif_prc_bgpf_scheduler.

    "! The scheduler to use (a test double if one is injected)
    CLASS-METHODS get RETURNING VALUE(r_scheduler) TYPE REF TO zif_prc_bgpf_scheduler.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-DATA go_scheduler TYPE REF TO zif_prc_bgpf_scheduler.
ENDCLASS.



CLASS zcl_prc_bgpf_scheduler IMPLEMENTATION.

  METHOD get.
    IF go_scheduler IS NOT BOUND.
      go_scheduler = NEW zcl_prc_bgpf_scheduler( ).
    ENDIF.
    r_scheduler = go_scheduler.
  ENDMETHOD.


  METHOD zif_prc_bgpf_scheduler~schedule.
    cl_bgmc_process_factory=>get_default(
        )->create(
        )->set_name( |ABAP Processing Center - asynchronous bgPF execution|
        )->set_operation_tx_uncontrolled( NEW zcl_prc_bgpf( i_parameters )
        )->save_for_execution( ).
  ENDMETHOD.

ENDCLASS.
