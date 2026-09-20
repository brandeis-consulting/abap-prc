@EndUserText.label: 'Parameter to initiate the run'
define root abstract entity ZA_PRC_DEMO_AdjustmentParams
{
  @EndUserText.label: 'Equipment Category'
  @Consumption.valueHelpDefinition: [{ entity.name: 'ZC_PRC_DEMO_EquipmentCategory', entity.element: 'Identifier', useForValidation: true }] 
  EquipmentCategory: abap.char(10);
  
  @EndUserText.label: 'Service'
  @Consumption.valueHelpDefinition: [{ entity.name: 'ZC_PRC_DEMO_Material', entity.element: 'Identifier', useForValidation: true }] 
  Material: abap.char(10);
  
  @EndUserText.label: 'Discount (in %)'
  DiscountInPercent: abap.dec( 10, 0 );
  
}
