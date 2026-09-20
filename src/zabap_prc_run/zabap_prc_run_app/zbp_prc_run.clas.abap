CLASS zbp_prc_run DEFINITION PUBLIC ABSTRACT FINAL FOR BEHAVIOR OF zr_prc_run.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_apj_parameters,
             job_name          TYPE c LENGTH 120,
             job_template_name TYPE zif_prc_run=>ty_job_template_name,
             parameter         TYPE cl_apj_rt_api=>tt_job_parameter_value,
           END OF ty_apj_parameters.
    TYPES tt_apj_parameters TYPE STANDARD TABLE OF ty_apj_parameters.

    CLASS-DATA gt_apj_parameters TYPE tt_apj_parameters.

ENDCLASS.



CLASS ZBP_PRC_RUN IMPLEMENTATION.
ENDCLASS.
