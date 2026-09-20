@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Run Progress'

@Metadata.allowExtensions: true

define root view entity ZR_PRC_RunSuccess
  as select from ZR_PRC_ProcessedObject as ProcessedObject

{
  key ProcessedObject.RunUUID,
      count(*) as NumberOfSuccess
}

where ( _LatestStep.MessageSeverity = 'S' )  
and ( ProcessedObject.RunUUID is not null )
group by ProcessedObject.RunUUID
