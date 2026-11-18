"! <p class="shorttext synchronized">Run interface</p>
"! Types and constants of the run pattern. Application specific values - job
"! template and application name - belong to the job of the application
"! (see ZCL_PRC_RUN_JOB=>GET_APPLICATION_NAME), not here.
INTERFACE zif_prc_run
  PUBLIC.

  TYPES ty_run_parameter     TYPE c LENGTH 8.
  TYPES ty_job_template_name TYPE c LENGTH 30.

  CONSTANTS: BEGIN OF co_message_severity,
               neutral TYPE zprc_message_severity_code VALUE 0,
               error   TYPE zprc_message_severity_code VALUE 1,
               warning TYPE zprc_message_severity_code VALUE 2,
               success TYPE zprc_message_severity_code VALUE 3,
               info    TYPE zprc_message_severity_code VALUE 5,
             END OF co_message_severity.

  " Execution status of a run. FINISHED: all objects processed (each one
  " successfully or not). ABORTED: the run job stopped, reason at the run and in
  " the application log (external ID = run UUID).
  CONSTANTS: BEGIN OF co_execution_status,
               started  TYPE zprc_run_execution_status VALUE 'ST',
               planned  TYPE zprc_run_execution_status VALUE 'PL',
               finished TYPE zprc_run_execution_status VALUE 'FI',
               aborted  TYPE zprc_run_execution_status VALUE 'AB',
             END OF co_execution_status.

  CONSTANTS: BEGIN OF co_parameter,
               p_uuid TYPE ty_run_parameter VALUE 'P_UUID',
             END OF co_parameter.

ENDINTERFACE.
