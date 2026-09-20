CLASS zcl_prc_processing_api DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS get_instance RETURNING VALUE(r_instance) TYPE REF TO zcl_prc_processing_api.

    TYPES tt_processed_object_uuid       TYPE STANDARD TABLE OF zr_prc_processedobject-uuid WITH DEFAULT KEY.
    TYPES tt_processed_objects_to_create TYPE TABLE FOR ACTION IMPORT zr_prc_processedobject~createprocessedobject.
    TYPES ty_failed                      TYPE RESPONSE FOR FAILED EARLY zr_prc_processedobject.
    TYPES ty_reported                    TYPE RESPONSE FOR REPORTED EARLY zr_prc_processedobject.
    TYPES ty_mapped                      TYPE RESPONSE FOR MAPPED EARLY ZR_PRC_ProcessedObject.

    METHODS add_processed_objects_and_exec IMPORTING i_processed_objects_to_create TYPE tt_processed_objects_to_create
                                           EXPORTING e_failed                      TYPE ty_failed
                                                     e_reported                    TYPE ty_reported
                                                     e_mapped                      TYPE ty_mapped.

    METHODS execute_synchronously       IMPORTING it_parameters            TYPE if_apj_rt_exec_object=>tt_templ_val OPTIONAL.
    METHODS execute_asynchronously      IMPORTING it_parameters            TYPE if_apj_rt_exec_object=>tt_templ_val OPTIONAL.
    METHODS execute_asynch_for_proc_obj IMPORTING it_processed_object_uuid TYPE tt_processed_object_uuid.

    TYPES:
      BEGIN OF ENUM ty_execution_mode STRUCTURE execution_mode BASE TYPE i,
        no_execution       VALUE IS INITIAL,
        direct_execution   VALUE 1,
        bgpf_execution     VALUE 2,
        appl_job_execution VALUE 3,
      END OF ENUM ty_execution_mode STRUCTURE execution_mode.

    TYPES tt_create_processed_objects TYPE STANDARD TABLE OF ZA_PRC_CreateProcessedObject WITH DEFAULT KEY.

    METHODS create_processed_objects IMPORTING i_create_processed_objects TYPE tt_create_processed_objects
                                               i_perform_commit           TYPE abap_bool         DEFAULT abap_false
                                               i_trigger_processing       TYPE ty_execution_mode DEFAULT ''.

  PRIVATE SECTION.
    METHODS _add_processed_objects IMPORTING i_processed_objects_to_create TYPE tt_processed_objects_to_create
                                   EXPORTING e_failed                      TYPE ty_failed
                                             e_reported                    TYPE ty_reported
                                             e_mapped                      TYPE ty_mapped.

    CLASS-DATA g_instance TYPE REF TO zcl_prc_processing_api.
ENDCLASS.


CLASS zcl_prc_processing_api IMPLEMENTATION.
  METHOD _add_processed_objects.
    DATA lt_action_parameters TYPE TABLE FOR ACTION IMPORT zr_prc_processedobject~createprocessedobject.

    LOOP AT i_processed_objects_to_create INTO DATA(k).
      INSERT VALUE #( %cid   = COND #( WHEN k-%cid IS NOT INITIAL THEN k-%cid ELSE |CID{ sy-tabix }| )
                      %param = k-%param ) INTO TABLE lt_action_parameters.
    ENDLOOP.

    MODIFY ENTITIES OF ZR_PRC_ProcessedObject
           ENTITY ProcessedObject
           EXECUTE createProcessedObject FROM lt_action_parameters
           FAILED e_failed
           REPORTED e_reported
           MAPPED e_mapped.
  ENDMETHOD.

  METHOD execute_asynchronously.
    TRY.
        cl_bgmc_process_factory=>get_default(
            )->create(
            )->set_name( |ZCL_PRC_JOB async execution|
            )->set_operation_tx_uncontrolled( NEW zcl_prc_bgpf( it_parameters )
            )->save_for_execution( ).
      CATCH cx_bgmc INTO DATA(lx_bgmc).
        ASSERT lx_bgmc IS NOT BOUND.
    ENDTRY.
  ENDMETHOD.

  METHOD execute_asynch_for_proc_obj.
    execute_asynchronously( VALUE #(  FOR k IN it_processed_object_uuid
                                     ( selname = zcl_prc_retry_job=>s_uuid sign = 'I' option = 'EQ' low = k ) ) ).
  ENDMETHOD.

  METHOD execute_synchronously.
    zcl_prc_processing_engine=>get_instance( )->execute_synchronously( it_parameters ).
  ENDMETHOD.

  METHOD get_instance.
    IF g_instance IS NOT BOUND.
      g_instance = NEW #( ).
    ENDIF.
    r_instance = g_instance.
  ENDMETHOD.

  METHOD add_processed_objects_and_exec.
    _add_processed_objects( EXPORTING i_processed_objects_to_create = i_processed_objects_to_create
                            IMPORTING e_reported                    = e_reported
                                      e_failed                      = e_failed
                                      e_mapped                      = e_mapped ).
    COMMIT ENTITIES.
    zcl_prc_processing_engine=>get_instance( )->execute_synchronously(
        VALUE #( FOR mapped IN e_mapped-processedobject
                 ( selname = zcl_prc_retry_job=>s_uuid sign = 'I' option = 'EQ' low = mapped-uuid ) ) ).
  ENDMETHOD.

  METHOD create_processed_objects.
    TYPES tt_proc_obj TYPE STANDARD TABLE OF zprc_proc_object WITH DEFAULT KEY.

    CHECK i_create_processed_objects IS NOT INITIAL.

    DATA(lt_proc_obj) = VALUE tt_proc_obj( FOR k IN i_create_processed_objects
                                           ( do_not_process_before     = k-doNotProcessBefore
                                             factory_class_name        = k-factoryClassName
                                             mail_address              = k-mailAddress
                                             payload_json              = k-payloadJson
                                             process_name              = k-processName
                                             ext_processed_object_id   = k-processedObject
                                             ext_processed_object_uuid = k-processedObjectUUID
                                             queue_id                  = k-queueID
                                             queue_pos                 = k-queuePosition
                                             run_uuid                  = k-runUUID
                                             State                     = zif_prc_process=>co_start ) ).

    LOOP AT lt_proc_obj ASSIGNING FIELD-SYMBOL(<fs>).
      TRY.
          <fs>-uuid = cl_uuid_factory=>create_system_uuid( )->create_uuid_x16( ).
        CATCH cx_root INTO DATA(lx).
          ASSERT lx IS NOT BOUND.
      ENDTRY.
    ENDLOOP.
    INSERT zprc_proc_object FROM TABLE lt_proc_obj.

    IF i_perform_commit = abap_true.
      COMMIT WORK.
    ENDIF.

    DATA(lt_processing_parameters) = VALUE if_apj_rt_exec_object=>tt_templ_val(
        FOR l IN lt_proc_obj
        ( SELname  = zcl_prc_retry_job=>s_uuid sign = 'I' option = 'EQ' low = l-uuid ) ).

    CASE i_trigger_processing.
      WHEN execution_mode-no_execution.
        " do nothing
      WHEN execution_mode-direct_execution.
        zcl_prc_processing_engine=>get_instance( )->execute_synchronously( lt_processing_parameters ).
      WHEN execution_mode-bgpf_execution.
        TRY.
            cl_bgmc_process_factory=>get_default(
                )->create(
                )->set_name( |Start ABAP-PRC execution via BGPF|
                )->set_operation_tx_uncontrolled( NEW zcl_prc_bgpf( lt_processing_parameters )
                )->save_for_execution( ).
          CATCH cx_bgmc INTO DATA(lx_bgmc).
            ASSERT lx_bgmc IS NOT BOUND.
        ENDTRY.

      WHEN execution_mode-appl_job_execution.
        DATA lt_job_parameter TYPE cl_apj_rt_api=>tt_job_parameter_value.

        LOOP AT lt_processing_parameters INTO FINAL(ls_parameter).
          READ TABLE lt_job_parameter WITH KEY name COMPONENTS name = ls_parameter-selname ASSIGNING FIELD-SYMBOL(<fs_job_parameter>).
          IF sy-subrc <> 0.
            APPEND VALUE #( name = ls_parameter-selname ) TO lt_job_parameter ASSIGNING <fs_job_parameter>.
          ENDIF.
          APPEND VALUE #( sign   = ls_parameter-sign
                          option = ls_parameter-option
                          low    = ls_parameter-low
                          high   = ls_parameter-high ) TO <fs_job_parameter>-t_value.
        ENDLOOP.

        TRY.
            cl_apj_rt_api=>generate_jobkey( IMPORTING ev_jobname  = DATA(jobname)
                                                      ev_jobcount = DATA(JobCount) ).
            cl_apj_rt_api=>schedule_job( iv_job_template_name   = zcl_prc_retry_job=>c_apj_template_name
                                         iv_job_text            = |ABAP-PRC: Trigger processing asynch via APJ|
                                         is_start_info          = VALUE #( start_immediately = abap_true )
                                         it_job_parameter_value = lt_job_parameter
                                         iv_jobname             = jobname
                                         iv_jobcount            = JobCount ).
          CATCH cx_apj_rt INTO DATA(lo_exception).
            DATA(lv_text) = lo_exception->get_text( ).
            ASSERT |No Error| = lv_text.
        ENDTRY.

    ENDCASE.
  ENDMETHOD.
ENDCLASS.
