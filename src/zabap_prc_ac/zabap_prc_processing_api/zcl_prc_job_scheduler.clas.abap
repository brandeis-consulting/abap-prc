"! <p class="shorttext synchronized">Schedules application jobs</p>
"! Production implementation of ZIF_PRC_JOB_SCHEDULER (application job framework), ABAP
"! Cloud: schedules ABAP Cloud templates only. GET returns the Standard ABAP implementation
"! ZIF_PRC_JOB_SCHEDULER=>CO_IMPLEMENTATION_NAC where it exists, so that Standard ABAP
"! templates can be scheduled, too. Tests replace it via ZCL_PRC_JOB_SCHEDULER_INJECTOR.
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
      " The name is taken at runtime on purpose: the implementation is Standard ABAP
      DATA(implementation) = zif_prc_job_scheduler=>co_implementation_nac.
      TRY.
          CREATE OBJECT go_scheduler TYPE (implementation).
        CATCH cx_sy_create_object_error ##NO_HANDLER.
          " Not available (BTP): ABAP Cloud templates only
      ENDTRY.
      IF go_scheduler IS NOT BOUND.
        go_scheduler = NEW zcl_prc_job_scheduler( ).
      ENDIF.
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


  METHOD zif_prc_job_scheduler~can_schedule.
    r_can_schedule = cl_apj_rt_api=>can_schedule_job( iv_job_template_name = i_template_name ).
  ENDMETHOD.


  METHOD zif_prc_job_scheduler~get_template_parameters.
    DATA template_parameters TYPE REF TO data.
    FIELD-SYMBOLS <template_parameters> TYPE ANY TABLE.

    CLEAR: e_supported, e_names.
    " GET_TEMPLATE_PARAM_VALUES and its result type do not exist in S/4HANA 2023,
    " so both are addressed dynamically
    TRY.
        CREATE DATA template_parameters TYPE ('\CLASS=CL_APJ_RT_API\TYPE=TT_TEMPL_PARAM_VAL_MULTISTEP').
        ASSIGN template_parameters->* TO <template_parameters>.
        CALL METHOD ('CL_APJ_RT_API')=>('GET_TEMPLATE_PARAM_VALUES')
          EXPORTING
            iv_job_template_name = i_template_name
          RECEIVING
            rt_parameters        = <template_parameters>.
      CATCH cx_sy_create_data_error cx_sy_dyn_call_error ##NO_HANDLER.
        " S/4HANA 2023: not supported
        RETURN.
    ENDTRY.

    LOOP AT <template_parameters> ASSIGNING FIELD-SYMBOL(<parameter>).
      ASSIGN COMPONENT 'NAME' OF STRUCTURE <parameter> TO FIELD-SYMBOL(<name>).
      IF sy-subrc = 0.
        INSERT CONV string( <name> ) INTO TABLE e_names.
      ENDIF.
    ENDLOOP.
    e_supported = abap_true.
  ENDMETHOD.

ENDCLASS.
