"! <p class="shorttext synchronized">Collects messages and decides on failure</p>
"!
"! One fresh instance per step. A transition feeds every operation into the
"! handler right after it ran; the handler collects the messages and decides
"! whether the step has failed. It never commits, rolls back, simulates or
"! logs - that is done by the layers of the processing engine.
"!
"! <h2>Typical use in a transition</h2>
"! <ul>
"! <li>EML: ADD_EML_MODIFY_RESULT with FAILED and REPORTED</li>
"! <li>BAPI: ADD_BAPI_RESULT with the return table</li>
"! <li>Own messages and own decision to fail: MESSAGE e... INTO DATA(dummy),
"!     then ADD_MESSAGE_FROM_SY</li>
"! <li>Caught exceptions: ADD_EXCEPTION</li>
"! <li>Texts without message class: ADD_MESSAGE_FROM_TEXT (not translatable)</li>
"! </ul>
"!
"! <h2>Failure</h2>
"! Any failure raises ZCX_PRC_UNIT_OF_WORK_FAILED immediately - a pure signal
"! without data; the details are in the handler. So no state has to be queried
"! in between. I_FAIL_ON_ERROR_MESSAGE decides whether an error message fails
"! the step: TRUE by default, FALSE for EML (there FAILED is the signal and
"! always fails).
"!
"! <h2>Severities</h2>
"! W, I and S are kept. Every other severity (E, A, X, blank) is an error and
"! stored as E.
"!
"! <h2>Header</h2>
"! The last message of the highest severity E > S > W > I. The engine may put
"! its own header on top: the success message of the transition, or its
"! failure message. A failure without any error message adds
"! ZPRC_PROCESS_MESSAGE/002.
INTERFACE zif_prc_message_handler PUBLIC.

  " A collected message: message key and variables plus the text,
  " resolved in the logon language of the processing user
  TYPES: BEGIN OF ty_message_details,
           message_text TYPE string.
           INCLUDE TYPE symsg.
  TYPES: END OF ty_message_details.

  TYPES tt_messages TYPE STANDARD TABLE OF ty_message_details WITH DEFAULT KEY.

  TYPES tt_bapiret2  TYPE STANDARD TABLE OF bapiret2 WITH DEFAULT KEY.

  "! Adds a message that exists as plain text only.
  "!
  "! For texts without a message class behind them - e.g. the return value of
  "! a library that carries no T100 key. Prefer a real message class whenever
  "! one exists: the text is stored as SY 499 spread across the message
  "! variables, so it is <em>not</em> translatable and not in the where-used
  "! list of any message. Roughly 200 characters survive.
  "!
  "! @parameter i_message_text              | Text to be recorded.
  "! @parameter i_message_severity          | Message type of the text.
  "! @parameter i_fail_on_error_message     | ABAP_TRUE (default) lets an error fail the step.
  "! @parameter r_message_handler           | Self reference for chaining.
  "! @raising   zcx_prc_unit_of_work_failed | The text failed the step.
  METHODS add_message_from_text IMPORTING i_message_text           TYPE string
                                          i_message_severity       TYPE symsgty
                                          i_fail_on_error_message  TYPE abap_bool DEFAULT abap_true
                                RETURNING VALUE(r_message_handler) TYPE REF TO zif_prc_message_handler
                                RAISING   zcx_prc_unit_of_work_failed.

  "! Adds the message currently in SY.
  "!
  "! Call it directly after MESSAGE ... INTO DATA(dummy) - any method call in
  "! between may overwrite SY. Keeps the message in the where-used list.
  "!
  "! A transition that decides on its own that it failed issues MESSAGE e...
  "! and calls this method: the message fails the step and becomes the header.
  "!
  "! @parameter i_fail_on_error_message     | ABAP_TRUE (default) lets an error fail the step.
  "! @parameter r_message_handler           | Self reference for chaining.
  "! @raising   zcx_prc_unit_of_work_failed | The message failed the step.
  METHODS add_message_from_sy IMPORTING i_fail_on_error_message  TYPE abap_bool DEFAULT abap_true
                              RETURNING VALUE(r_message_handler) TYPE REF TO zif_prc_message_handler
                              RAISING   zcx_prc_unit_of_work_failed.

  "! Adds the response of an EML statement.
  "!
  "! Accepts both the BO specific response structures of MODIFY ENTITIES and the
  "! generic ABP_BEHV_RESPONSE_TAB of the dynamic form. Messages of all entities
  "! including %OTHER are collected.
  "!
  "! A non-initial FAILED always fails the step - the contractual failure signal
  "! of a RAP BO, it cannot be switched off.
  "!
  "! @parameter i_failed                    | FAILED response; evaluated if supplied.
  "! @parameter i_reported                  | REPORTED response; evaluated if supplied.
  "! @parameter i_fail_on_error_message     | ABAP_TRUE also lets errors in REPORTED fail the
  "!                                        step. Default FALSE: RAP BOs legitimately report
  "!                                        E without FAILED (state messages, other instances).
  "! @parameter r_message_handler           | Self reference for chaining.
  "! @raising   zcx_prc_unit_of_work_failed | The operation failed.
  METHODS add_EML_modify_result IMPORTING i_failed                 TYPE any       OPTIONAL
                                          i_reported               TYPE any       OPTIONAL
                                          i_fail_on_error_message  TYPE abap_bool DEFAULT abap_false
                                RETURNING VALUE(r_message_handler) TYPE REF TO zif_prc_message_handler
                                RAISING   zcx_prc_unit_of_work_failed.

  "! Adds the return table of a BAPI call.
  "!
  "! A BAPI has no FAILED, so the severity is the only failure signal. A line
  "! without type counts as error.
  "!
  "! @parameter i_bapiret                   | Return table of the BAPI.
  "! @parameter i_fail_on_error_message     | ABAP_TRUE (default) lets an error fail the step.
  "! @parameter r_message_handler           | Self reference for chaining.
  "! @raising   zcx_prc_unit_of_work_failed | The BAPI reported an error.
  METHODS add_bapi_result IMPORTING i_bapiret                TYPE zif_prc_message_handler=>tt_bapiret2
                                    i_fail_on_error_message  TYPE abap_bool DEFAULT abap_true
                          RETURNING VALUE(r_message_handler) TYPE REF TO zif_prc_message_handler
                          RAISING   zcx_prc_unit_of_work_failed.

  "! Adds an exception including its PREVIOUS chain.
  "!
  "! The innermost cause comes first, the exception itself last - so the outer
  "! exception, usually the most meaningful one, becomes the header among the
  "! errors. Exceptions with a T100 key (IF_T100_MESSAGE) keep it and stay
  "! translatable; all others are stored as SY 499 with GET_TEXT( ).
  "!
  "! Severity: from IF_T100_DYN_MSG or IF_ABAP_BEHV_MESSAGE if the exception
  "! carries one, otherwise E.
  "!
  "! @parameter i_exception                 | Exception to be recorded.
  "! @parameter i_fail_on_error_message     | ABAP_TRUE (default) lets an error fail the step.
  "! @parameter r_message_handler           | Self reference for chaining.
  "! @raising   zcx_prc_unit_of_work_failed | The exception failed the step.
  METHODS add_exception IMPORTING i_exception              TYPE REF TO cx_root
                                  i_fail_on_error_message  TYPE abap_bool DEFAULT abap_true
                        RETURNING VALUE(r_message_handler) TYPE REF TO zif_prc_message_handler
                        RAISING   zcx_prc_unit_of_work_failed.

  "! Returns whether the step has failed.
  "!
  "! Reflects the failure decision, not the presence of error messages - an E
  "! added with I_FAIL_ON_ERROR_MESSAGE = FALSE does not set it.
  "!
  "! @parameter r_has_errors | ABAP_TRUE if an operation failed the step.
  METHODS has_errors RETURNING VALUE(r_has_errors) TYPE abap_bool.

  "! Returns the header of the collected messages: the last message of the
  "! highest severity E > S > W > I.
  "!
  "! @parameter r_message | Header message; initial if there are no messages.
  METHODS get_header RETURNING VALUE(r_message) TYPE ty_message_details.

  "! Returns all collected messages in order of arrival.
  "!
  "! @parameter r_messages | Collected messages.
  METHODS get_messages RETURNING VALUE(r_messages) TYPE tt_messages.

ENDINTERFACE.
