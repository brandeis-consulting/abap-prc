"! <p class="shorttext synchronized">Schedules application jobs</p>
"! Production implementation of ZIF_PRC_JOB_SCHEDULER (application job framework).
"! Tests replace it via ZCL_PRC_JOB_SCHEDULER_INJECTOR.
CLASS zcl_prc_job_scheduler DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE
  GLOBAL FRIENDS zcl_prc_job_scheduler_injector.

  PUBLIC SECTION.
    INTERFACES zif_prc_job_scheduler.

    "! The scheduler to use (a test double if one is injected)
    CLASS-METHODS get RETURNING VALUE(r_scheduler) TYPE REF TO zif_prc_job_scheduler.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-DATA go_scheduler TYPE REF TO zif_prc_job_scheduler.
ENDCLASS.



CLASS zcl_prc_job_scheduler IMPLEMENTATION.

  METHOD get.
    IF go_scheduler IS NOT BOUND.
      go_scheduler = NEW zcl_prc_job_scheduler( ).
    ENDIF.
    r_scheduler = go_scheduler.
  ENDMETHOD.


  METHOD zif_prc_job_scheduler~schedule_immediately.
    cl_apj_rt_api=>generate_jobkey( IMPORTING ev_jobname  = DATA(jobname)
                                              ev_jobcount = DATA(jobcount) ).
    cl_apj_rt_api=>schedule_job( iv_job_template_name   = i_template_name
                                 iv_job_text            = i_job_text
                                 is_start_info          = VALUE #( start_immediately = abap_true )
                                 it_job_parameter_value = i_parameters
                                 iv_jobname             = jobname
                                 iv_jobcount            = jobcount ).
  ENDMETHOD.

ENDCLASS.

