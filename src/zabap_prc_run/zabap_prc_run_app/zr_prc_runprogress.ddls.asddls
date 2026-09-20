@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Run Progress'

@Metadata.allowExtensions: true

define root view entity ZR_PRC_RunProgress
  as select from ZR_PRC_ProcessedObject as ProcessedObject

{
  key ProcessedObject.RunUUID,
      count(*) as AlreadyProcessedObjects,
      min( _LatestStep.MessageSeverityCode ) as WorstMessageSeverityCode
}

where ( ProcessedObject._LatestStep.StepUUID is not null )  
and ( ProcessedObject.RunUUID is not null  )
group by ProcessedObject.RunUUID
