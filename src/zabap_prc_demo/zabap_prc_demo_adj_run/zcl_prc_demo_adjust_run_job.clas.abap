CLASS zcl_prc_demo_adjust_run_job DEFINITION
  PUBLIC
  INHERITING FROM zcl_prc_run_job FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS if_apj_dt_exec_object~get_parameters REDEFINITION.

    CONSTANTS: BEGIN OF c_parameter,
                 contract_id        TYPE zif_prc_run=>ty_run_parameter VALUE 'S_CTR',
                 sold_to_party      TYPE zif_prc_run=>ty_run_parameter VALUE 'S_SOLD',
                 ship_to_party      TYPE zif_prc_run=>ty_run_parameter VALUE 'S_SHIP',
                 lifecycle_status   TYPE zif_prc_run=>ty_run_parameter VALUE 'S_LIFE',
                 error_status       TYPE zif_prc_run=>ty_run_parameter VALUE 'S_ERR',

                 equipment_category TYPE zif_prc_run=>ty_run_parameter VALUE 'P_EQCAT',
                 material           TYPE zif_prc_run=>ty_run_parameter VALUE 'P_MAT',
                 discount_percent   TYPE zif_prc_run=>ty_run_parameter VALUE 'P_DISC',
               END OF c_parameter.

    CONSTANTS: co_job_template_names TYPE zif_prc_run=>ty_job_template_name VALUE 'ZAJT_PRC_DEMO_ADJUST_RUN'.
    CONSTANTS: co_application_names  TYPE zprc_run_app_name VALUE 'DEMO_RATE_ADJUSTMENT'.

  PROTECTED SECTION.
    METHODS get_application_name REDEFINITION.
    METHODS execute              REDEFINITION.

  PRIVATE SECTION.
    DATA mt_contract_items_to_process TYPE STANDARD TABLE OF ZI_PRC_Demo_SrvCtrItemSel WITH DEFAULT KEY.

    METHODS _do_actual_processing.
    METHODS _get_data.
ENDCLASS.


CLASS zcl_prc_demo_adjust_run_job IMPLEMENTATION.

  METHOD execute.
    _get_data( ).
    _do_actual_processing( ).
  ENDMETHOD.

  METHOD if_apj_dt_exec_object~get_parameters.
    et_parameter_def = VALUE #(
        changeable_ind = abap_true
        ( selname = c_parameter-contract_id         kind = if_apj_dt_exec_object=>select_option datatype = 'C' length = 10 param_text = 'Service Contract' )
        ( selname = c_parameter-sold_to_party       kind = if_apj_dt_exec_object=>select_option datatype = 'C' length = 10 param_text = 'Sold-to-Party' )
        ( selname        = c_parameter-ship_to_party
          kind           = if_apj_dt_exec_object=>select_option
          component_type = 'ZPRC_DEMO_LIFECYCLE_STATUS'
          datatype       = 'C'
          length         = 10
          param_text     = 'Ship-to-Party' )
        ( selname        = c_parameter-lifecycle_status
          kind           = if_apj_dt_exec_object=>select_option
          component_type = 'ZPRC_DEMO_ERROR_STATUS'
          datatype       = 'C'
          length         = 1
          param_text     = 'Lifecycle Status' )
        ( selname = c_parameter-error_status        kind = if_apj_dt_exec_object=>select_option datatype = 'C' length = 1  param_text = 'Error Status' )

        ( selname        = c_parameter-equipment_category
          kind           = if_apj_dt_exec_object=>parameter
          datatype       = 'C'
          length         = 10
          param_text     = 'Equipment Category' )
        ( selname = c_parameter-material            kind = if_apj_dt_exec_object=>parameter datatype = 'C'   length = 10 param_text = 'Service' )
        ( selname = c_parameter-discount_percent    kind = if_apj_dt_exec_object=>parameter datatype = 'P'   length = 10 param_text = 'Discount (in %)' )
        ( selname = zif_prc_run=>co_parameter-p_uuid kind = if_apj_dt_exec_object=>parameter datatype = 'C'   length = 32 param_text = 'Run UUID' ) ).
  ENDMETHOD.

  METHOD _do_actual_processing.
    TYPES: BEGIN OF ty_id_and_uuid,
             id   TYPE ZI_PRC_Demo_SrvCtrItemSel-ServiceContractID,
             uuid TYPE ZI_PRC_Demo_SrvCtrItemSel-ContractUUID,
           END OF ty_id_and_uuid,
           tt_contract_ids TYPE SORTED TABLE OF ty_id_and_uuid WITH UNIQUE KEY uuid.
    DATA lt_contract_ids TYPE tt_contract_ids.

    LOOP AT mt_contract_items_to_process INTO DATA(ls_contract_item).
      INSERT VALUE #( id   = ls_contract_item-ServiceContractID
                      uuid = ls_contract_item-ContractUUID ) INTO TABLE lt_contract_ids.
    ENDLOOP.

    set_total_number( lines( lt_contract_ids ) ).

    zcl_prc_processing_api=>get_instance( )->create_processed_objects(
        i_create_processed_objects = VALUE #( FOR i IN lt_contract_ids
                                              ( processedObject     = i-id
                                                processedObjectUUID = i-uuid
                                                runUUID             = mv_current_run_uuid
                                                factoryClassName    = zcl_prc_demo_create_equi_proc=>co_class_name
                                                processName         = zcl_prc_demo_create_equi_proc=>co_process_name ) )
        i_perform_commit           = abap_true
        i_trigger_processing       = zcl_prc_processing_api=>execution_mode-direct_execution ).
  ENDMETHOD.

  METHOD _get_data.
    CLEAR mt_contract_items_to_process.
    READ TABLE mt_select_options_values WITH KEY selname = c_parameter-contract_id INTO DATA(ls_select_option_ctr).
    READ TABLE mt_select_options_values WITH KEY selname = c_parameter-sold_to_party INTO DATA(ls_select_option_sold).
    READ TABLE mt_select_options_values WITH KEY selname = c_parameter-ship_to_party INTO DATA(ls_select_option_ship).
    READ TABLE mt_select_options_values WITH KEY selname = c_parameter-lifecycle_status INTO DATA(ls_select_option_life).
    READ TABLE mt_select_options_values WITH KEY selname = c_parameter-error_status INTO DATA(ls_select_option_error).

    SELECT * FROM ZI_PRC_Demo_SrvCtrItemSel
      WHERE ServiceContractID IN @ls_select_option_ctr-ranges
        AND SoldToPartyID     IN @ls_select_option_sold-ranges
        AND ShipToPartyID     IN @ls_select_option_ship-ranges
        AND LifecycleStatus   IN @ls_select_option_life-ranges
        AND ErrorStatus       IN @ls_select_option_error-ranges
      INTO TABLE @mt_contract_items_to_process.
  ENDMETHOD.

  METHOD get_application_name.
    rv_application_name = zif_prc_run=>co_application_names-demo_rate_adjustment.
  ENDMETHOD.

ENDCLASS.
