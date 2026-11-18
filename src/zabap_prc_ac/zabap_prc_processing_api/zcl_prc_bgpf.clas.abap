"! bgPF operation: processes the objects selected by the parameters in the background.
CLASS zcl_prc_bgpf DEFINITION PUBLIC CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_bgmc_op_single_tx_uncontr.

    "! @parameter i_parameters | UUIDs, process names, ignore retry scheduling
    METHODS constructor IMPORTING i_parameters TYPE if_apj_rt_exec_object=>tt_templ_val.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA parameters TYPE if_apj_rt_exec_object=>tt_templ_val.
ENDCLASS.



CLASS zcl_prc_bgpf IMPLEMENTATION.


  METHOD constructor.
    parameters = i_parameters.
  ENDMETHOD.


  METHOD if_bgmc_op_single_tx_uncontr~execute.
    zcl_prc_processing_api=>get_instance( )->process_synchronously( parameters ).
  ENDMETHOD.
ENDCLASS.
