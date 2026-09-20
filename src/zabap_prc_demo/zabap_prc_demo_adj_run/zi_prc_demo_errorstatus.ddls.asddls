@AbapCatalog.viewEnhancementCategory: [ #NONE ]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Lifecycle Status Value Help'
@ObjectModel.resultSet.sizeCategory: #XS
 
define view entity ZI_PRC_DEMO_ErrorStatus
  as select from ZI_PRC_DomainValues( p_domain_name: 'ZPRC_DEMO_ERROR_STATUS')
{
  key Value as Value,
      Text
}
