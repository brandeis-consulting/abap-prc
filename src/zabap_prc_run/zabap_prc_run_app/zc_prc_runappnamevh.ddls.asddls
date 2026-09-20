@AbapCatalog.viewEnhancementCategory: [ #NONE ]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Execution Type Value Help'
@ObjectModel.resultSet.sizeCategory: #XS

define view entity ZC_PRC_RunAppNameVH
  as select from zprc_run
{
  key app_name as ApplicationName
} group by app_name
