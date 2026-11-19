"! <p class="shorttext synchronized">Starts a run from a host application</p>
"!
"! Entry for host applications (e.g. an action of a RAP BO) that start a run: it
"! calls the action initiateRun of the run BO with the selection of the user and
"! the job template of the run job.
"!
"! No COMMIT: the run is saved and its job is scheduled with the commit of the
"! caller's LUW. A rejected run (unknown template or parameter, no authorization)
"! is not created; the reasons are returned to be passed on as REPORTED.
"!
"! A simulation is decided by the run job (ZCL_PRC_RUN_JOB->IS_SIMULATION):
"! pass the value as a parameter of the job like any other.
CLASS zcl_prc_run_initiator DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE .

  PUBLIC SECTION.
    "! The instance to use
    CLASS-METHODS get_instance RETURNING VALUE(r_instance) TYPE REF TO zcl_prc_run_initiator.

    TYPES: BEGIN OF ty_parameter,
             name  TYPE zif_prc_run=>ty_run_parameter,
             value TYPE string,
           END OF ty_parameter,
           tt_parameters TYPE STANDARD TABLE OF ty_parameter WITH EMPTY KEY.

    TYPES tt_messages TYPE STANDARD TABLE OF REF TO if_abap_behv_message WITH EMPTY KEY.

    "! Creates a run and schedules its job (action initiateRun of the run BO).
    "!
    "! @parameter i_selection_json    | Selection of the user as JSON (select options of the job)
    "! @parameter i_parameters        | Further parameters of the job (name, value)
    "! @parameter i_application_name  | Application of the run (authorization ZPRC_RUN)
    "! @parameter i_job_name          | Name of the job, shown in the Runs app
    "! @parameter i_job_template_name | Job template of the run job
    "! @parameter e_messages          | Reasons of a rejection (e.g. ZPRC_RUN/001 unknown parameter,
    "!                                  ZPRC_RUN/010 unknown template), to pass on as REPORTED
    "! @parameter r_run_uuid          | The new run; initial if the run was rejected
    METHODS schedule_run IMPORTING i_selection_json    TYPE string
                                   i_parameters        TYPE tt_parameters
                                   i_application_name  TYPE zprc_run_app_name
                                   i_job_name          TYPE string
                                   i_job_template_name TYPE zif_prc_run=>ty_job_template_name
                         EXPORTING e_messages          TYPE tt_messages
                         RETURNING VALUE(r_run_uuid)   TYPE zprc_run-uuid.
  PROTECTED SECTION.

  PRIVATE SECTION.
    CLASS-DATA instance TYPE REF TO zcl_prc_run_initiator.

    METHODS constructor.
ENDCLASS.



CLASS zcl_prc_run_initiator IMPLEMENTATION.

  METHOD schedule_run.
    DATA select_options TYPE cl_apj_rt_api=>tt_job_parameter_value.

    CLEAR e_messages.

    /ui2/cl_json=>deserialize( EXPORTING json = i_selection_json
                               CHANGING  data = select_options ).

    LOOP AT i_parameters INTO DATA(parameter).
      APPEND VALUE #( name    = parameter-name
                      t_value = VALUE #( ( option = 'EQ' sign = 'I' low = parameter-value ) ) ) TO select_options.
    ENDLOOP.

    DATA(json) = /ui2/cl_json=>serialize( data = select_options ).

    MODIFY ENTITIES OF ZR_PRC_RunTP PRIVILEGED ENTITY Run
           EXECUTE initiateRun FROM VALUE #(
               ( %cid   = 'CID'
                 %param = VALUE #( applicationName    = i_application_name
                                   jobName            = i_job_name
                                   jobTemplateName    = i_job_template_name
                                   selectOptionString = json ) ) )
           MAPPED DATA(mapped)
           REPORTED DATA(reported)
           FAILED DATA(failed).

    " Rejected (e.g. unknown parameter or template): no run, the reasons go to the caller
    " instead of a short dump
    IF failed IS NOT INITIAL OR NOT line_exists( mapped-run[ 1 ] ).
      LOOP AT reported-run INTO DATA(message) WHERE %msg IS BOUND.
        APPEND message-%msg TO e_messages.
      ENDLOOP.
      RETURN.
    ENDIF.

    r_run_uuid = mapped-run[ 1 ]-uuid.
  ENDMETHOD.


  METHOD get_instance.
    IF instance IS NOT BOUND.
      instance = NEW #( ).
    ENDIF.
    r_instance = instance.
  ENDMETHOD.

  METHOD constructor.
  ENDMETHOD.

ENDCLASS.
