"! <p class="shorttext synchronized">ABAP-PRC: List layer - parallel packages</p>
"!
"! Splits the list into packages and runs them in parallel: every queue is one
"! package (serial inside, see the queue rule), every object without queue is a
"! package of its own. Each package runs in a session of its own
"! (CL_ABAP_PARALLEL); the steps inside are still isolated each.
"!
"! A single package needs no session of its own: it runs in the session of the
"! run, so one object costs the run session and its step session only.
"!
"! Parallel packages of one run count as one lock owner. That is harmless, as
"! no two packages contain the same object.
CLASS zcl_prc_list_parallel DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_prc_processing_list.

    "! @parameter i_inner     | List level of one package, used for a single package.
    "! @parameter i_max_tasks | Packages running at the same time.
    METHODS constructor IMPORTING i_inner     TYPE REF TO zif_prc_processing_list
                                  i_max_tasks TYPE i.

  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES tt_package TYPE STANDARD TABLE OF zif_prc_processing_engine=>tt_state WITH EMPTY KEY.

    DATA mo_inner     TYPE REF TO zif_prc_processing_list.
    DATA m_max_tasks  TYPE i.

    METHODS build_packages IMPORTING i_states          TYPE zif_prc_processing_engine=>tt_state
                           RETURNING VALUE(r_packages) TYPE tt_package.
ENDCLASS.



CLASS zcl_prc_list_parallel IMPLEMENTATION.

  METHOD constructor.
    mo_inner    = i_inner.
    m_max_tasks = i_max_tasks.
  ENDMETHOD.


  METHOD zif_prc_processing_list~process.
    DATA(packages) = build_packages( i_states ).

    IF lines( packages ) <= 1.
      r_states = mo_inner->process( i_states ).
      RETURN.
    ENDIF.

    DATA(parallel) = NEW cl_abap_parallel( p_num_tasks = m_max_tasks ).
    parallel->run_inst( EXPORTING p_in_tab  = VALUE #( FOR p IN packages ( NEW zcl_prc_list_package_task( p ) ) )
                        IMPORTING p_out_tab = DATA(results) ).

    LOOP AT packages INTO DATA(package).
      DATA(result) = VALUE #( results[ sy-tabix ] OPTIONAL ).
      IF result-inst IS BOUND.
        APPEND LINES OF CAST zcl_prc_list_package_task( result-inst )->get_result( ) TO r_states.
      ELSE.
        " Package session aborted: its steps are isolated, so this hardly happens.
        " The objects stay as they are and are picked up by the next run.
        APPEND LINES OF package TO r_states.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD build_packages.
    LOOP AT i_states INTO DATA(state)
         GROUP BY ( process_name = state-ProcessName
                    queue_id     = state-QueueID ) INTO DATA(group).
      IF group-queue_id IS INITIAL.
        LOOP AT GROUP group INTO DATA(single).
          APPEND VALUE #( ( single ) ) TO r_packages.
        ENDLOOP.
      ELSE.
        APPEND VALUE #( FOR member IN GROUP group ( member ) ) TO r_packages.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

