CLASS zcl_prc_bgpf DEFINITION PUBLIC CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_bgmc_op_single_tx_uncontr.

    METHODS constructor IMPORTING it_parameters TYPE if_apj_rt_exec_object=>tt_templ_val.

protected section.
  PRIVATE SECTION.
    DATA mt_parameters TYPE if_apj_rt_exec_object=>tt_templ_val.
ENDCLASS.



CLASS ZCL_PRC_BGPF IMPLEMENTATION.


  METHOD constructor.
    mt_parameters = it_parameters.
  ENDMETHOD.


  METHOD if_bgmc_op_single_tx_uncontr~execute.
    zcl_prc_processing_api=>get_instance( )->execute_synchronously( mt_parameters ).
  ENDMETHOD.
ENDCLASS.
