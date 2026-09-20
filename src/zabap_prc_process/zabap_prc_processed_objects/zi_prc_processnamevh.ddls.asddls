@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Available application Names'
@Search.searchable: true
define view entity ZI_PRC_ProcessNameVH
  as select from ZR_PRC_ProcessedObject
{
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.6
  key ProcessName
}
group by
  ProcessName
