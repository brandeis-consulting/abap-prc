@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Process Object Aggregates'

define view entity ZI_PRC_ProcessedObjectAggr
  as select from ZR_PRC_ProcessedStep

{
  key ProcessedObjectUUID,

      count(*)             as StepCounter
}

where StartState <> EndState // only count real transitions
group by ProcessedObjectUUID
