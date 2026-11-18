"! <p class="shorttext synchronized">Processing API</p>
"!
"! Creates processed objects and triggers their processing - synchronously, via
"! bgPF or via an application job. One method per use case:
"! <ul>
"! <li>CREATE - only create; the caller commits, the retry job processes them</li>
"! <li>CREATE_AND_PROCESS - create, commit and process in this session</li>
"! <li>CREATE_AND_SCHEDULE_BGPF / _JOB - create and schedule; the commit of the
"! caller's LUW starts the processing (e.g. from the save phase of a RAP BO)</li>
"! </ul>
"! If scheduling fails, the original exception of the framework is raised: the
"! caller asked for it explicitly, so a failure must not go unnoticed.
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

    TYPES tt_create_processed_objects TYPE STANDARD TABLE OF ZA_PRC_CreateProcessedObject WITH EMPTY KEY.

    "! Processes the due objects selected by the parameters in this session.
    "!
    "! @parameter i_parameters | UUIDs, process names, ignore retry scheduling.
    METHODS process_synchronously       IMPORTING i_parameters TYPE zif_prc_processing_engine=>tt_parameters OPTIONAL.

    "! Schedules the processing via bgPF. No COMMIT: the commit of the caller's LUW
    "! starts it.
    "!
    "! @parameter i_parameters | UUIDs, process names, ignore retry scheduling.
    "! @raising   cx_bgmc      | bgPF could not be scheduled.
    METHODS process_asynchronously_bgpf IMPORTING i_parameters TYPE zif_prc_processing_engine=>tt_parameters OPTIONAL
                                        RAISING   cx_bgmc.

    "! Schedules the processing as application job. No COMMIT: the job becomes
    "! visible with the commit of the caller's LUW.
    "!
    "! @parameter i_parameters | UUIDs, process names, ignore retry scheduling.
    "! @raising   cx_apj_rt    | The job could not be scheduled.
    METHODS process_asynchronously_job  IMPORTING i_parameters TYPE zif_prc_processing_engine=>tt_parameters OPTIONAL
                                        RAISING   cx_apj_rt.

    "! Creates processed objects in their start state, without processing them.
    "! No COMMIT: the caller's LUW saves them; the retry job processes them.
    "!
    "! @parameter i_objects | Objects to create.
    METHODS create IMPORTING i_objects TYPE tt_create_processed_objects.

    "! Creates processed objects, commits and processes them in this session.
    "! Processing needs the committed objects (every step runs in its own session),
    "! so this method commits - do not call it inside a foreign LUW (e.g. a RAP save).
    "!
    "! @parameter i_objects | Objects to create.
    METHODS create_and_process IMPORTING i_objects TYPE tt_create_processed_objects.

    "! Creates processed objects and schedules their processing via bgPF. No COMMIT:
    "! the commit of the caller's LUW saves the objects and starts bgPF.
    "!
    "! @parameter i_objects | Objects to create.
    "! @raising   cx_bgmc   | bgPF could not be scheduled; the objects are written, not committed.
    METHODS create_and_schedule_bgpf IMPORTING i_objects TYPE tt_create_processed_objects
                                     RAISING   cx_bgmc.

    "! Creates processed objects and schedules their processing as application job.
    "! No COMMIT: the commit of the caller's LUW saves the objects and releases the job.
    "!
    "! @parameter i_objects | Objects to create.
    "! @raising   cx_apj_rt | The job could not be scheduled; the objects are written, not committed.
    METHODS create_and_schedule_job IMPORTING i_objects TYPE tt_create_processed_objects
                                    RAISING   cx_apj_rt.

    "! Deprecated - use CREATE, CREATE_AND_PROCESS, CREATE_AND_SCHEDULE_BGPF or
    "! CREATE_AND_SCHEDULE_JOB. Will be removed in a later release.
    "! <br/>
    "! Creates processed objects in their start state and triggers their processing.
    "! Scheduling errors are ignored: the objects stay due for the retry job.
    "!
    "! @parameter i_create_processed_objects | Objects to create.
    "! @parameter i_perform_commit           | COMMIT WORK after creating.
    "! @parameter i_trigger_processing       | How to process the created objects.
    METHODS create_processed_objects IMPORTING i_create_processed_objects TYPE tt_create_processed_objects
                                               i_perform_commit           TYPE abap_bool         DEFAULT abap_false
                                               i_trigger_processing       TYPE ty_execution_mode DEFAULT ''.
  PRIVATE SECTION.
    CLASS-DATA g_instance TYPE REF TO zcl_prc_processing_api.

    "! Writes the objects (no commit) and returns the selection of exactly these objects
    METHODS write IMPORTING i_objects           TYPE tt_create_processed_objects
                  RETURNING VALUE(r_parameters) TYPE zif_prc_processing_engine=>tt_parameters.
ENDCLASS.


CLASS zcl_prc_processing_api IMPLEMENTATION.

  METHOD process_asynchronously_bgpf.
    zcl_prc_bgpf_scheduler=>get( )->schedule( i_parameters ).
  ENDMETHOD.

  METHOD process_asynchronously_job.
    " The engine parameters are a flat list; the job API wants one entry per parameter name
    DATA job_parameters TYPE cl_apj_rt_api=>tt_job_parameter_value.

    LOOP AT i_parameters INTO FINAL(parameter).
      READ TABLE job_parameters WITH KEY name COMPONENTS name = parameter-selname ASSIGNING FIELD-SYMBOL(<job_parameter>).
      IF sy-subrc <> 0.
        APPEND VALUE #( name = parameter-selname ) TO job_parameters ASSIGNING <job_parameter>.
      ENDIF.
      APPEND VALUE #( sign   = parameter-sign
                      option = parameter-option
                      low    = parameter-low
                      high   = parameter-high ) TO <job_parameter>-t_value.
    ENDLOOP.

    zcl_prc_job_scheduler=>get( )->schedule_immediately( i_template_name = zcl_prc_retry_job=>co_apj_template_name
                                                         i_job_text      = |ABAP-PRC: Trigger processing asynch via APJ|
                                                         i_parameters    = job_parameters ).
  ENDMETHOD.

  METHOD process_synchronously.
    zcl_prc_processing_engine=>get_instance( )->execute_synchronously( i_parameters ).
  ENDMETHOD.

  METHOD get_instance.
    IF g_instance IS NOT BOUND.
      g_instance = NEW #( ).
    ENDIF.
    r_instance = g_instance.
  ENDMETHOD.


  METHOD create.
    write( i_objects ).
  ENDMETHOD.


  METHOD create_and_process.
    DATA(parameters) = write( i_objects ).
    IF parameters IS INITIAL.
      RETURN.
    ENDIF.
    COMMIT WORK.
    process_synchronously( parameters ).
  ENDMETHOD.


  METHOD create_and_schedule_bgpf.
    DATA(parameters) = write( i_objects ).
    IF parameters IS NOT INITIAL.
      process_asynchronously_bgpf( parameters ).
    ENDIF.
  ENDMETHOD.


  METHOD create_and_schedule_job.
    DATA(parameters) = write( i_objects ).
    IF parameters IS NOT INITIAL.
      process_asynchronously_job( parameters ).
    ENDIF.
  ENDMETHOD.


  METHOD write.
    CHECK i_objects IS NOT INITIAL.

    DATA(objects) = VALUE zif_prc_db_writer=>ty_create-processedobject(
        FOR k IN i_objects
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

    r_parameters = VALUE #( FOR o IN objects
                            ( selname = zcl_prc_retry_job=>co_parameter-uuid sign = 'I' option = 'EQ' low = o-UUID ) ).
  ENDMETHOD.


  METHOD create_processed_objects.
    CHECK i_create_processed_objects IS NOT INITIAL.

    DATA(parameters) = write( i_create_processed_objects ).

    IF i_perform_commit = abap_true.
      COMMIT WORK.
    ENDIF.

    CASE i_trigger_processing.
      WHEN execution_mode-no_execution.
        " do nothing
      WHEN execution_mode-direct_execution.
        process_synchronously( parameters ).
      WHEN execution_mode-bgpf_execution.
        TRY.
            process_asynchronously_bgpf( parameters ).
          CATCH cx_bgmc ##NO_HANDLER.
            " Behaviour of this deprecated method: the objects stay due, the retry job processes them
        ENDTRY.
      WHEN execution_mode-appl_job_execution.
        TRY.
            process_asynchronously_job( parameters ).
          CATCH cx_apj_rt ##NO_HANDLER.
            " Behaviour of this deprecated method: the objects stay due, the retry job processes them
        ENDTRY.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
