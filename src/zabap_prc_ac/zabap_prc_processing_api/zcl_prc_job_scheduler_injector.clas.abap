"! <p class="shorttext synchronized">Test injection of the job scheduler</p>
"! For tests only: replaces the job scheduling of the PRC by a test double, e.g. to
"! check what would be scheduled or to simulate errors of the job framework.
CLASS zcl_prc_job_scheduler_injector DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE
  FOR TESTING.

  PUBLIC SECTION.
    "! Use I_DOUBLE instead of the application job framework (until RESET)
    CLASS-METHODS inject IMPORTING i_double TYPE REF TO zif_prc_job_scheduler.
    "! Back to the production implementation
    CLASS-METHODS reset.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_prc_job_scheduler_injector IMPLEMENTATION.

  METHOD inject.
    zcl_prc_job_scheduler=>go_scheduler = i_double.
  ENDMETHOD.


  METHOD reset.
    CLEAR zcl_prc_job_scheduler=>go_scheduler.
  ENDMETHOD.

ENDCLASS.

