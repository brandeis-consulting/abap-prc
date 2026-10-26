"! <p class="shorttext synchronized">ABAP-PRC: Builds the layers of the step level</p>
"!
"! The one place where the step level is put together, and the list level of
"! one package on top of it. The isolation layer splits the step level in two:
"! the outer part runs in the session of the run or package, the inner part is
"! built again in the new session of every step.
"! <p class="shorttext synchronized">ABAP-PRC: Builds the layers of the step level</p>
"!
"! The one place where the step level is put together, and the list level of
"! one package on top of it. The isolation layer splits the step level in two:
"! the outer part runs in the session of the run or package, the inner part is
"! built again in the new session of every step.
CLASS zcl_prc_step_factory DEFINITION PUBLIC FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    "! List level of one package - queue rule, object level, step level. Runs in
    "! the session of the run (single package) or of a package task.
    CLASS-METHODS create_package_list RETURNING VALUE(r_list) TYPE REF TO zif_prc_processing_list.

    "! Step level as seen by the object level: 9-Event, application log and
    "! 8-Isolation. One instance per package, so one log per run and package.
    CLASS-METHODS create_step RETURNING VALUE(r_step) TYPE REF TO zif_prc_processing_step.

    "! Layers inside the isolated session: 7-Lock, 6-Unexpected, 5-Expected,
    "! 4-Commit, 3-Result, 2-Simulation, 1-Core.
    CLASS-METHODS create_isolated_step RETURNING VALUE(r_step) TYPE REF TO zif_prc_processing_step.

    "! Finder for the short dump of an aborted step; unbound where the Standard
    "! ABAP implementation does not exist (ABAP Cloud, BTP).
    CLASS-METHODS create_dump_finder RETURNING VALUE(r_finder) TYPE REF TO zif_prc_dump_finder.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-METHODS create_step_writer RETURNING VALUE(r_step_writer) TYPE REF TO zcl_prc_step_writer.
ENDCLASS.



CLASS zcl_prc_step_factory IMPLEMENTATION.

  METHOD create_package_list.
    " Object level from the outside in: run event per object, step loop
    r_list = NEW zcl_prc_list_queue(
               NEW zcl_prc_object_run(
                 NEW zcl_prc_object_step_loop( create_step( ) ) ) ).
  ENDMETHOD.


  METHOD create_step.
    " 9-Event, application log, 8-Isolation; one instance per package
    r_step = NEW zcl_prc_step_9_event(
               NEW zcl_prc_step_log(
                 NEW zcl_prc_step_8_isolation( create_step_writer( ) ) ) ).
  ENDMETHOD.


  METHOD create_isolated_step.
    DATA(step_writer) = create_step_writer( ).

    r_step = NEW zcl_prc_step_7_lock(
               NEW zcl_prc_step_6_unexpected(
                 i_step_writer = step_writer
                 i_inner       = NEW zcl_prc_step_5_expected(
                                   i_step_writer = step_writer
                                   i_inner       = NEW zcl_prc_step_4_commit(
                                                     i_step_writer = step_writer
                                                     i_inner       = NEW zcl_prc_step_3_result(
                                                                       i_step_writer = step_writer
                                                                       i_inner       = NEW zcl_prc_step_2_simulation(
                                                                                         NEW zcl_prc_step_1_core( ) ) ) ) ) ) ).
  ENDMETHOD.


  METHOD create_dump_finder.
    " The name is taken at runtime on purpose: the implementation is Standard ABAP
    DATA(implementation) = zif_prc_dump_finder=>co_implementation.
    TRY.
        CREATE OBJECT r_finder TYPE (implementation).
      CATCH cx_sy_create_object_error ##NO_HANDLER.
        " Not available: the step carries the hint message only
    ENDTRY.
  ENDMETHOD.


  METHOD create_step_writer.
    r_step_writer = NEW #( zcl_prc_db_writer=>create( ) ).
  ENDMETHOD.

ENDCLASS.

