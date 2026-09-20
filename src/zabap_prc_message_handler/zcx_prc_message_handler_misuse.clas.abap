"! <p class="shorttext synchronized">Message handler contract violation</p>
"!
"! Signals a programming error in the calling code, not a business failure.
"! Derived from CX_NO_CHECK on purpose so it does not pollute the signature
"! of every method that touches the handler.
CLASS zcx_prc_message_handler_misuse DEFINITION
  PUBLIC INHERITING FROM cx_no_check FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_t100_message.

    CONSTANTS:
      "! Handler was already sealed by CLOSE_OK, CLOSE_FAILED or a failure
      BEGIN OF already_closed,
        msgid TYPE symsgid      VALUE 'ZPRC_MESSAGE_HANDLER',
        msgno TYPE symsgno      VALUE '001',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF already_closed.

    CONSTANTS:
      "! CLOSE_OK was called although errors had been collected
      BEGIN OF success_despite_errors,
        msgid TYPE symsgid      VALUE 'ZPRC_MESSAGE_HANDLER',
        msgno TYPE symsgno      VALUE '002',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF success_despite_errors.

    CONSTANTS:
      "! SIMULATE_SAVE was called more than once
      BEGIN OF already_simulated,
        msgid TYPE symsgid      VALUE 'ZPRC_MESSAGE_HANDLER',
        msgno TYPE symsgno      VALUE '003',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF already_simulated.

    CONSTANTS:
      "! GET_FAILURE_MESSAGE returned an initial message
      BEGIN OF header_missing,
        msgid TYPE symsgid      VALUE 'ZPRC_MESSAGE_HANDLER',
        msgno TYPE symsgno      VALUE '004',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF header_missing.

    CONSTANTS:
      "! GET_MESSAGE_HANDLER was called outside a running execution
      BEGIN OF no_active_execution,
        msgid TYPE symsgid      VALUE 'ZPRC_MESSAGE_HANDLER',
        msgno TYPE symsgno      VALUE '005',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',

        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF no_active_execution.

    "! Creates the exception for a given contract violation.
    "!
    "! @parameter textid | One of the constants of this class. Defaults to the
    "!                     class default text if omitted.
    METHODS constructor IMPORTING textid LIKE if_t100_message=>t100key OPTIONAL.

protected section.
private section.
ENDCLASS.



CLASS ZCX_PRC_MESSAGE_HANDLER_MISUSE IMPLEMENTATION.


  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( ).
    if_t100_message~t100key = COND #( WHEN textid IS INITIAL
                                      THEN if_t100_message=>default_textid
                                      ELSE textid ).
  ENDMETHOD.
ENDCLASS.
