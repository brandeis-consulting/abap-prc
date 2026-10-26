"! <p class="shorttext synchronized">ABAP-PRC: Process definition violated by the process class</p>
"!
"! Raised by the core when the process class breaks its own definition - no
"! transition handler, an end state outside its transitions. An implementation
"! error, caught by the layer for unexpected errors. CX_NO_CHECK, so it passes
"! the layers in between without being declared.
CLASS zcx_prc_process_definition DEFINITION PUBLIC INHERITING FROM cx_no_check FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_t100_dyn_msg.

    METHODS constructor IMPORTING textid   LIKE if_t100_message=>t100key OPTIONAL
                                  previous LIKE previous                 OPTIONAL.
ENDCLASS.



CLASS zcx_prc_process_definition IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

