"! <p class="shorttext synchronized">Processing API</p>
"!
"! Creates processed objects and triggers their processing - synchronously, via
"! bgPF or via an application job.
"!
"! Triggering asynchronously is best effort: if scheduling fails, the created
"! objects stay in their start state and the retry job processes them. The
"! caller cannot do anything better, so no exception is raised.
CLASS zcl_prc_processing_api DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS get_instance RETURNING VALUE(r_instance) TYPE REF TO zcl_prc_processing_api.

    TYPES:
      BEGIN OF ENUM ty_execution_mode STRUCTURE execution_mode BASE TYPE i,
        no_execution       VALUE IS INITIAL,
        direct_execution   VALUE 1,
        bgpf_execution     VALUE 2,
        appl_job_execution VALUE 3,
      END OF ENUM ty_execution_mode STRUCTURE execution_mode.

    TYPES tt_create_processed_objects TYPE STANDARD TABLE OF ZA_PRC_CreateProcessedObject WITH DEFAULT KEY.

    "! Processes the due objects selected by the parameters in this session.
    "!
    "! @parameter it_parameters | UUIDs, process names, ignore retry scheduling.
    METHODS process_synchronously       IMPORTING it_parameters TYPE zif_prc_processing_engine=>tt_parameters OPTIONAL.

    "! Schedules the processing via bgPF. If scheduling fails, nothing happens:
    "! the objects stay due and the retry job processes them.
    "!
    "! @parameter it_parameters | UUIDs, process names, ignore retry scheduling.
    METHODS process_asynchronously_bgpf IMPORTING it_parameters TYPE zif_prc_processing_engine=>tt_parameters OPTIONAL.

    "! Schedules the processing as application job. If scheduling fails, nothing
    "! happens: the objects stay due and the retry job processes them.
    "!
    "! @parameter it_parameters | UUIDs, process names, ignore retry scheduling.
    METHODS process_asynchronously_job  IMPORTING it_parameters TYPE zif_prc_processing_engine=>tt_parameters OPTIONAL.

    "! Creates processed objects in their start state and triggers their processing.
    "!
    "! @parameter i_create_processed_objects | Objects to create.
    "! @parameter i_perform_commit           | COMMIT WORK after creating.
    "! @parameter i_trigger_processing       | How to process the created objects.
    METHODS create_processed_objects IMPORTING i_create_processed_objects TYPE tt_create_processed_objects
                                               i_perform_commit           TYPE abap_bool         DEFAULT abap_false
                                               i_trigger_processing       TYPE ty_execution_mode DEFAULT ''.
  PRIVATE SECTION.
    CLASS-DATA g_instance TYPE REF TO zcl_prc_processing_api.
ENDCLASS.


CLASS zcl_prc_processing_api IMPLEMENTATION.

  METHOD process_asynchronously_bgpf.
    TRY.
        cl_bgmc_process_factory=>get_default(
            )->create(
            )->set_name( |ABAP Processing Center - asynchronous bgPF execution|
            )->set_operation_tx_uncontrolled( NEW zcl_prc_bgpf( it_parameters )
            )->save_for_execution( ).
      CATCH cx_bgmc ##NO_HANDLER.
        " Best effort: the objects stay due, the retry job processes them.
        " TODO: entry in the application log (logging BAdI)
    ENDTRY.
  ENDMETHOD.

  METHOD process_asynchronously_job.
    DATA lt_job_parameter TYPE cl_apj_rt_api=>tt_job_parameter_value.

    LOOP AT it_parameters INTO FINAL(ls_parameter).
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
        zcl_prc_job_scheduler=>get( )->schedule_immediately( i_template_name = zcl_prc_retry_job=>c_apj_template_name
                                                             i_job_text      = |ABAP-PRC: Trigger processing asynch via APJ|
                                                             i_parameters    = lt_job_parameter ).
      CATCH cx_apj_rt ##NO_HANDLER.
        " Best effort: the objects stay due, the retry job processes them.
        " TODO: entry in the application log (logging BAdI)
    ENDTRY.
  ENDMETHOD.

  METHOD process_synchronously.
    zcl_prc_processing_engine=>get_instance( )->execute_synchronously( it_parameters ).
  ENDMETHOD.

  METHOD get_instance.
    IF g_instance IS NOT BOUND.
      g_instance = NEW #( ).
    ENDIF.
    r_instance = g_instance.
  ENDMETHOD.


  METHOD create_processed_objects.
    CHECK i_create_processed_objects IS NOT INITIAL.

    DATA(objects) = VALUE zif_prc_db_writer=>ty_create-processedobject(
        FOR k IN i_create_processed_objects
        ( UUID                        = xco_cp=>uuid( )->value
          ProcessName                 = k-processName
          FactoryClassName            = k-factoryClassName
          MailAddress                 = k-mailAddress
          PayloadJson                 = k-payloadJson
          ExternalProcessedObjectID   = k-processedObject
          ExternalProcessedObjectUUID = k-processedObjectUUID
          QueueID                     = k-queueID
          QueuePosition               = k-queuePosition
          RunUUID                     = k-runUUID
          DoNotProcessBefore          = k-doNotProcessBefore
          State                       = zif_prc_process=>co_start ) ).

    " Same write path as BO and engine: admin fields, ETag and StepTotal are derived
    " there. Unlike the BO action there is no precheck: a process class that cannot be
    " loaded (e.g. syntax error) does not lose the object. It is created without step
    " total, its first step fails visibly with the reason, and the retry job processes
    " it once the class is corrected (see ZCL_PRC_PROCESS_LOADER).
    zcl_prc_db_writer=>create( )->save( i_create = VALUE #( processedobject = objects ) ).

    IF i_perform_commit = abap_true.
      COMMIT WORK.
    ENDIF.

    DATA(lt_processing_parameters) = VALUE zif_prc_processing_engine=>tt_parameters(
        FOR o IN objects
        ( selname = zcl_prc_retry_job=>s_uuid sign = 'I' option = 'EQ' low = o-UUID ) ).

    CASE i_trigger_processing.
      WHEN execution_mode-no_execution.
        " do nothing
      WHEN execution_mode-direct_execution.
        process_synchronously( lt_processing_parameters ).
      WHEN execution_mode-bgpf_execution.
        process_asynchronously_bgpf( lt_processing_parameters ).
      WHEN execution_mode-appl_job_execution.
        process_asynchronously_job( lt_processing_parameters ).
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
