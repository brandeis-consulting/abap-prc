"! <p class="shorttext synchronized">ABAP-PRC: Step layer 8 - isolation</p>
"!
"! Runs every step in a session of its own (CL_ABAP_PARALLEL, local server), so
"! an abort of that session - dump, syntax error, update error, MESSAGE x - is
"! written as a failed step instead of ending the whole run. A fresh session
"! also discards every session-local state: static attributes, function group
"! globals, BAPI buffers, the RAP transactional buffer.
"!
"! Only data crosses the session boundary. The messages of the aborted session
"! are lost. The header of the failed step is written for the end user:
"! <ul>
"! <li>with a short dump: ZPRC_PROCESS_MESSAGE/018 (program error), followed by
"! the technical abort text (011) and the short dump (013, 014) as information</li>
"! <li>without a short dump (MESSAGE A/E): 019 with the text of the original
"! message; without a dump finder (BTP) also where to look (012)</li>
"! </ul>
"! The short dump is found exactly through the EPP transaction ID the step
"! session registered under the marker of the step. The transition is not
"! handed out, it lives in the other session.
CLASS zcl_prc_step_8_isolation DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_prc_processing_step.

    "! @parameter i_step_writer | Writes the failed step after an abort.
    METHODS constructor IMPORTING i_step_writer TYPE REF TO zcl_prc_step_writer.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mo_step_writer TYPE REF TO zcl_prc_step_writer.
    DATA mo_dump_finder TYPE REF TO zif_prc_dump_finder.

    "! Writes the failed step of an aborted session in a LUW of this session.
    "!
    "! @parameter i_state           | State before the step.
    "! @parameter i_abort_message   | Abort text delivered by CL_ABAP_PARALLEL.
    "! @parameter i_marker          | Marker of the step session.
    "! @parameter i_started_at      | Start of the step, to find the short dump.
    "! @parameter i_message_handler | Handler of this session.
    "! @parameter r_state           | State as written.
    METHODS write_abort IMPORTING i_state           TYPE zif_prc_processing_engine=>ty_state
                                  i_abort_message   TYPE string
                                  i_marker          TYPE sysuuid_x16
                                  i_started_at      TYPE timestampl
                                  i_message_handler TYPE REF TO zif_prc_message_handler
                        RETURNING VALUE(r_state)    TYPE zif_prc_processing_engine=>ty_state.

    "! Adds the abort messages: header for the end user, details as information.
    "!
    "! @parameter i_abort_message   | Abort text delivered by CL_ABAP_PARALLEL.
    "! @parameter i_marker          | Marker of the step session.
    "! @parameter i_started_at      | Start of the step, to find the short dump.
    "! @parameter i_message_handler | Handler of this session.
    METHODS add_abort_messages IMPORTING i_abort_message   TYPE string
                                         i_marker          TYPE sysuuid_x16
                                         i_started_at      TYPE timestampl
                                         i_message_handler TYPE REF TO zif_prc_message_handler
                               RAISING   zcx_prc_unit_of_work_failed.

    "! Adds the short dump of the step session (013, 014).
    "!
    "! @parameter i_dump            | The short dump.
    "! @parameter i_message_handler | Handler of this session.
    METHODS add_dump_messages IMPORTING i_dump            TYPE zif_prc_dump_finder=>ty_dump
                                        i_message_handler TYPE REF TO zif_prc_message_handler
                              RAISING   zcx_prc_unit_of_work_failed.
ENDCLASS.



CLASS zcl_prc_step_8_isolation IMPLEMENTATION.

  METHOD constructor.
    mo_step_writer = i_step_writer.
    mo_dump_finder = zcl_prc_step_factory=>create_dump_finder( ).
  ENDMETHOD.


  METHOD zif_prc_processing_step~execute.
    CLEAR e_transition.
    DATA started_at TYPE timestampl.
    GET TIME STAMP FIELD started_at.
    DATA(marker) = xco_cp=>uuid( )->value.

    " Local server: the step session registers itself in the shared buffer of this server
    DATA(parallel) = NEW cl_abap_parallel( p_num_tasks    = 1
                                           p_local_server = abap_true ).
    parallel->run_inst( EXPORTING p_in_tab  = VALUE #( ( NEW zcl_prc_step_8_isolation_task( i_state  = i_state
                                                                                            i_marker = marker ) ) )
                        IMPORTING p_out_tab = DATA(results) ).

    DATA(result) = VALUE #( results[ 1 ] OPTIONAL ).
    IF result-message IS INITIAL AND result-inst IS BOUND.
      IF mo_dump_finder IS BOUND.
        mo_dump_finder->forget( marker ).
      ENDIF.
      r_state = CAST zcl_prc_step_8_isolation_task( result-inst )->get_result( ).
      RETURN.
    ENDIF.

    r_state = write_abort( i_state           = i_state
                           i_abort_message   = result-message
                           i_marker          = marker
                           i_started_at      = started_at
                           i_message_handler = i_message_handler ).
  ENDMETHOD.


  METHOD write_abort.
    TRY.
        add_abort_messages( i_abort_message   = i_abort_message
                            i_marker          = i_marker
                            i_started_at      = i_started_at
                            i_message_handler = i_message_handler ).
      CATCH zcx_prc_unit_of_work_failed ##NO_HANDLER.
        " Cannot happen with i_fail_on_error_message = abap_false
    ENDTRY.

    " The state before the step, only the retry data change
    r_state = mo_step_writer->write( i_start_state     = i_state-State
                                     i_state           = mo_step_writer->with_next_retry( i_state )
                                     i_header          = i_message_handler->get_header( )
                                     i_message_handler = i_message_handler ).
    " No RAP buffer here, so COMMIT ENTITIES alone would not commit the step written by SQL
    COMMIT ENTITIES.
    COMMIT WORK.
  ENDMETHOD.


  METHOD add_abort_messages.
    " The abort text, up to 200 characters, spread over the four variables
    DATA text TYPE c LENGTH 200.
    text = COND string( WHEN i_abort_message IS NOT INITIAL THEN i_abort_message ELSE `no message` ).

    " Searched first: the header depends on whether there is a short dump
    DATA(dump) = COND zif_prc_dump_finder=>ty_dump( WHEN mo_dump_finder IS BOUND
                                                    THEN mo_dump_finder->find_dump( i_marker = i_marker
                                                                                    i_from   = i_started_at ) ).

    " Recorded without failing the handler: the failure is decided here.
    " The only error message becomes the header of the step.
    IF dump IS NOT INITIAL.
      " Program error: the header speaks to the end user, the details to the administrator
      MESSAGE e018(zprc_process_message) INTO DATA(message) ##NEEDED.
      i_message_handler->add_message_from_sy( i_fail_on_error_message = abap_false ).
      MESSAGE i011(zprc_process_message) WITH text+0(50) text+50(50) text+100(50) text+150(50)
              INTO message.
      i_message_handler->add_message_from_sy( i_fail_on_error_message = abap_false ).
      add_dump_messages( i_dump            = dump
                         i_message_handler = i_message_handler ).
      RETURN.
    ENDIF.

    " MESSAGE A/E abort the session without a short dump: the abort text is the original message
    MESSAGE e019(zprc_process_message) WITH text+0(50) text+50(50) text+100(50) text+150(50)
            INTO message.
    i_message_handler->add_message_from_sy( i_fail_on_error_message = abap_false ).

    IF mo_dump_finder IS NOT BOUND.
      " No dump finder (BTP): whether there is a short dump is unknown, so where to look
      MESSAGE i012(zprc_process_message) WITH cl_abap_context_info=>get_user_technical_name( )
                                              |{ i_started_at TIMESTAMP = ISO }|
              INTO message.
      i_message_handler->add_message_from_sy( i_fail_on_error_message = abap_false ).
    ENDIF.
  ENDMETHOD.


  METHOD add_dump_messages.
    MESSAGE i013(zprc_process_message) WITH i_dump-runtime_error i_dump-program INTO DATA(message) ##NEEDED.
    i_message_handler->add_message_from_sy( i_fail_on_error_message = abap_false ).

    DATA short_text TYPE c LENGTH 200.
    short_text = i_dump-short_text.
    MESSAGE i014(zprc_process_message) WITH short_text+0(50) short_text+50(50) short_text+100(50) short_text+150(50)
            INTO message.
    i_message_handler->add_message_from_sy( i_fail_on_error_message = abap_false ).
  ENDMETHOD.

ENDCLASS.
