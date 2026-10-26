"! <p class="shorttext synchronized">ABAP-PRC: Writes one step of the step level</p>
"!
"! Shared by the layers that write a step - result, expected and unexpected
"! errors, isolation. Not a layer itself. Writes the step with its header, all
"! messages of the handler and the object through the DB writer. Never commits.
"!
"! The header is always one of the messages of the handler; that message is
"! marked as header (IsHeader), all others are additional messages.
CLASS zcl_prc_step_writer DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor IMPORTING i_db_writer TYPE REF TO zif_prc_db_writer.

    "! Writes one step and the object.
    "!
    "! @parameter i_start_state     | State the step started in.
    "! @parameter i_state           | Object as it is to be written: end state, payload, retry data.
    "! @parameter i_header          | Header message of the step.
    "! @parameter i_message_handler | Handler whose messages are written below the step.
    "! @parameter r_state           | Object as written, with the new latest step.
    METHODS write IMPORTING i_start_state     TYPE zif_prc_process=>ty_state
                            i_state           TYPE zif_prc_processing_engine=>ty_state
                            i_header          TYPE zif_prc_message_handler=>ty_message_details
                            i_message_handler TYPE REF TO zif_prc_message_handler
                  RETURNING VALUE(r_state)    TYPE zif_prc_processing_engine=>ty_state
                  RAISING   cx_sy_create_object_error.

    "! Adds messages to the latest step of the object, which is written already.
    "! Added messages are never the header.
    "!
    "! @parameter i_state    | Object as written; its latest step receives the messages.
    "! @parameter i_messages | Messages to add.
    METHODS add_messages IMPORTING i_state    TYPE zif_prc_processing_engine=>ty_state
                                   i_messages TYPE zif_prc_message_handler=>tt_messages
                         RAISING   cx_sy_create_object_error.

    "! Retry data after a failure: +5 min, +55 min, +23 h, +6 d, then no further retry.
    "!
    "! @parameter i_state | Object before the failed step.
    "! @parameter r_state | Object with the next retry data.
    METHODS with_next_retry IMPORTING i_state        TYPE zif_prc_processing_engine=>ty_state
                            RETURNING VALUE(r_state) TYPE zif_prc_processing_engine=>ty_state.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mo_db_writer TYPE REF TO zif_prc_db_writer.

    "! @parameter i_header | Header of the step; the last message equal to it is marked. Initial: none.
    METHODS to_processed_messages IMPORTING i_state           TYPE zif_prc_processing_engine=>ty_state
                                            i_messages        TYPE zif_prc_message_handler=>tt_messages
                                            i_header          TYPE zif_prc_message_handler=>ty_message_details OPTIONAL
                                  RETURNING VALUE(r_messages) TYPE zif_prc_db_writer=>ty_create-processedmessage.
ENDCLASS.



CLASS zcl_prc_step_writer IMPLEMENTATION.

  METHOD constructor.
    mo_db_writer = i_db_writer.
  ENDMETHOD.


  METHOD write.
    r_state = i_state.
    r_state-LatestStepUUID = xco_cp=>uuid( )->value.

    " The step holds no header fields: the header is its message with IsHeader = 'X'
    DATA(create) = VALUE zif_prc_db_writer=>ty_create(
        processedstep    = VALUE #( ( StepUUID            = r_state-LatestStepUUID
                                      ProcessedObjectUUID = r_state-UUID
                                      StartState          = i_start_state
                                      EndState            = r_state-State ) )
        processedmessage = to_processed_messages( i_state    = r_state
                                                  i_messages = i_message_handler->get_messages( )
                                                  i_header   = i_header ) ).

    DATA(update) = VALUE zif_prc_db_writer=>ty_update(
        processedobject = VALUE #( ( CORRESPONDING #( r_state ) ) ) ).

    mo_db_writer->save( i_create = create
                        i_update = update ).
  ENDMETHOD.


  METHOD add_messages.
    IF i_messages IS INITIAL.
      RETURN.
    ENDIF.
    mo_db_writer->save( i_create = VALUE #( processedmessage = to_processed_messages( i_state    = i_state
                                                                                       i_messages = i_messages ) ) ).
  ENDMETHOD.


  METHOD to_processed_messages.
    r_messages = VALUE #( FOR m IN i_messages
                          ( UUID                = xco_cp=>uuid( )->value
                            ProcessedStepUUID   = i_state-LatestStepUUID
                            ProcessedObjectUUID = i_state-UUID
                            MessageText         = m-message_text
                            MessageClass        = m-msgid
                            MessageNumber       = m-msgno
                            MessageSeverity     = m-msgty
                            MessageVariable1    = m-msgv1
                            MessageVariable2    = m-msgv2
                            MessageVariable3    = m-msgv3
                            MessageVariable4    = m-msgv4 ) ).

    IF i_header IS INITIAL.
      RETURN.
    ENDIF.

    " The handler takes the last message of the highest severity as header:
    " mark the last message equal to it
    DATA(index) = lines( i_messages ).
    WHILE index > 0.
      IF i_messages[ index ] = i_header.
        r_messages[ index ]-IsHeader = abap_true.
        RETURN.
      ENDIF.
      index -= 1.
    ENDWHILE.

    " Safety net: the header is the only place the step header is kept - never lose it
    INSERT VALUE #( UUID                = xco_cp=>uuid( )->value
                    ProcessedStepUUID   = i_state-LatestStepUUID
                    ProcessedObjectUUID = i_state-UUID
                    MessageText         = i_header-message_text
                    MessageClass        = i_header-msgid
                    MessageNumber       = i_header-msgno
                    MessageSeverity     = i_header-msgty
                    MessageVariable1    = i_header-msgv1
                    MessageVariable2    = i_header-msgv2
                    MessageVariable3    = i_header-msgv3
                    MessageVariable4    = i_header-msgv4
                    IsHeader            = abap_true ) INTO TABLE r_messages.
  ENDMETHOD.


  METHOD with_next_retry.
    r_state = i_state.
    GET TIME STAMP FIELD DATA(now).

    CASE i_state-RetryCount.
      WHEN 0.
        r_state-RetryCount    = 1.
        r_state-RetryDateTime = cl_abap_tstmp=>add( tstmp = now secs = 5 * 60 ).
      WHEN 1.
        r_state-RetryCount    = 2.
        r_state-RetryDateTime = cl_abap_tstmp=>add( tstmp = now secs = 55 * 60 ).
      WHEN 2.
        r_state-RetryCount    = 3.
        r_state-RetryDateTime = cl_abap_tstmp=>add( tstmp = now secs = 23 * 3600 ).
      WHEN 3.
        r_state-RetryCount    = 4.
        r_state-RetryDateTime = cl_abap_tstmp=>add( tstmp = now secs = 6 * 86400 ).
      WHEN 4.
        r_state-RetryCount = zif_prc_process=>co_max_retry.
        CLEAR r_state-RetryDateTime.
    ENDCASE.
  ENDMETHOD.

ENDCLASS.
