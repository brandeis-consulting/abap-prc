"! <p class="shorttext synchronized">Collects messages and evaluates operation results</p>
"!
"! One instance per unit of work. The handler decides whether an operation has
"! failed; committing and rolling back stay with the transaction owner.
"!
"! Assumes the caller owns the transaction - application jobs, API
"! implementations, reports. Not intended for scenarios in which RAP owns the
"! transaction, such as an OData service behind a Fiori app: there the commit is
"! triggered by the RAP runtime and must not be simulated or issued by hand.
"!
"! Typical sequence:
"! <ol>
"! <li>SET_FAILURE_HEADER - optional, declare the potential failure header message up front</li>
"! <li>ADD_MODIFY_RESULT / ADD_BAPI_RESULT / ADD_MESSAGE_FROM_SY - any number of times</li>
"! <li>SIMULATE_SAVE - once, after the last operation</li>
"! <li>CLOSE_OK - directly after MESSAGE s...</li>
"! </ol>
"!
"! Any failure raises ZCX_PRC_UNIT_OF_WORK_FAILED immediately and seals the
"! handler, so the caller never has to query the state in between asking for has_errors() - which is still provided.
INTERFACE zif_prc_message_handler PUBLIC.

  TYPES: BEGIN OF ty_message_details,
           message_text       TYPE string,
           LOG_message_prefix TYPE string.
           INCLUDE TYPE symsg.
  TYPES: END OF ty_message_details.

  TYPES tt_messages TYPE STANDARD TABLE OF ty_message_details WITH DEFAULT KEY.

  TYPES tt_bapiret2  TYPE STANDARD TABLE OF bapiret2 WITH DEFAULT KEY.
  "! Adds a prefix to messages for logging to better identify the context.
  "!
  "! @parameter i_log_message_prefix |
  METHODS set_log_message_prefix IMPORTING i_log_message_prefix TYPE symsg.

  "! Adds a message that exists as plain text only.
  "!
  "! For texts that have no message class behind them - the return value of an
  "! library that carries no T100 key.
  "!
  "! Prefer a real message class whenever one exists. The text is stored as
  "! SY 499 with the wording spread across the message variables, which means it
  "! is <em>not</em> translatable and cannot be found by the where-used list of
  "! any message. Roughly 200 characters survive; longer texts are truncated.
  "!
  "! Only A, E, W, S and I are meaningful severities here.
  "!
  "! @parameter i_message_text              | Text to be recorded.
  "! @parameter i_message_severity          | Message type of the text.
  "! @parameter i_fail_on_error_message     | ABAP_TRUE lets severity E fail the
  "!                                        handler. Default TRUE, because passing
  "!                                        an error severity is a deliberate
  "!                                        statement by the caller. Severity A
  "!                                        always fails.
  "! @parameter r_message_handler           | Self reference for chaining.
  "! @raising   zcx_prc_unit_of_work_failed | The text failed the unit of work.
  METHODS add_message_from_text IMPORTING i_message_text           TYPE string
                                          i_message_severity       TYPE symsgty
                                          i_fail_on_error_message  TYPE abap_bool DEFAULT abap_true
                                RETURNING VALUE(r_message_handler) TYPE REF TO zif_prc_message_handler
                                RAISING   zcx_prc_unit_of_work_failed.

  "! Declares the header message used if the unit of work fails.
  "!
  "! Pass a prepared SYMSG.
  "! May be called repeatedly to refine the header as more context becomes known.
  "! This method never fails the handler, even though the message is an error.
  "!
  "! @parameter i_header_message  | Header message represented as SY variable values.
  "! @parameter r_message_handler | Self reference for chaining.
  METHODS set_failure_header IMPORTING i_header_message         TYPE symsg
                             RETURNING VALUE(r_message_handler) TYPE REF TO zif_prc_message_handler.

  "! Declares the header message used if the unit of work was successful.
  "!
  "! Pass a prepared SYMSG.
  "!
  "! @parameter i_header_message  | Header message represented as SY variable values.
  "! @parameter r_message_handler | Self reference for chaining.
  METHODS set_success_header IMPORTING i_header_message         TYPE symsg
                             RETURNING VALUE(r_message_handler) TYPE REF TO zif_prc_message_handler.

  "! Adds a message of the caller itself, taken from SY.
  "!
  "! Must be called directly after the MESSAGE statement, since any intervening
  "! method call may overwrite SY.
  "!
  "! @parameter i_fail_on_error_message     | ABAP_TRUE lets severity E fail the handler.
  "!                                      Default TRUE, because an explicit
  "!                                      MESSAGE e... by the caller is a deliberate
  "!                                      statement. Severity A always fails.
  "! @parameter r_message_handler           | Self reference for chaining.
  "! @raising   zcx_prc_unit_of_work_failed | The message failed the unit of work.
  METHODS add_message_from_sy IMPORTING i_fail_on_error_message  TYPE abap_bool DEFAULT abap_true
                              RETURNING VALUE(r_message_handler) TYPE REF TO zif_prc_message_handler
                              RAISING   zcx_prc_unit_of_work_failed.

  "! Adds the response of an EML statement.
  "!
  "! Accepts both the BO specific response structure of MODIFY ENTITIES and the
  "! generic ABP_BEHV_RESPONSE_TAB of the dynamic COMMIT ENTITIES form.
  "! Messages of all entities including %OTHER are collected.
  "!
  "! A non-initial FAILED always fails the handler - this is the contractual
  "! failure signal of a RAP BO and cannot be switched off.
  "!
  "! @parameter i_failed                    | FAILED response. Evaluated if supplied.
  "! @parameter i_reported                  | REPORTED response. Evaluated if supplied.
  "! @parameter i_fail_on_error_message     | ABAP_TRUE also lets severity E in REPORTED
  "!                                      fail the handler. Default FALSE, because RAP
  "!                                      BOs legitimately report E without FAILED
  "!                                      (state messages, messages on other
  "!                                      instances). Set to TRUE only for a BO known
  "!                                      to violate the contract, and document why.
  "! @parameter r_message_handler           | Self reference for chaining.
  "! @raising   zcx_prc_unit_of_work_failed | The operation failed.
  METHODS add_EML_modify_result IMPORTING i_failed                 TYPE any       OPTIONAL
                                          i_reported               TYPE any       OPTIONAL
                                          i_fail_on_error_message  TYPE abap_bool DEFAULT abap_false
                                RETURNING VALUE(r_message_handler) TYPE REF TO zif_prc_message_handler
                                RAISING   zcx_prc_unit_of_work_failed.

  "! Adds the return table of a BAPI call.
  "!
  "! A BAPI has no FAILED equivalent, so severity is the only failure signal here.
  "! Severity A always fails the handler regardless of the parameter.
  "!
  "! @parameter i_bapiret                   | Return table of the BAPI.
  "! @parameter i_fail_on_error_message     | ABAP_TRUE lets severity E fail the handler.
  "!                                      Default TRUE.
  "! @parameter r_message_handler           | Self reference for chaining.
  "! @raising   zcx_prc_unit_of_work_failed | The BAPI reported E or A.
  METHODS add_bapi_result IMPORTING i_bapiret                TYPE zif_prc_message_handler=>tt_bapiret2
                                    i_fail_on_error_message  TYPE abap_bool DEFAULT abap_true
                          RETURNING VALUE(r_message_handler) TYPE REF TO zif_prc_message_handler
                          RAISING   zcx_prc_unit_of_work_failed.

  "! Runs COMMIT ENTITIES IN SIMULATION MODE and evaluates the response.
  "!
  "! Answers "may all of this be saved?" for the entire transactional buffer, not
  "! just for the last operation. Call once, after the last operation.
  "!
  "! Only FINALIZE and CHECK_BEFORE_SAVE are executed; failures in ADJUST_NUMBERS
  "! or SAVE_MODIFIED surface at the real COMMIT ENTITIES only. Doing nothing if
  "! the buffer is empty, it is safe to call even for pure BAPI units of work -
  "! which is the point, since a BAPI may use RAP internally.
  "!
  "! Must not be called inside a RAP behavior implementation: COMMIT ENTITIES is
  "! forbidden there and raises BEHAVIOR_ILLEGAL_STATEMENT.
  "!
  "! @parameter r_message_handler           | Self reference for chaining.
  "! @raising   zcx_prc_unit_of_work_failed | The buffer cannot be saved.
  METHODS simulate_save RETURNING VALUE(r_message_handler) TYPE REF TO zif_prc_message_handler
                        RAISING   zcx_prc_unit_of_work_failed.

*  "! Closes the handler successfully and stores the header message."
*  "! Without a parameter, SY is evaluated - call directly after MESSAGE s...
*  "! Raises ZCX_PRC_MESSAGE_HANDLER_MISUSE if errors were collected before,
*  "! since a success message would then contradict the collected content.
*  "!
*  "! @parameter i_header | Success message represented via symsg.
*  METHODS close_ok IMPORTING i_header TYPE symsg.

  "! Closes the handler as failed and stores the header message from SY.
  "!
  "! Call directly after a MESSAGE e... statement when the caller decides on its
  "! own that it failed - for example after a business check of its own that
  "! never produced an EML or BAPI response.
  "!
  "! @raising zcx_prc_unit_of_work_failed | Always.
  METHODS close_failed RAISING zcx_prc_unit_of_work_failed.

  "! Returns whether the unit of work has failed.
  "!
  "! Reflects the failure state, not the presence of error messages - an E
  "! message without FAILED does not set it.
  "!
  "! @parameter r_has_errors | ABAP_TRUE if an operation failed or CLOSE_FAILED was called.
  METHODS has_errors RETURNING VALUE(r_has_errors) TYPE abap_bool.

*  "! Returns whether the handler has been sealed.
*  "!
*  "! Intended for the orchestrating caller: code that returns without a sealed
*  "! handler has violated the contract.
*  "!
*  "! @parameter r_is_closed | ABAP_TRUE after CLOSE_OK, CLOSE_FAILED or any failure.
*  METHODS is_closed RETURNING VALUE(r_is_closed) TYPE abap_bool.

  "! Returns the header message to be persisted on header level.
  "!
  "! @parameter r_message | Header message, or initial if none was declared.
  METHODS get_header RETURNING VALUE(r_message) TYPE ty_message_details.

  "! Returns all collected messages, to be persisted below the header.
  "!
  "! Messages carry message class, number and variables rather than resolved
  "! text, so they stay translatable - except they were added with add_message_from_text().
  "!
  "! @parameter r_messages | Collected messages in order of arrival.
  METHODS get_messages             RETURNING VALUE(r_messages) TYPE tt_messages.

  METHODS finalize_and_persist_log RAISING   cx_bali_runtime.


ENDINTERFACE.
