@AbapCatalog.viewEnhancementCategory: [ #NONE ]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value help for errors'
@ObjectModel.resultSet.sizeCategory: #XS

define view entity ZI_PRC_MessageSeverityVH
  as select from ZI_PRC_DomainValues(p_domain_name : 'ZPRC_MESSAGE_SEVERITY')
{
  key Value as Value,
      Text
}
