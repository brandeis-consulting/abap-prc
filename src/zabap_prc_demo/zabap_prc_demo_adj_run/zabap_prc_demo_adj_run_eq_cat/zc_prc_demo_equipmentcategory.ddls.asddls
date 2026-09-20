@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Equipment Category'
@Metadata.allowExtensions: true
@Search.searchable: true

@ObjectModel.resultSet.sizeCategory: #XS
@ObjectModel.dataCategory: #VALUE_HELP

define root view entity ZC_PRC_DEMO_EquipmentCategory
  as select from ZR_PRC_DEMO_EquipmentCategory as EquipmentCategory
{
      @Search.defaultSearchElement: true
  key Identifier,

      @Search.defaultSearchElement: true
      Description as Description
}
