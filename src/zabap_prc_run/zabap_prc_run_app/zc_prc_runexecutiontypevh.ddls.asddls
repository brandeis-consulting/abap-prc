@AbapCatalog.viewEnhancementCategory: [ #NONE ]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Execution Type Value Help'
@ObjectModel.resultSet.sizeCategory: #XS
 
define view entity ZC_PRC_RunExecutionTypeVH
  as select from ZI_PRC_DomainValues( p_domain_name: 'ZPRC_RUN_EXECUTION_TYPE')
{
  key Value as Value,
      Text
}
