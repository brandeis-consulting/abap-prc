"! <p class="shorttext synchronized">ABAP-PRC: Step header</p>
"!
"! The one place where the header of a step is chosen. Used by the layers
"! that write a step (3-Result, 5-Expected, 6-Unexpected, 8-Isolation) and by
"! ZCL_PRC_TRANSITION_HANDLR_TEST, so unit tests check exactly this rule.
"!
"! <ul>
"! <li>Success: the success message of the transition with its type S, I or
"!     W, by default ZPRC_PROCESS_MESSAGE/017. Another type is a program
"!     error: the step fails with ZPRC_PROCESS_MESSAGE/023.</li>
"! <li>Failure: the failure message of the transition, added as the last
"!     error; else the last error of the step; without any error
"!     ZPRC_PROCESS_MESSAGE/002.</li>
"! <li>Findings: the last error of the step. Findings are no failure, so the
"!     failure message of the transition is not used.</li>
"! </ul>
"! The success header is not added to the message handler: the step writer
"! persists it with the commit of the step only. The failure and the
"! findings header are messages of the handler.
CLASS zcl_prc_step_header DEFINITION PUBLIC FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    "! Header of a successful step.
    "!
    "! @parameter i_transition              | Transition of the step.
    "! @parameter i_message_handler         | Handler of the step; receives 023 on a program error.
    "! @parameter r_header                  | Step header.
    "! @raising   zcx_prc_unit_of_work_failed | The success message has a type other than S, I or W.
    CLASS-METHODS for_success IMPORTING i_transition      TYPE REF TO zif_prc_transition_handler
                                        i_message_handler TYPE REF TO zif_prc_message_handler
                              RETURNING VALUE(r_header)   TYPE zif_prc_message_handler=>ty_message_details
                              RAISING   zcx_prc_unit_of_work_failed.

    "! Header of a failed step. Adds the failure message, or 002 if the step
    "! has no error at all, to the handler without failing it again.
    "!
    "! @parameter i_message_handler | Handler of the step.
    "! @parameter i_failure_message | Failure message of the transition; initial if none.
    "! @parameter r_header          | Step header, one of the messages of the handler.
    CLASS-METHODS for_failure IMPORTING i_message_handler TYPE REF TO zif_prc_message_handler
                                        i_failure_message TYPE symsg OPTIONAL
                              RETURNING VALUE(r_header)   TYPE zif_prc_message_handler=>ty_message_details.

    "! Header of a step with findings (errors added with I_FAIL_STEP = ABAP_FALSE):
    "! the last error. Adds nothing to the handler.
    "!
    "! @parameter i_message_handler | Handler of the step; contains at least one error.
    "! @parameter r_header          | Step header, one of the messages of the handler.
    CLASS-METHODS for_findings IMPORTING i_message_handler TYPE REF TO zif_prc_message_handler
                               RETURNING VALUE(r_header)   TYPE zif_prc_message_handler=>ty_message_details.

  PRIVATE SECTION.
    "! The last error among the messages; initial if there is none.
    CLASS-METHODS last_error IMPORTING i_messages      TYPE zif_prc_message_handler=>tt_messages
                             RETURNING VALUE(r_header) TYPE zif_prc_message_handler=>ty_message_details.
ENDCLASS.



CLASS zcl_prc_step_header IMPLEMENTATION.

  METHOD for_success.
    DATA message TYPE symsg.
    IF i_transition IS BOUND.
      message = i_transition->get_success_message( ).
    ENDIF.
    IF message IS INITIAL.
      MESSAGE s017(zprc_process_message) INTO DATA(default_text) ##NEEDED.
      message = VALUE #( msgty = sy-msgty
                         msgid = sy-msgid
                         msgno = sy-msgno ).
    ENDIF.

    IF message-msgty <> 'S' AND message-msgty <> 'I' AND message-msgty <> 'W'.
      " Program error: a success message is never an error - the step fails
      MESSAGE e023(zprc_process_message) WITH message-msgid message-msgno message-msgty
              INTO DATA(error_text) ##NEEDED.
      i_message_handler->add_message_from_sy( ).
    ENDIF.

    r_header = CORRESPONDING #( message ).
    MESSAGE ID r_header-msgid TYPE r_header-msgty NUMBER r_header-msgno
            WITH r_header-msgv1 r_header-msgv2 r_header-msgv3 r_header-msgv4
            INTO r_header-message_text.
  ENDMETHOD.


  METHOD for_failure.
    DATA(handler) = CAST zcl_prc_message_handler( i_message_handler ).

    " The failure message states the intent of the transition: as the last error it is the header
    IF i_failure_message IS NOT INITIAL.
      DATA(failure) = i_failure_message.
      failure-msgty = 'E'.
      handler->add_message_without_failing( failure ).
    ENDIF.

    " A failed step always has an error as header
    DATA(messages) = i_message_handler->get_messages( ).
    IF NOT line_exists( messages[ msgty = 'E' ] ).
      MESSAGE e002(zprc_process_message) INTO DATA(missing_error) ##NEEDED.
      handler->add_message_without_failing( VALUE #( msgty = sy-msgty
                                                     msgid = sy-msgid
                                                     msgno = sy-msgno ) ).
      messages = i_message_handler->get_messages( ).
    ENDIF.

    r_header = last_error( messages ).
  ENDMETHOD.


  METHOD for_findings.
    r_header = last_error( i_message_handler->get_messages( ) ).
  ENDMETHOD.


  METHOD last_error.
    LOOP AT i_messages INTO DATA(message) WHERE msgty = 'E'.
      r_header = message.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
