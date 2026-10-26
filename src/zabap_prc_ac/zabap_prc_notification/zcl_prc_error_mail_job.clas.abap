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

    CONSTANTS c_process_name TYPE zif_prc_run=>ty_run_parameter VALUE 'S_PROC'.

    "! Runs the job in this session, without application job (tests, classruns).
    "!
    "! @parameter it_parameters | Parameters as the application job would pass them.
    METHODS execute_synchronously IMPORTING it_parameters TYPE if_apj_rt_exec_object=>tt_templ_val.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_group,
             process_name TYPE zprc_process_name,
             mail_address TYPE zprc_mail_address,
           END OF ty_group,
           tt_groups TYPE STANDARD TABLE OF ty_group WITH EMPTY KEY.

    METHODS _get_groups IMPORTING it_parameters    TYPE if_apj_rt_exec_object=>tt_templ_val
                        RETURNING VALUE(r_groups) TYPE tt_groups.
ENDCLASS.



CLASS zcl_prc_error_mail_job IMPLEMENTATION.

  METHOD if_apj_dt_exec_object~get_parameters.
    CLEAR: et_parameter_def,
           et_parameter_val.

    et_parameter_def = VALUE #( ( changeable_ind = abap_true
                                  mandatory_ind  = abap_true
                                  datatype       = 'C'
                                  selname        = c_process_name
                                  kind           = if_apj_dt_exec_object=>select_option
                                  length         = 30
                                  param_text     = 'Process Name' ) ).
  ENDMETHOD.

  METHOD if_apj_rt_exec_object~execute.
    execute_synchronously( it_parameters ).
  ENDMETHOD.

  METHOD execute_synchronously.
    DATA(lt_groups) = _get_groups( it_parameters ).
    IF lt_groups IS INITIAL.
      RETURN.
    ENDIF.

    zcl_prc_processing_api=>get_instance( )->create_processed_objects(
        i_create_processed_objects = VALUE #(
            FOR g IN lt_groups
            ( processName         = zcl_prc_notif_error_proc=>co_process_name
              factoryClassName    = zcl_prc_notif_error_proc=>co_class_name
              " readable, cut to 50 characters; the group itself is in the payload
              processedObject     = zcl_prc_notification=>object_id( |{ g-process_name } / { condense( g-mail_address ) }| )
              processedObjectUUID = xco_cp=>uuid( )->value
              payloadJson         = zcl_prc_notification=>payload_to_json(
                                        VALUE #( process_name = g-process_name
                                                 mail_address = condense( g-mail_address ) ) ) ) )
        i_perform_commit           = abap_true
        i_trigger_processing       = zcl_prc_processing_api=>execution_mode-direct_execution ).
  ENDMETHOD.

  METHOD _get_groups.
    DATA lt_process_name_range TYPE RANGE OF ZI_PRC_ProcessedObject-ProcessName.

    lt_process_name_range = VALUE #( FOR line IN it_parameters WHERE ( selname = c_process_name )
                                     ( CORRESPONDING #( line ) ) ).

    " MessageSeverity = header of the latest step; objects created today included
    SELECT FROM ZI_PRC_ProcessedObject
      FIELDS DISTINCT ProcessName, MailAddress
      WHERE ProcessName     IN @lt_process_name_range
        AND MessageSeverity  = 'E'
        AND MailAddress     IS NOT INITIAL
      INTO TABLE @r_groups.
  ENDMETHOD.
ENDCLASS.
