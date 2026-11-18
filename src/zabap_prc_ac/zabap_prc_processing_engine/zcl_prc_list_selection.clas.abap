"! <p class="shorttext synchronized">ABAP-PRC: List layer - selection</p>
"!
"! Outermost layer of the list level: decides which objects are due - not
"! FINISHED, DoNotProcessBefore passed, retry due, selected UUIDs and process
"! names. Ignores its input and passes the selected list inward, ordered by
"! process, queue and position.
"!
"! Ignoring the retry scheduling selects failed objects regardless of their
"! retry time and treats them as not retried yet.
CLASS zcl_prc_list_selection DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_prc_processing_list.

    "! @parameter i_parameters | Parameters of the run (UUIDs, process names, ignore retry scheduling).
    "! @parameter i_inner      | Next inner layer of the list level.
    METHODS constructor IMPORTING i_parameters TYPE if_apj_rt_exec_object=>tt_templ_val
                                  i_inner      TYPE REF TO zif_prc_processing_list.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA parameters TYPE if_apj_rt_exec_object=>tt_templ_val.
    DATA inner      TYPE REF TO zif_prc_processing_list.

    METHODS select IMPORTING i_ignore_retry_scheduling TYPE abap_bool
                   RETURNING VALUE(r_states)           TYPE zif_prc_processing_engine=>tt_state.
ENDCLASS.



CLASS zcl_prc_list_selection IMPLEMENTATION.

  METHOD constructor.
    parameters = i_parameters.
    inner      = i_inner.
  ENDMETHOD.


  METHOD zif_prc_processing_list~process.
    DATA(ignore_retry_scheduling) = xsdbool( line_exists( parameters[ selname = zcl_prc_retry_job=>co_parameter-ignore_restart
                                                                      low     = abap_true ] ) ).
    DATA(selected) = select( ignore_retry_scheduling ).

    DATA(states) = COND zif_prc_processing_engine=>tt_state(
                     WHEN ignore_retry_scheduling = abap_false
                     THEN selected
                     ELSE VALUE #( FOR s IN selected
                                   ( VALUE #( BASE s RetryCount = 0 RetryDateTime = 0 ) ) ) ).

    r_states = inner->process( states ).
  ENDMETHOD.


  METHOD select.
    DATA(max_retry) = CONV int8( zif_prc_process=>co_max_retry ).
    FINAL(state_finished) = zif_prc_process=>co_finished.
    GET TIME STAMP FIELD DATA(current_timestamp).
    DATA(retry_compare_timestamp) = current_timestamp.
    IF i_ignore_retry_scheduling = abap_true.
      retry_compare_timestamp = '20991010101010'.
      max_retry += 1.
    ENDIF.

    DATA selected_uuids TYPE RANGE OF ZR_PRC_ProcessedObject-uuid.
    selected_uuids = VALUE #( FOR p IN parameters WHERE ( selname = zcl_prc_retry_job=>co_parameter-uuid )
                              ( CORRESPONDING #( p ) ) ).

    DATA selected_process_names TYPE RANGE OF zprc_process_name.
    selected_process_names = VALUE #( FOR p IN parameters WHERE ( selname = zcl_prc_retry_job=>co_parameter-process_name )
                                      ( CORRESPONDING #( p ) ) ).

    " Privileged: this selection serves every way of processing (direct execution after
    " creation, run job, processing API, retry job), which must not depend on the user who
    " triggers it. The DCL of ZI_PRC_ProcessedObject (ZPRC_PROC activity 03) would also be
    " the wrong check: processing needs activity 16, and adding 16 to that DCL would let
    " every user with 16 read in the apps. Where a user decides what is processed, the
    " entry point restricts the process names beforehand: the retry job
    " (ZCL_PRC_RETRY_JOB->RESTRICT_TO_AUTHORIZED, ZPRC_PROC activity 16).
    SELECT FROM ZR_PRC_ProcessedObject AS ProcessedObject
      FIELDS *
      WHERE State <> @state_finished
        AND ( \_LatestStep-MessageSeverity <> 'E' OR RetryDateTime <= @retry_compare_timestamp AND RetryCount < @max_retry )
        AND DoNotProcessBefore  < @current_timestamp
        AND uuid               IN @selected_uuids
        AND ProcessName        IN @selected_process_names
      ORDER BY ProcessName, QueueID, QueuePosition
      INTO CORRESPONDING FIELDS OF TABLE @r_states
      PRIVILEGED ACCESS.
  ENDMETHOD.

ENDCLASS.
