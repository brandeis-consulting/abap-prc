@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Material'
@Metadata.allowExtensions: true
@Search.searchable: true

@ObjectModel.resultSet.sizeCategory: #XS
@ObjectModel.dataCategory: #VALUE_HELP

define root view entity ZC_PRC_DEMO_Material
  as select from ZR_PRC_DEMO_Material as Material
{
  key Identifier,

      @Search.defaultSearchElement: true
      Description as Description
}
