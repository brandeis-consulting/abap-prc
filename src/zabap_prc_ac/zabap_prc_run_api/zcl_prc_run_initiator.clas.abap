CLASS zcl_prc_run_initiator DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE .

  PUBLIC SECTION.
    CLASS-METHODS get_instance RETURNING VALUE(ro_instance) TYPE REF TO zcl_prc_run_initiator.

    TYPES: BEGIN OF ty_parameter_table,
             name  TYPE zif_prc_run=>ty_run_parameter,
             value TYPE string,
           END OF ty_parameter_table,
           tt_parameter_table TYPE STANDARD TABLE OF ty_parameter_table WITH DEFAULT KEY.

    TYPES tt_messages TYPE STANDARD TABLE OF REF TO if_abap_behv_message WITH EMPTY KEY.

    "! Creates a run and schedules its job (action initiateRun of the run BO).
    "!
    "! @parameter rv_run_uuid | The new run; initial if the run was rejected
    "! @parameter et_messages | Reasons of a rejection (e.g. ZPRC_RUN/001 unknown parameter,
    "!                          ZPRC_RUN/010 unknown template), to pass on as REPORTED
    METHODS schedule_run IMPORTING iv_selection_option_json TYPE string
                                   it_parameter_table       TYPE tt_parameter_table
                                   iv_application_name      TYPE zprc_run_app_name
                                   iv_job_name              TYPE string
                                   iv_job_template_name     TYPE zif_prc_run=>ty_job_template_name
                         EXPORTING et_messages              TYPE tt_messages
                         RETURNING VALUE(rv_run_uuid)       TYPE zprc_run-uuid.
  PROTECTED SECTION.

  PRIVATE SECTION.
    CLASS-DATA go_instance TYPE REF TO zcl_prc_run_initiator.

    METHODS constructor.
ENDCLASS.



CLASS zcl_prc_run_initiator IMPLEMENTATION.

  METHOD schedule_run.
    DATA select_options TYPE cl_apj_rt_api=>tt_job_parameter_value.

    CLEAR et_messages.

    /ui2/cl_json=>deserialize( EXPORTING json = iv_selection_option_json
                               CHANGING  data = select_options ).

    LOOP AT it_parameter_table INTO DATA(ls_parameter).
      APPEND VALUE #( name = ls_parameter-name t_value = VALUE #( ( option = 'EQ' sign = 'I' low = ls_parameter-value ) ) ) TO select_options.
    ENDLOOP.

    DATA(json) = /ui2/cl_json=>serialize( EXPORTING data = select_options ).

    MODIFY ENTITIES OF ZR_PRC_RunTP PRIVILEGED ENTITY Run
           EXECUTE initiateRun FROM VALUE #(
               ( %cid   = 'CID'
                 %param = VALUE #( applicationName    = iv_application_name
                                   jobName            = iv_job_name
                                   jobTemplateName    = iv_job_template_name
                                   selectOptionString = json ) ) )
           MAPPED DATA(ls_mapped)
           REPORTED DATA(ls_reported)
           FAILED DATA(ls_failed).

    " Rejected (e.g. unknown parameter or template): no run, the reasons go to the caller
    " instead of a short dump (formerly ASSERT, Nr. B1 of 25.10.)
    IF ls_failed IS NOT INITIAL OR NOT line_exists( ls_mapped-run[ 1 ] ).
      LOOP AT ls_reported-run INTO DATA(ls_message) WHERE %msg IS BOUND.
        APPEND ls_message-%msg TO et_messages.
      ENDLOOP.
      RETURN.
    ENDIF.

    rv_run_uuid = ls_mapped-run[ 1 ]-uuid.
  ENDMETHOD.


  METHOD get_instance.
    IF go_instance IS NOT BOUND.
      go_instance = NEW #( ).
    ENDIF.
    ro_instance = go_instance.
  ENDMETHOD.

  METHOD constructor.
  ENDMETHOD.

ENDCLASS.
