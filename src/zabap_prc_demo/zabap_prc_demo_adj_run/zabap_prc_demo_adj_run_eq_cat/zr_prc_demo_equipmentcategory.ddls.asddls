@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Equipment Category'
@Metadata.allowExtensions: true
@Search.searchable: true

define root view entity ZR_PRC_DEMO_EquipmentCategory
  as select from zprc_demo_eq_cat as EquipmentCategory
{
         @ObjectModel.text.element: [ 'Description' ]
  key    id                            as Identifier,

         @Search.defaultSearchElement: true
         EquipmentCategory.description as Description
}
