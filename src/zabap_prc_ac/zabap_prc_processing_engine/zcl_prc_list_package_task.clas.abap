"! <p class="shorttext synchronized">ABAP-PRC: Package of objects running in a session of its own</p>
"!
"! Created by the parallel list layer and executed by CL_ABAP_PARALLEL. A
"! package is one queue or one object without queue. The instance is
"! serialized, so it carries data only; the list level of the package (queue
"! rule, object level, step level) is created in the new session.
"!
"! Global instead of local, because the instance is re-created in the new session.
CLASS zcl_prc_list_package_task DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_abap_parallel.

    "! @parameter i_states | States of the package, in processing order.
    METHODS constructor IMPORTING i_states TYPE zif_prc_processing_engine=>tt_state.

    "! @parameter r_states | States after processing the package.
    METHODS get_result RETURNING VALUE(r_states) TYPE zif_prc_processing_engine=>tt_state.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mt_states TYPE zif_prc_processing_engine=>tt_state.
    DATA mt_result TYPE zif_prc_processing_engine=>tt_state.
ENDCLASS.



CLASS zcl_prc_list_package_task IMPLEMENTATION.

  METHOD constructor.
    mt_states = i_states.
    mt_result = i_states.
  ENDMETHOD.


  METHOD get_result.
    r_states = mt_result.
  ENDMETHOD.


  METHOD if_abap_parallel~do.
    mt_result = zcl_prc_step_factory=>create_package_list( )->process( mt_states ).
  ENDMETHOD.

ENDCLASS.

