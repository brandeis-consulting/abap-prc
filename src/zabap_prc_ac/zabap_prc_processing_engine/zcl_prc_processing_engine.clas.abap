"! <p class="shorttext synchronized">ABAP-PRC: Processing engine</p>
"!
"! Layered processing engine: composition root of the three levels list, object
"! and step. The layers are described in the architecture document; the step
"! level is built by ZCL_PRC_STEP_FACTORY.
CLASS zcl_prc_processing_engine DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS get_instance RETURNING VALUE(r_instance) TYPE REF TO zcl_prc_processing_engine.

    "! Processes the due objects selected by the parameters.
    "!
    "! @parameter it_parameters | UUIDs, process names, ignore retry scheduling.
    METHODS execute_synchronously IMPORTING it_parameters TYPE zif_prc_processing_engine=>tt_parameters OPTIONAL.

  PROTECTED SECTION.
  PRIVATE SECTION.
    "! Packages running at the same time. Every package session starts one step
    "! session at a time, so a run needs up to twice as many dialog work processes.
    CONSTANTS co_max_parallel_packages TYPE i VALUE 3.

    CLASS-DATA g_instance TYPE REF TO zcl_prc_processing_engine.
ENDCLASS.



CLASS zcl_prc_processing_engine IMPLEMENTATION.

  METHOD get_instance.
    IF g_instance IS NOT BOUND.
      g_instance = NEW #( ).
    ENDIF.
    r_instance = g_instance.
  ENDMETHOD.


  METHOD execute_synchronously.
    " List level from the outside in: selection, parallel packages; inside a
    " package: queue rule, object level (run event, step loop), step level
    DATA(list) = CAST zif_prc_processing_list(
                   NEW zcl_prc_list_selection(
                     i_parameters = it_parameters
                     i_inner      = NEW zcl_prc_list_parallel(
                                      i_inner     = zcl_prc_step_factory=>create_package_list( )
                                      i_max_tasks = co_max_parallel_packages ) ) ).

    " The selection provides the list itself
    list->process( VALUE #( ) ).
  ENDMETHOD.

ENDCLASS.

