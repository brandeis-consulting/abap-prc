@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Business Partner'
@Metadata.allowExtensions: true
@Search.searchable: true

define root view entity ZC_PRC_DEMO_BusinessPartner
  as select from ZR_PRC_DEMO_BusinessPartner as BusinessPartner

{
  key Identifier,

      @Search.defaultSearchElement: true
      Description as Description
}
