@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Material'
@Metadata.allowExtensions: true
@Search.searchable: true

define root view entity ZR_PRC_DEMO_Material
  as select from zprc_demo_mat as Material

{
      @ObjectModel.text.element: [ 'Description' ]
      @UI.textArrangement: #TEXT_FIRST
  key id                   as Identifier,

      @Search.defaultSearchElement: true
      Material.description as Description
}
