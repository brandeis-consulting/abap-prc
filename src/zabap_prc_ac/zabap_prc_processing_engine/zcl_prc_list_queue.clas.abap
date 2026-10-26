"! <p class="shorttext synchronized">ABAP-PRC: List layer - grouping and queue</p>
"!
"! Innermost layer of the list level: groups by process and queue and hands
"! every object to the object level, in the order of the list.
"!
"! Queue rule: a successor runs only if every predecessor of its queue is
"! FINISHED - read from the database, so predecessors that failed in this run,
"! got no lock or were not selected at all block alike. A blocked successor and
"! all after it stay untouched: nothing happens.
"!
"! First version processes serially, also objects without a queue.
CLASS zcl_prc_list_queue DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_prc_processing_list.

    "! @parameter i_object | Object level.
    METHODS constructor IMPORTING i_object TYPE REF TO zif_prc_processing_object.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mo_object TYPE REF TO zif_prc_processing_object.

    METHODS has_open_predecessor IMPORTING i_state         TYPE zif_prc_processing_engine=>ty_state
                                 RETURNING VALUE(r_result) TYPE abap_bool.
ENDCLASS.



CLASS zcl_prc_list_queue IMPLEMENTATION.

  METHOD constructor.
    mo_object = i_object.
  ENDMETHOD.


  METHOD zif_prc_processing_list~process.
    LOOP AT i_states INTO DATA(group_state)
         GROUP BY ( process_name = group_state-ProcessName
                    queue_id     = group_state-QueueID ) INTO DATA(group).

      DATA(blocked) = abap_false.
      LOOP AT GROUP group INTO DATA(state).
        IF blocked = abap_false AND state-QueueID IS NOT INITIAL.
          blocked = has_open_predecessor( state ).
        ENDIF.

        APPEND COND #( WHEN blocked = abap_true
                       THEN state
                       ELSE mo_object->process( state ) ) TO r_states.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.


  METHOD has_open_predecessor.
    FINAL(state_finished) = zif_prc_process=>co_finished.

    SELECT SINGLE FROM ZR_PRC_ProcessedObject
      FIELDS @abap_true
      WHERE ProcessName    = @i_state-ProcessName
        AND QueueID        = @i_state-QueueID
        AND QueuePosition  < @i_state-QueuePosition
        AND State         <> @state_finished
      INTO @r_result
      PRIVILEGED ACCESS.
  ENDMETHOD.

ENDCLASS.

