@AbapCatalog.viewEnhancementCategory: [ #NONE ]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Execution Status Value Help'
@ObjectModel.resultSet.sizeCategory: #XS
 
define view entity ZC_PRC_RunExecutionStatusVH
  as select from ZI_PRC_DomainValues( p_domain_name: 'ZPRC_RUN_EXECUTION_STATUS')
{
  key Value as Value,
      Text
}
