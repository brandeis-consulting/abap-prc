@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Available States'
@Search.searchable: true
define view entity ZI_PRC_StateVH
  as select from ZR_PRC_ProcessedObject
{
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.6
  key State
}
group by
  State
