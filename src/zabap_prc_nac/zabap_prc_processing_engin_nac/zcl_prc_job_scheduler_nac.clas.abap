"! <p class="shorttext synchronized">ABAP-PRC: Schedules app. jobs of both language versions</p>
"!
"! Standard ABAP, released (C1), created dynamically by ZCL_PRC_JOB_SCHEDULER=>GET via
"! ZIF_PRC_JOB_SCHEDULER=>CO_IMPLEMENTATION_NAC.
"!
"! The application job framework does not let an ABAP Cloud caller schedule a Standard
"! ABAP job template (catalog entry and template cannot be released). Called from here,
"! the caller is Standard ABAP: templates of both language versions can be checked and
"! scheduled. Same logic as the ABAP Cloud implementation ZCL_PRC_JOB_SCHEDULER.
CLASS zcl_prc_job_scheduler_nac DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_prc_job_scheduler.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_prc_job_scheduler_nac IMPLEMENTATION.

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
