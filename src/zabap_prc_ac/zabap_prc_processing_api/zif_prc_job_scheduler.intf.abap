"! <p class="shorttext synchronized">Schedules application jobs</p>
"! Seam between the PRC and the application job framework (run app, processing API),
"! so tests can replace the scheduling and simulate its errors
"! (ZCL_PRC_JOB_SCHEDULER_INJECTOR).
INTERFACE zif_prc_job_scheduler PUBLIC.

  "! Schedules a job of the template to start immediately. No COMMIT inside: the job
  "! becomes visible to the scheduler with the commit of the caller's LUW.
  "!
  "! @parameter i_template_name | Job template
  "! @parameter i_job_text      | Text of the job
  "! @parameter i_parameters    | Parameter values
  "! @raising   cx_apj_rt       | The job could not be scheduled
  METHODS schedule_immediately
    IMPORTING i_template_name TYPE cl_apj_rt_api=>ty_template_name
              i_job_text      TYPE cl_apj_rt_api=>ty_job_text
              i_parameters    TYPE cl_apj_rt_api=>tt_job_parameter_value
    RAISING   cx_apj_rt.

ENDINTERFACE.
