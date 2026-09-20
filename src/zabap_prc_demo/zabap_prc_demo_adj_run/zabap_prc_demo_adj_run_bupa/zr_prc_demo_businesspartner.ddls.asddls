@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Business Partner'
@Metadata.allowExtensions: true
@Search.searchable: true

define root view entity ZR_PRC_DEMO_BusinessPartner
  as select from zprc_demo_bupa as BusinessParter

{
      @ObjectModel.text.element: [ 'Description' ]
      @UI.textArrangement: #TEXT_ONLY
  key id          as Identifier,

      @Search.defaultSearchElement: true
      @Semantics.name.fullName: true
      @Semantics.text: true
      description as Description
}
