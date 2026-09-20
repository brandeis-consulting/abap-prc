@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Run Progress'

@Metadata.allowExtensions: true

define root view entity ZR_PRC_RunErrors
  as select from ZR_PRC_ProcessedObject as ProcessedObject

{
  key ProcessedObject.RunUUID,
      count(*) as NumberOfErrors
}

where ( _LatestStep.MessageSeverity = 'E' )  
and ( ProcessedObject.RunUUID is not null  )
group by ProcessedObject.RunUUID
