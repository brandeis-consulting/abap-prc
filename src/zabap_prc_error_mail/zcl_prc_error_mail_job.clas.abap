CLASS zcl_prc_error_mail_job DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_apj_dt_exec_object.
    INTERFACES if_apj_rt_exec_object.

    CONSTANTS c_process_name   TYPE zif_prc_run=>ty_run_parameter VALUE 'S_PROC'.

  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES: BEGIN OF ty_failed_objects,
             processName               TYPE ZR_PRC_ProcessedObject-ProcessName,
             mailAddress               TYPE ZR_PRC_ProcessedObject-MailAddress,
             ExternalProcessedObjectID TYPE ZR_PRC_ProcessedObject-ExternalProcessedObjectID,
             MessageText               TYPE ZR_PRC_ProcessedStep-MessageText,
             CreatedAt                 TYPE ZR_PRC_ProcessedStep-CreatedAt,
           END OF ty_failed_objects,
           tt_failed_objects TYPE STANDARD TABLE OF ty_failed_objects WITH DEFAULT KEY.

    METHODS _get_failed_processed_objects   IMPORTING it_parameters                     TYPE if_apj_rt_exec_object=>tt_templ_val
                                            RETURNING VALUE(r_failed_processed_objects) TYPE tt_failed_objects.

    METHODS _send_mail_for_entries IMPORTING i_failed_processed_objects TYPE tt_failed_objects
                                             i_mail_address             TYPE char0256.

    METHODS _get_mail_html IMPORTING i_failed_processed_objects TYPE tt_failed_objects
                           RETURNING VALUE(r_result)            TYPE string.
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

  METHOD _send_mail_for_entries.
    IF i_mail_address IS INITIAL OR i_failed_processed_objects IS INITIAL.
      RETURN.
    ENDIF.

    DATA(lv_process_name) = i_failed_processed_objects[ 1 ]-processName.

    TRY.
        DATA(lv_main) = cl_bcs_mail_textpart=>create_text_html( _get_mail_html( i_failed_processed_objects ) ).
        DATA(lo_mail_api) = cl_bcs_mail_message=>create_instance( ).

        " not possible in 2023, but later:
        " lo_mail_api->set_importance( cl_bcs_mail_message=>importance-high ).
        TRY.
            CALL METHOD lo_mail_api->('SET_IMPORTANCE')
              EXPORTING
                iv_importance = 1.
          CATCH cx_sy_dyn_call_illegal_method.
            " not possible in 2023
        ENDTRY.

        lo_mail_api->set_sender( 'no_reply@abap-processing-center.de' ).
        lo_mail_api->add_recipient( CONV #( condense( i_mail_address ) ) ).
        lo_mail_api->set_subject( |ABAP Processing Center: Errors in process { lv_process_name }| ).
        lo_mail_api->set_main( lv_main ).

        " TODO: variable is assigned but never used (ABAP cleaner)
        lo_mail_api->send( IMPORTING et_status      = DATA(lt_status)
                           " TODO: variable is assigned but never used (ABAP cleaner)
                                     ev_mail_status = DATA(lv_mail_status) ).
        COMMIT WORK.
      CATCH cx_bcs_mail INTO DATA(lo_message). " TODO: variable is assigned but never used (ABAP cleaner)
    ENDTRY.
  ENDMETHOD.


  METHOD _get_mail_html.
    DATA lv_created_at TYPE timestamp.

    DATA(lv_process_name) = VALUE ty_failed_objects-processName( ).
    IF i_failed_processed_objects IS NOT INITIAL.
      lv_process_name = i_failed_processed_objects[ 1 ]-processName.
    ENDIF.

    r_result = |<!DOCTYPE html>| &&
    |<html>| &&
    |<body style="font-family: Arial, sans-serif; font-size: 14px;">| &&
    |<p>Hello,</p>| &&
    |<p>the following objects of process <strong>{ lv_process_name }</strong> could not be processed successfully in the ABAP Processing Center.</p>| &&
    |<table style="border-collapse: collapse; width: 100%; font-family: Arial, sans-serif; font-size: 14px;">| &&
    |<thead>| &&
    |<tr style="background-color: #0078D4; color: white;">| &&
    |<th style="padding: 10px; border: 1px solid #d1d1d1; text-align: left;">Object ID</th>| &&
    |<th style="padding: 10px; border: 1px solid #d1d1d1; text-align: left;">Error Message</th>| &&
    |<th style="padding: 10px; border: 1px solid #d1d1d1; text-align: left;">Created At (UTC)</th>| &&
    |</tr>| &&
    |</thead>| &&
    |<tbody>|.

    LOOP AT i_failed_processed_objects INTO DATA(ls_entry).
      " cut off fractional seconds instead of rounding
      lv_created_at = trunc( ls_entry-CreatedAt ).
      r_result = r_result &&
                 |<tr style="background-color: #f8f9fa;">| &&
                 |<td style="padding: 10px; border: 1px solid #d1d1d1;">{ ls_entry-ExternalProcessedObjectID }</td>| &&
                 |<td style="padding: 10px; border: 1px solid #d1d1d1;">{ ls_entry-MessageText }</td>| &&
                 |<td style="padding: 10px; border: 1px solid #d1d1d1;">{ lv_created_at TIMESTAMP = SPACE TIMEZONE = 'UTC' }</td>| &&
                 |</tr>|.
    ENDLOOP.

    r_result = r_result &&
    |</tbody>| &&
    |</table>| &&
    |<div style="margin-top: 15px; padding: 12px; background-color: #FFF4CE; border-left: 4px solid #FFB900; font-family: Arial, sans-serif;">| &&
    |<strong>Action required:</strong><br>Please investigate and resolve the issues listed above.</div>| &&
    |<p>Thank you.</p>| &&
    |<p style="color: #6a6d70; font-size: 12px;">This is an automatically generated message from the ABAP Processing Center. Please do not reply.</p>| &&
    |</body>| &&
    |</html>|.
  ENDMETHOD.

  METHOD _get_failed_processed_objects.
    DATA lt_process_name_range TYPE RANGE OF ZR_PRC_ProcessedObject-ProcessName.

    lt_process_name_range = VALUE #( FOR line IN it_parameters WHERE ( selname = c_process_name )
                                     ( CORRESPONDING #( line ) ) ).

    DATA(lv_system_date) = cl_abap_context_info=>get_system_date( ).

    CONVERT DATE lv_system_date TIME '000000'
            INTO TIME STAMP DATA(lv_cutoff) TIME ZONE 'UTC'.

    SELECT FROM ZR_PRC_ProcessedObject
      FIELDS ProcessName,
             MailAddress,
             ExternalProcessedObjectID,
             \_LatestStep-MessageText,
             \_LatestStep-CreatedAt

      WHERE ProcessName                  IN @lt_process_name_range
        AND \_LatestStep-MessageSeverity  = 'E'
        AND CreatedAt < @lv_cutoff
        AND MailAddress                  IS NOT INITIAL
      INTO TABLE @r_failed_processed_objects.
  ENDMETHOD.


  METHOD if_apj_rt_exec_object~execute.
    DATA(lt_failed_processed_objects) = _get_failed_processed_objects( it_parameters ).

    IF lt_failed_processed_objects IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT lt_failed_processed_objects INTO DATA(ls_group)
         GROUP BY ( appName     = ls_group-ProcessName
                    mailAddress = ls_group-mailAddress )
         ASSIGNING FIELD-SYMBOL(<ls_group_key>).

      DATA(lt_members) = VALUE tt_failed_objects( ).
      LOOP AT GROUP <ls_group_key> ASSIGNING FIELD-SYMBOL(<ls_member>).
        APPEND <ls_member> TO lt_members.
        DATA(lv_mail_address) = <ls_member>-mailaddress.
      ENDLOOP.

      _send_mail_for_entries( i_failed_processed_objects = lt_members
                              i_mail_address = CONV #( lv_mail_address ) ).
    ENDLOOP.

    COMMIT WORK.
  ENDMETHOD.
ENDCLASS.
