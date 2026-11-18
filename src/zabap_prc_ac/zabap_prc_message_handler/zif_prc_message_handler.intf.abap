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
"! An error is a failure: every error message (E, A, X or blank) and a
"! non-initial FAILED of EML fail the step. The handler raises
"! ZCX_PRC_UNIT_OF_WORK_FAILED immediately - a pure signal without data; the
"! details are in the handler. So no state has to be queried in between, and
"! only the handler raises this exception.
"!
"! Several results that belong together - e.g. the return tables of two
"! BAPIs - are merged before they are added, if all their messages are to be
"! kept.
"!
"! <h2>Findings</h2>
"! Every ADD method has I_FAIL_STEP, by default ABAP_TRUE. With ABAP_FALSE an
"! error is a finding, not a failure: it is recorded, nothing is raised and
"! the transition goes on - e.g. a consistency check that collects all its
"! errors and marks them in the application.
"!
"! A transition with findings is a transition back to its start state
"! (X -> X, declared in the process). The step is committed with all changes
"! of the transition, written with the last error as header and with retry
"! data, so the object is erroneous until it is resumed. Any other end state
"! fails the step (ZPRC_PROCESS_MESSAGE/024).
"!
"! <h2>Failed or errors</h2>
"! <ul>
"! <li>HAS_FAILED: the step has failed - an error added with I_FAIL_STEP =
"!     ABAP_TRUE. Within a transition never ABAP_TRUE: the failure has left it
"!     with the exception already.</li>
"! <li>HAS_ERRORS: an error has been collected - a failure or a finding. A
"!     failed step always has errors. Within a transition: there are findings,
"!     so the transition returns its start state.</li>
"! </ul>
"!
"! <h2>Severities</h2>
"! W, I and S are kept. Every other severity (E, A, X, blank) is an error and
"! stored as E.
"!
"! <h2>Step header</h2>
"! The handler collects messages only; the step header is chosen by the
"! engine (ZCL_PRC_STEP_HEADER): on success the success message of the
"! transition, on failure its failure message, else the last error, with
"! findings the last error. Tests read the header from
"! ZCL_PRC_TRANSITION_HANDLR_TEST, never from the handler.
INTERFACE zif_prc_message_handler PUBLIC.

  " A collected message: message key and variables plus the text,
  " resolved in the logon language of the processing user
  TYPES: BEGIN OF ty_message_details,
           message_text TYPE string.
           INCLUDE TYPE symsg.
  TYPES: END OF ty_message_details.

  TYPES tt_messages TYPE STANDARD TABLE OF ty_message_details WITH EMPTY KEY.

  " DEFAULT KEY on purpose: BAPI return tables (BAPIRET2_T and the tables of the
  " callers) have the standard key, and a fully typed parameter needs the same key
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
  "! @parameter i_message_severity          | Message type of the text; an error fails the step.
  "! @parameter i_fail_step                 | ABAP_FALSE: an error is a finding, not a failure.
  "! @parameter r_message_handler           | Self reference for chaining.
  "! @raising   zcx_prc_unit_of_work_failed | The text is an error and I_FAIL_STEP is set.
  METHODS add_message_from_text IMPORTING i_message_text           TYPE string
                                          i_message_severity       TYPE symsgty
                                          i_fail_step              TYPE abap_bool DEFAULT abap_true
                                RETURNING VALUE(r_message_handler) TYPE REF TO zif_prc_message_handler
                                RAISING   zcx_prc_unit_of_work_failed.

  "! Adds the message currently in SY.
  "!
  "! Call it directly after MESSAGE ... INTO DATA(dummy) - any method call in
  "! between may overwrite SY. Keeps the message in the where-used list.
  "!
  "! A transition that decides on its own that it failed issues MESSAGE e...
  "! and calls this method: the message fails the step.
  "!
  "! @parameter i_fail_step                 | ABAP_FALSE: an error is a finding, not a failure.
  "! @parameter r_message_handler           | Self reference for chaining.
  "! @raising   zcx_prc_unit_of_work_failed | The message is an error and I_FAIL_STEP is set.
  METHODS add_message_from_sy IMPORTING i_fail_step              TYPE abap_bool DEFAULT abap_true
                              RETURNING VALUE(r_message_handler) TYPE REF TO zif_prc_message_handler
                              RAISING   zcx_prc_unit_of_work_failed.

  "! Adds the response of an EML statement.
  "!
  "! Accepts both the BO specific response structures of MODIFY ENTITIES and the
  "! generic ABP_BEHV_RESPONSE_TAB of the dynamic form. Messages of all entities
  "! including %OTHER are collected.
  "!
  "! A non-initial FAILED fails the step, and so does an error message in
  "! REPORTED - also without FAILED: an error is an error.
  "!
  "! @parameter i_failed                    | FAILED response; evaluated if supplied.
  "! @parameter i_reported                  | REPORTED response; evaluated if supplied.
  "! @parameter i_fail_step                 | ABAP_FALSE: an error or FAILED is a finding, not a failure.
  "! @parameter r_message_handler           | Self reference for chaining.
  "! @raising   zcx_prc_unit_of_work_failed | The operation failed and I_FAIL_STEP is set.
  METHODS add_EML_modify_result IMPORTING i_failed                 TYPE any OPTIONAL
                                          i_reported               TYPE any OPTIONAL
                                          i_fail_step              TYPE abap_bool DEFAULT abap_true
                                RETURNING VALUE(r_message_handler) TYPE REF TO zif_prc_message_handler
                                RAISING   zcx_prc_unit_of_work_failed.

  "! Adds the return table of a BAPI call.
  "!
  "! A BAPI has no FAILED, so the severity is the only failure signal. A line
  "! without type counts as error. All lines are added before the step fails.
  "!
  "! @parameter i_bapiret                   | Return table of the BAPI.
  "! @parameter i_fail_step                 | ABAP_FALSE: an error is a finding, not a failure.
  "! @parameter r_message_handler           | Self reference for chaining.
  "! @raising   zcx_prc_unit_of_work_failed | The BAPI reported an error and I_FAIL_STEP is set.
  METHODS add_bapi_result IMPORTING i_bapiret                TYPE zif_prc_message_handler=>tt_bapiret2
                                    i_fail_step              TYPE abap_bool DEFAULT abap_true
                          RETURNING VALUE(r_message_handler) TYPE REF TO zif_prc_message_handler
                          RAISING   zcx_prc_unit_of_work_failed.

  "! Adds an exception including its PREVIOUS chain.
  "!
  "! The innermost cause comes first, the exception itself last - so the outer
  "! exception, usually the most meaningful one, is the last error. Exceptions
  "! with a T100 key (IF_T100_MESSAGE) keep it and stay translatable; all
  "! others are stored as SY 499 with GET_TEXT( ).
  "!
  "! Severity: from IF_T100_DYN_MSG or IF_ABAP_BEHV_MESSAGE if the exception
  "! carries one, otherwise E. An error fails the step.
  "!
  "! @parameter i_exception                 | Exception to be recorded.
  "! @parameter i_fail_step                 | ABAP_FALSE: an error is a finding, not a failure.
  "! @parameter r_message_handler           | Self reference for chaining.
  "! @raising   zcx_prc_unit_of_work_failed | The exception is an error and I_FAIL_STEP is set.
  METHODS add_exception IMPORTING i_exception              TYPE REF TO cx_root
                                  i_fail_step              TYPE abap_bool DEFAULT abap_true
                        RETURNING VALUE(r_message_handler) TYPE REF TO zif_prc_message_handler
                        RAISING   zcx_prc_unit_of_work_failed.

  "! Returns whether the step has failed: an error was added with
  "! I_FAIL_STEP = ABAP_TRUE. Findings do not count.
  "!
  "! @parameter r_has_failed | ABAP_TRUE if an operation failed the step.
  METHODS has_failed RETURNING VALUE(r_has_failed) TYPE abap_bool.

  "! Returns whether an error has been collected - a failure or a finding.
  "! A failed step always has errors.
  "!
  "! @parameter r_has_errors | ABAP_TRUE if at least one message is an error.
  METHODS has_errors RETURNING VALUE(r_has_errors) TYPE abap_bool.

  "! Returns all collected messages in order of arrival.
  "!
  "! @parameter r_messages | Collected messages.
  METHODS get_messages RETURNING VALUE(r_messages) TYPE tt_messages.

ENDINTERFACE.
