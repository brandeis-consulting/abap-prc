"! <p class="shorttext synchronized">ABAP-PRC: Finds the short dump of an aborted step</p>
"!
"! Standard ABAP, released (C1), created dynamically by the processing engine
"! via ZIF_PRC_DUMP_FINDER=>CO_IMPLEMENTATION.
"!
"! The step session stores its Extended Passport identity in the shared buffer
"! of the application server; the isolation layer runs the step session on the
"! local server, so it finds the entry there. Every short dump of the session -
"! also one in the local update task - carries the same identity.
"!
"! The EPP transaction ID is inherited from the caller, so all step sessions of
"! one run share it: it only preselects the dumps (CL_RUNTIME_ERROR has no
"! filter for the connection). The EPP connection ID and counter identify the
"! step session exactly.
CLASS zcl_prc_dump_finder DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_prc_dump_finder.

  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES: BEGIN OF ty_session,
             transaction_id     TYPE string,
             connection_id      TYPE string,
             connection_counter TYPE string,
           END OF ty_session.

    "! Key of the shared buffer entry: the marker in its 22 character form.
    METHODS buffer_id IMPORTING i_marker    TYPE sysuuid_x16
                      RETURNING VALUE(r_id) TYPE indx_srtfd.

    "! The dump of exactly this session among the dumps of its transaction.
    METHODS select_dump IMPORTING i_session     TYPE ty_session
                                  i_from        TYPE timestampl
                        RETURNING VALUE(r_dump) TYPE REF TO cl_runtime_error
                        RAISING   cx_runtime_error_exc_auth
                                  cx_parameter_invalid_range.
ENDCLASS.



CLASS zcl_prc_dump_finder IMPLEMENTATION.

  METHOD zif_prc_dump_finder~register_session.
    DATA session TYPE ty_session.
    TRY.
        DATA(section) = cl_epp_global_factory=>get_section( ).
        session = VALUE #( transaction_id     = section->get_transaction_id( )
                           connection_id      = section->get_connection_id_as_uuid( )
                           connection_counter = section->get_connection_counter( ) ).
      CATCH cx_epp_error.
        RETURN.
    ENDTRY.

    " Survives an abort of this session
    DATA(id) = buffer_id( i_marker ).
    EXPORT session = session TO SHARED BUFFER indx(zp) ID id.
  ENDMETHOD.


  METHOD zif_prc_dump_finder~forget.
    DATA(id) = buffer_id( i_marker ).
    DELETE FROM SHARED BUFFER indx(zp) ID id.
  ENDMETHOD.


  METHOD zif_prc_dump_finder~find_dump.
    DATA session TYPE ty_session.
    DATA(id) = buffer_id( i_marker ).
    IMPORT session = session FROM SHARED BUFFER indx(zp) ID id.
    DELETE FROM SHARED BUFFER indx(zp) ID id.
    IF session-transaction_id IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        DATA(dump) = select_dump( i_session = session
                                  i_from    = i_from ).
        IF dump IS NOT BOUND.
          RETURN.
        ENDIF.

        " The error analysis names the actual cause, e.g. the text of a MESSAGE X;
        " the short description is generic
        dump->get_error_analysis_text( IMPORTING p_text = DATA(analysis) ).
        dump->get_abap_sourceinfo( IMPORTING p_e_mainprogram = DATA(program) ).

        r_dump = VALUE #( runtime_error = dump->get_errid( )
                          program       = COND #( WHEN program IS NOT INITIAL THEN program
                                                  ELSE dump->get_current_program( ) )
                          short_text    = condense( replace( val  = analysis
                                                             sub  = cl_abap_char_utilities=>newline
                                                             with = ` `
                                                             occ  = 0 ) ) ).
      CATCH cx_root ##CATCH_ALL ##NO_HANDLER.
        " No authorization for the dump analysis or no readable dump: the step
        " carries the hint message only
    ENDTRY.
  ENDMETHOD.


  METHOD select_dump.
    " The whole step, with a minute of margin for clock and second rounding
    DATA from TYPE timestamp.
    from = cl_abap_tstmp=>subtractsecs( tstmp = i_from secs = 60 ).
    GET TIME STAMP FIELD DATA(to).

    cl_runtime_error=>select_by_timestamp(
      EXPORTING p_r_timestamps    = VALUE #( ( sign = 'I' option = 'BT' low = from high = to ) )
                p_r_transactionid = VALUE #( ( sign = 'I' option = 'EQ' low = i_session-transaction_id ) )
      IMPORTING p_e_t_snapentries = DATA(keys) ).

    " Newest first; the connection identifies the step session
    SORT keys BY datum DESCENDING uzeit DESCENDING.
    LOOP AT keys INTO DATA(key).
      DATA(candidate) = NEW cl_runtime_error( key = key ).
      candidate->build_field_table( ).
      " CL_RUNTIME_ERROR reads the connection only together with the root context
      candidate->get_transaction_info( IMPORTING p_e_root_context_id    = DATA(root_context) ##NEEDED
                                                 p_e_connection_id      = DATA(connection_id)
                                                 p_e_connection_counter = DATA(connection_counter) ).
      IF     to_upper( condense( CONV string( connection_id ) ) ) = to_upper( condense( i_session-connection_id ) )
         AND condense( CONV string( connection_counter ) )        = condense( i_session-connection_counter ).
        r_dump = candidate.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD buffer_id.
    TRY.
        cl_system_uuid=>convert_uuid_x16_static( EXPORTING uuid     = i_marker
                                                 IMPORTING uuid_c22 = DATA(c22) ).
        r_id = c22.
      CATCH cx_uuid_error.
        r_id = CONV #( i_marker ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.

