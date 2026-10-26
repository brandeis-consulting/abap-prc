"! <p class="shorttext synchronized">ABAP-PRC: Step layer 3 - write result</p>
"!
"! Decides what is persisted after a successful transition: new state, payload,
"! retry reset, the step and all messages of the handler. The step header is
"! the success message of the transition, read on the fly; it is added to the
"! messages of the step as well. Writes within the running LUW, the commit is
"! the next layer.
CLASS zcl_prc_step_3_result DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_prc_processing_step.

    METHODS constructor IMPORTING i_inner       TYPE REF TO zif_prc_processing_step
                                  i_step_writer TYPE REF TO zcl_prc_step_writer.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mo_inner       TYPE REF TO zif_prc_processing_step.
    DATA mo_step_writer TYPE REF TO zcl_prc_step_writer.

    "! Success message of the transition, added to the handler as well; the
    "! header of the handler if the transition declares none.
    METHODS get_success_header IMPORTING i_transition      TYPE REF TO zif_prc_transition_handler
                                         i_message_handler TYPE REF TO zif_prc_message_handler
                               RETURNING VALUE(r_header)   TYPE zif_prc_message_handler=>ty_message_details.
ENDCLASS.



CLASS zcl_prc_step_3_result IMPLEMENTATION.

  METHOD constructor.
    mo_inner       = i_inner.
    mo_step_writer = i_step_writer.
  ENDMETHOD.


  METHOD zif_prc_processing_step~execute.
    r_state = mo_inner->execute( EXPORTING i_state           = i_state
                                           i_message_handler = i_message_handler
                                 IMPORTING e_transition      = e_transition ).

    DATA(header) = get_success_header( i_transition      = e_transition
                                       i_message_handler = i_message_handler ).

    r_state = mo_step_writer->write( i_start_state     = i_state-State
                                     i_state           = VALUE #( BASE r_state
                                                                  RetryCount    = 0
                                                                  RetryDateTime = 0 )
                                     i_header          = header
                                     i_message_handler = i_message_handler ).
  ENDMETHOD.


  METHOD get_success_header.
    DATA(message) = COND symsg( WHEN i_transition IS BOUND THEN i_transition->get_success_message( ) ).
    IF message IS INITIAL.
      r_header = i_message_handler->get_header( ).
      RETURN.
    ENDIF.

    " Into the messages of the step as well - the header is set explicitly below,
    " so an error message reported without failing does not take its place
    MESSAGE ID message-msgid TYPE 'S' NUMBER message-msgno
            WITH message-msgv1 message-msgv2 message-msgv3 message-msgv4
            INTO DATA(text) ##NEEDED.
    TRY.
        i_message_handler->add_message_from_sy( i_fail_on_error_message = abap_false ).
      CATCH zcx_prc_unit_of_work_failed ##NO_HANDLER.
        " Cannot happen for a success message
    ENDTRY.

    r_header = CORRESPONDING #( message ).
    r_header-msgty = 'S'.
    MESSAGE ID r_header-msgid TYPE r_header-msgty NUMBER r_header-msgno
            WITH r_header-msgv1 r_header-msgv2 r_header-msgv3 r_header-msgv4
            INTO r_header-message_text.
  ENDMETHOD.

ENDCLASS.

