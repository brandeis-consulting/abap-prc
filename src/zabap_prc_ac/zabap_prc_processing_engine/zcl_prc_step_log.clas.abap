"! <p class="shorttext synchronized">ABAP-PRC: Step layer - application log</p>
"!
"! Between 9-Event and 8-Isolation, so outside the isolated session: every
"! message of a written step goes into the application log - also the abort
"! messages of 8-Isolation. The messages are read from the step as written,
"! each one with the prefix of the transition handler (default: process /
"! object / start state -> end state).
"!
"! One log per run (external ID: run UUID; without run: process name) and per
"! instance of this layer, i.e. per package. Parallel packages write logs of
"! their own with the same external ID: appending to one log from parallel
"! sessions loses messages silently, since every save rewrites the whole log.
"!
"! Logging never changes the result of a step.
CLASS zcl_prc_step_log DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_prc_processing_step.

    CONSTANTS co_log_object    TYPE cl_bali_header_setter=>ty_object    VALUE 'ZBALI_PRC'.
    CONSTANTS co_log_subobject TYPE cl_bali_header_setter=>ty_subobject VALUE 'PRC_RETRY'.

    "! @parameter i_inner | Step level inside: 8-Isolation.
    METHODS constructor IMPORTING i_inner TYPE REF TO zif_prc_processing_step.

    "! External ID of the log of an object: run UUID, without run the process name.
    "!
    "! @parameter i_state       | Processed object.
    "! @parameter r_external_id | External ID of its log.
    CLASS-METHODS get_external_id IMPORTING i_state              TYPE zif_prc_processing_engine=>ty_state
                                  RETURNING VALUE(r_external_id) TYPE cl_bali_header_setter=>ty_external_id.

  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES: BEGIN OF ty_log,
             external_id TYPE cl_bali_header_setter=>ty_external_id,
             log         TYPE REF TO if_bali_log,
           END OF ty_log.

    DATA mo_inner TYPE REF TO zif_prc_processing_step.
    DATA mt_logs  TYPE HASHED TABLE OF ty_log WITH UNIQUE KEY external_id.

    "! Writes the messages of the step just written into the log of the object.
    METHODS write_step IMPORTING i_before TYPE zif_prc_processing_engine=>ty_state
                                 i_after  TYPE zif_prc_processing_engine=>ty_state
                       RAISING   cx_bali_runtime.

    "! Prefix from the transition handler, otherwise process / object / states.
    METHODS get_prefix IMPORTING i_before        TYPE zif_prc_processing_engine=>ty_state
                                 i_after         TYPE zif_prc_processing_engine=>ty_state
                       RETURNING VALUE(r_prefix) TYPE string.

    "! The log of this package for the external ID of the object; created on first use.
    METHODS get_log IMPORTING i_state      TYPE zif_prc_processing_engine=>ty_state
                    RETURNING VALUE(r_log) TYPE REF TO if_bali_log
                    RAISING   cx_bali_runtime.
ENDCLASS.



CLASS zcl_prc_step_log IMPLEMENTATION.

  METHOD constructor.
    mo_inner = i_inner.
  ENDMETHOD.


  METHOD zif_prc_processing_step~execute.
    r_state = mo_inner->execute( EXPORTING i_state           = i_state
                                           i_message_handler = i_message_handler
                                 IMPORTING e_transition      = e_transition ).

    " Nothing written - no lock, for example - means nothing to log
    IF r_state-LatestStepUUID = i_state-LatestStepUUID.
      RETURN.
    ENDIF.

    TRY.
        write_step( i_before = i_state
                    i_after  = r_state ).
      CATCH cx_root ##CATCH_ALL ##NO_HANDLER.
        " Logging never changes the result of the step
    ENDTRY.
  ENDMETHOD.


  METHOD get_external_id.
    r_external_id = COND #( WHEN i_state-RunUUID IS NOT INITIAL
                            THEN |{ i_state-RunUUID }|
                            ELSE i_state-ProcessName ).
  ENDMETHOD.


  METHOD write_step.
    SELECT FROM zr_prc_processedmessage WITH PRIVILEGED ACCESS
      FIELDS MessageSeverity, MessageText
      WHERE ProcessedStepUUID = @i_after-LatestStepUUID
      ORDER BY CreatedAt, UUID
      INTO TABLE @DATA(messages).
    IF messages IS INITIAL.
      RETURN.
    ENDIF.

    DATA(prefix) = get_prefix( i_before = i_before
                               i_after  = i_after ).
    DATA(log) = get_log( i_after ).

    LOOP AT messages INTO DATA(message).
      DATA text TYPE c LENGTH 200.
      text = |{ prefix } { message-MessageText }|.
      log->add_item( cl_bali_free_text_setter=>create(
                         severity = COND #( WHEN message-MessageSeverity CA 'WIS' THEN message-MessageSeverity
                                            ELSE if_bali_constants=>c_severity_error )
                         text     = text ) ).
    ENDLOOP.

    " Own database connection: independent of the LUW of the run
    cl_bali_log_db=>get_instance( )->save_log_2nd_db_connection( log = log ).
  ENDMETHOD.


  METHOD get_prefix.
    " This layer runs in the main session: loading the process or its handler must not
    " abort it with SYNTAX_ERROR (uncatchable).
    " 1. A step aborted by the step session (header 018/019) may have died on loading the
    "    handler - a handler in a global class of its own is not covered by the loader.
    "    Steps that ran have loaded process and handler already, so loading here is safe.
    SELECT SINGLE MessageClass, MessageNumber
      FROM zr_prc_processedmessage WITH PRIVILEGED ACCESS
      WHERE ProcessedStepUUID = @i_after-LatestStepUUID
        AND IsHeader          = @abap_true
      INTO @DATA(ls_header).
    DATA(lv_aborted) = xsdbool( ls_header-MessageClass = 'ZPRC_PROCESS_MESSAGE'
                                AND ( ls_header-MessageNumber = '018' OR ls_header-MessageNumber = '019' ) ).

    IF lv_aborted = abap_false.
      TRY.
          " 2. Via the loader: syntax error in the process class (or a local handler)
          DATA(process) = zcl_prc_process_loader=>get_process( i_before-FactoryClassName ).
          IF process IS BOUND.
            DATA(transition) = process->get_transition_handler( i_start_state      = i_before-State
                                                                i_processed_object = i_before-ExternalProcessedObjectID ).
            IF transition IS BOUND.
              transition->initialize( i_process_name              = i_before-ProcessName
                                      i_processed_object_ext_id   = i_before-ExternalProcessedObjectID
                                      i_processed_object_ext_uuid = i_before-ExternalProcessedObjectUUID
                                      i_message_handler           = zcl_prc_message_handler=>create_message_handler( ) ).
              DATA(message) = transition->get_message_prefix_for_log( ).
              IF message-msgid IS NOT INITIAL.
                MESSAGE ID message-msgid TYPE 'I' NUMBER message-msgno
                        WITH message-msgv1 message-msgv2 message-msgv3 message-msgv4
                        INTO r_prefix.
                RETURN.
              ENDIF.
            ENDIF.
          ENDIF.
        CATCH cx_root ##CATCH_ALL ##NO_HANDLER.
          " No prefix from the process class: default below
      ENDTRY.
    ENDIF.

    r_prefix = |{ i_after-ProcessName } / { i_after-ExternalProcessedObjectID } / { i_before-State } -> { i_after-State }:|.
  ENDMETHOD.


  METHOD get_log.
    DATA(external_id) = get_external_id( i_state ).
    ASSIGN mt_logs[ external_id = external_id ] TO FIELD-SYMBOL(<log>).
    IF sy-subrc = 0.
      r_log = <log>-log.
      RETURN.
    ENDIF.

    " Same retention as the processed data (cleanup job): the log system deletes it
    DATA(expiry) = CONV d( cl_abap_context_info=>get_system_date( ) + zcl_prc_cleanup_job=>co_default_days ).
    r_log = cl_bali_log=>create_with_header( cl_bali_header_setter=>create( object      = co_log_object
                                                                            subobject   = co_log_subobject
                                                                            external_id = external_id
                                                    )->set_expiry( expiry_date       = expiry
                                                                   keep_until_expiry = abap_true ) ).
    INSERT VALUE #( external_id = external_id
                    log         = r_log ) INTO TABLE mt_logs.
  ENDMETHOD.

ENDCLASS.
