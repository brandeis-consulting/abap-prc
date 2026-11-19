"! <p class="shorttext synchronized">Schedules application jobs</p>
"! Seam between the PRC and the application job framework (run app, processing API),
"! so tests can replace the scheduling and simulate its errors
"! (ZCL_PRC_JOB_SCHEDULER_INJECTOR).
"!
"! The job framework does not let an ABAP Cloud caller schedule a Standard ABAP job
"! template. Where it exists (on-premise), the Standard ABAP implementation
"! CO_IMPLEMENTATION_NAC (released C1, created dynamically) is used, so templates of both
"! language versions can be scheduled; otherwise the ABAP Cloud implementation.
INTERFACE zif_prc_job_scheduler PUBLIC.

  "! Standard ABAP implementation, taken at runtime (not on BTP)
  CONSTANTS co_implementation_nac TYPE string VALUE `ZCL_PRC_JOB_SCHEDULER_NAC`.

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

  "! Whether the template exists and the user may schedule it.
  "!
  "! @parameter i_template_name | Job template
  "! @parameter r_can_schedule  | Template can be scheduled
  "! @raising   cx_apj_rt       | Error of the job framework
  METHODS can_schedule
    IMPORTING i_template_name       TYPE cl_apj_rt_api=>ty_template_name
    RETURNING VALUE(r_can_schedule) TYPE abap_bool
    RAISING   cx_apj_rt.

  "! Names of the parameters of the template. Not available in S/4HANA 2023
  "! (CL_APJ_RT_API=>GET_TEMPLATE_PARAM_VALUES): then E_SUPPORTED is initial.
  "!
  "! @parameter i_template_name | Job template
  "! @parameter e_supported     | The names could be determined
  "! @parameter e_names         | Parameter names of the template
  "! @raising   cx_apj_rt       | Error of the job framework
  METHODS get_template_parameters
    IMPORTING i_template_name TYPE cl_apj_rt_api=>ty_template_name
    EXPORTING e_supported     TYPE abap_bool
              e_names         TYPE string_table
    RAISING   cx_apj_rt.

ENDINTERFACE.
