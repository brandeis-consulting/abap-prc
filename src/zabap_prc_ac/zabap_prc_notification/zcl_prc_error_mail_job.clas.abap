"! <p class="shorttext synchronized">ABAP-PRC: Error notification job</p>
"!
"! Creates one notification object (process PRC_ERROR_NOTIFY) per group of
"! objects with errors - process name + mail address - and processes them right
"! away. Reading the objects, building and sending the mail is done by the
"! notification process, with log, retry and resume.
CLASS zcl_prc_error_mail_job DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_apj_dt_exec_object.
    INTERFACES if_apj_rt_exec_object.

    " Selection names of the job parameters. The values are stored in job templates
    " and scheduled jobs - do not change them.
    CONSTANTS:
      BEGIN OF co_parameter,
        "! Select option: process names
        process_name TYPE zif_prc_run=>ty_run_parameter VALUE 'S_PROC',
      END OF co_parameter.

    "! Runs the job in this session, without application job (tests, classruns).
    "!
    "! @parameter i_parameters | Parameters as the application job would pass them.
    METHODS execute_synchronously IMPORTING i_parameters TYPE if_apj_rt_exec_object=>tt_templ_val.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_group,
             process_name TYPE zprc_process_name,
             mail_address TYPE zprc_mail_address,
           END OF ty_group,
           tt_groups TYPE STANDARD TABLE OF ty_group WITH EMPTY KEY.

    "! Process name and mail address of the objects with errors
    METHODS groups_with_errors IMPORTING i_parameters    TYPE if_apj_rt_exec_object=>tt_templ_val
                               RETURNING VALUE(r_groups) TYPE tt_groups.
ENDCLASS.



CLASS zcl_prc_error_mail_job IMPLEMENTATION.

  METHOD if_apj_dt_exec_object~get_parameters.
    CLEAR: et_parameter_def,
           et_parameter_val.

    et_parameter_def = VALUE #( ( changeable_ind = abap_true
                                  mandatory_ind  = abap_true
                                  datatype       = 'C'
                                  selname        = co_parameter-process_name
                                  kind           = if_apj_dt_exec_object=>select_option
                                  length         = 30
                                  param_text     = 'Process Name' ) ).
  ENDMETHOD.

  METHOD if_apj_rt_exec_object~execute.
    execute_synchronously( it_parameters ).
  ENDMETHOD.

  METHOD execute_synchronously.
    DATA(groups) = groups_with_errors( i_parameters ).
    IF groups IS INITIAL.
      RETURN.
    ENDIF.

    zcl_prc_processing_api=>get_instance( )->create_and_process(
        VALUE #(
            FOR g IN groups
            ( processName         = zcl_prc_notif_error_proc=>co_process_name
              factoryClassName    = zcl_prc_notif_error_proc=>co_class_name
              " readable, cut to 50 characters; the group itself is in the payload
              processedObject     = zcl_prc_notification=>object_id( |{ g-process_name } / { condense( g-mail_address ) }| )
              processedObjectUUID = xco_cp=>uuid( )->value
              payloadJson         = zcl_prc_notification=>payload_to_json(
                                        VALUE #( process_name = g-process_name
                                                 mail_address = condense( g-mail_address ) ) ) ) ) ).
  ENDMETHOD.

  METHOD groups_with_errors.
    DATA process_names TYPE RANGE OF ZI_PRC_ProcessedObject-ProcessName.

    process_names = VALUE #( FOR line IN i_parameters WHERE ( selname = co_parameter-process_name )
                             ( CORRESPONDING #( line ) ) ).

    " MessageSeverity = header of the latest step; objects created today included.
    " Objects of a simulation run are reported by the run notification only.
    SELECT FROM ZI_PRC_ProcessedObject
      FIELDS DISTINCT ProcessName, MailAddress
      WHERE ProcessName     IN @process_names
        AND MessageSeverity  = 'E'
        AND MailAddress     IS NOT INITIAL
        AND ( Simulation IS NULL OR Simulation = @abap_false )
      INTO TABLE @r_groups.
  ENDMETHOD.
ENDCLASS.
