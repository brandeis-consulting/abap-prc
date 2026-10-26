"! <p class="shorttext synchronized">ABAP-PRC: Step layer 1 - core</p>
"!
"! Runs the business logic: instantiates the process class, gets the transition
"! for the current state, performs it on a copy of the payload and determines
"! the end state. Hands the transition out by reference, also on failure.
"!
"! Violations of the process definition raise ZCX_PRC_PROCESS_DEFINITION, which
"! the layer for unexpected errors catches.
CLASS zcl_prc_step_1_core DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_prc_processing_step.

  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS create_process IMPORTING i_state          TYPE zif_prc_processing_engine=>ty_state
                           RETURNING VALUE(r_process) TYPE REF TO zif_prc_process.

    "! The end state is the unique target of the start state; with several
    "! targets the transition has to propose one of them.
    METHODS get_end_state IMPORTING i_process            TYPE REF TO zif_prc_process
                                    i_state              TYPE zif_prc_processing_engine=>ty_state
                                    i_proposed_end_state TYPE zif_prc_process=>ty_state
                          RETURNING VALUE(r_end_state)   TYPE zif_prc_process=>ty_state.
ENDCLASS.



CLASS zcl_prc_step_1_core IMPLEMENTATION.

  METHOD zif_prc_processing_step~execute.
    CLEAR e_transition.
    r_state = i_state.

    DATA(process) = create_process( i_state ).

    e_transition = process->get_transition_handler( i_start_state      = i_state-State
                                                    i_processed_object = i_state-ExternalProcessedObjectID ).
    IF e_transition IS NOT BOUND.
      RAISE EXCEPTION TYPE zcx_prc_process_definition
            MESSAGE e007(zprc_process_message) WITH i_state-FactoryClassName i_state-State.
    ENDIF.

    e_transition->initialize( i_process_name              = i_state-ProcessName
                              i_message_handler           = i_message_handler
                              i_processed_object_ext_id   = i_state-ExternalProcessedObjectID
                              i_processed_object_ext_uuid = i_state-ExternalProcessedObjectUUID ).

    " The transition works on a copy of the payload: taken over only if it succeeds
    DATA(payload_json) = i_state-PayloadJson.
    DATA(proposed_end_state) = e_transition->perform_transition( EXPORTING i_start_state  = i_state-State
                                                                 CHANGING  c_payload_json = payload_json ).

    r_state-PayloadJson = payload_json.
    r_state-State       = get_end_state( i_process            = process
                                         i_state              = i_state
                                         i_proposed_end_state = proposed_end_state ).
  ENDMETHOD.


  METHOD create_process.
    TRY.
        CREATE OBJECT r_process TYPE (i_state-FactoryClassName).
      CATCH cx_sy_create_object_error INTO DATA(error).
        RAISE EXCEPTION TYPE zcx_prc_process_definition
              MESSAGE e005(zprc_process_message) WITH i_state-FactoryClassName
              EXPORTING previous = error.
    ENDTRY.
  ENDMETHOD.


  METHOD get_end_state.
    DATA(transitions) = i_process->get_transitions( ).
    DATA(targets) = VALUE zif_prc_process=>tt_transition( FOR t IN transitions WHERE ( start_state = i_state-State )
                                                          ( t ) ).

    IF lines( targets ) = 1.
      r_end_state = targets[ 1 ]-end_state.
      IF i_proposed_end_state IS NOT INITIAL AND i_proposed_end_state <> r_end_state.
        RAISE EXCEPTION TYPE zcx_prc_process_definition
              MESSAGE e006(zprc_process_message) WITH i_state-State i_proposed_end_state i_state-FactoryClassName.
      ENDIF.
      RETURN.
    ENDIF.

    IF i_proposed_end_state IS INITIAL.
      RAISE EXCEPTION TYPE zcx_prc_process_definition
            MESSAGE e008(zprc_process_message) WITH i_state-FactoryClassName i_state-State.
    ENDIF.
    IF NOT line_exists( targets[ end_state = i_proposed_end_state ] ).
      RAISE EXCEPTION TYPE zcx_prc_process_definition
            MESSAGE e006(zprc_process_message) WITH i_state-State i_proposed_end_state i_state-FactoryClassName.
    ENDIF.
    r_end_state = i_proposed_end_state.
  ENDMETHOD.

ENDCLASS.

