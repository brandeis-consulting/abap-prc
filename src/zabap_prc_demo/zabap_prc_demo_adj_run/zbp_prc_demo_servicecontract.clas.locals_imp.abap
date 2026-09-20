CLASS lhc_ServiceContract DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR ServiceContract RESULT result.

    METHODS adjustViaSelectOptions FOR MODIFY
      IMPORTING keys FOR ACTION ServiceContract~adjustViaSelectOptions RESULT result.

*    METHODS GetDefaultsForAdjSelOpt FOR READ
*      IMPORTING keys FOR FUNCTION ServiceContract~GetDefaultsForAdjSelOpt RESULT result.

ENDCLASS.

CLASS lhc_ServiceContract IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD adjustViaSelectOptions.
      DATA(lv_run_uuid) = zcl_prc_run_initiator=>get_instance( )->schedule_run(
        iv_selection_option_json = keys[ 1 ]-%param-selectoptions
        it_parameter_table       = VALUE #(
            ( name = zcl_prc_demo_adjust_run_job=>c_parameter-equipment_category    value = keys[ 1 ]-%param-EquipmentCategory )
            ( name = zcl_prc_demo_adjust_run_job=>c_parameter-discount_percent      value = keys[ 1 ]-%param-DiscountInPercent )
            ( name = zcl_prc_demo_adjust_run_job=>c_parameter-material              value = keys[ 1 ]-%param-Material ) )
        iv_application_name      = zif_prc_run=>co_application_names-demo_rate_adjustment
        iv_job_name              = |Service Contract Adjustment Run - { sy-datum }, { sy-uzeit } - { sy-uname }|
        iv_job_template_name     = zif_prc_run=>co_job_template_names-demo_rate_adjustment ).

    APPEND VALUE #( %cid           = keys[ 1 ]-%cid
                    %param-runUUID = lv_run_uuid ) TO result.
*  ENDMETHOD.
*
*  METHOD GetDefaultsForAdjSelOpt.
*    LOOP AT keys INTO DATA(ls_key).
*      APPEND INITIAL LINE TO result ASSIGNING FIELD-SYMBOL(<result>).
*      <result> = VALUE #( %cid   = ls_key-%cid
*                          %param = VALUE #( EquipmentCategory = 'EQC0000001'
*                                            Material          = 'MAT0000003'
*                                            DiscountInPercent = 10 ) ).
*    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
