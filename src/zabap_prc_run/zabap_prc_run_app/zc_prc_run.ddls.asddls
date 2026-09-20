@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Run'

@Metadata.allowExtensions: true

@Search.searchable: true

@UI.headerInfo: { typeName: 'Application Run',
                  typeNamePlural: 'Application Runs',
                  title: { type: #STANDARD, value: 'JobName' } }

@UI.presentationVariant: [ { sortOrder: [ { by: 'JobStart', direction: #DESC } ],
                             visualizations: [ { type: #AS_LINEITEM } ] } ]

@UI.lineItem: [ { criticality: 'MessageSeverity' } ]

define root view entity ZC_PRC_Run
  provider contract transactional_query
  as projection on ZR_PRC_Run as Run
  association [0..*] to ZC_PRC_ProcessedObject      as _ProcessedObjectsErrors
    on _ProcessedObjectsErrors.RunUUID = $projection.UUID
    and _ProcessedObjectsErrors.MessageSeverity = 'E'

  association [0..*] to ZC_PRC_ProcessedObject      as _ProcessedObjectsSuccess
    on  _ProcessedObjectsSuccess.RunUUID          = $projection.UUID
    and _ProcessedObjectsSuccess.MessageSeverity <> 'E'

{
  key UUID,

      ApplicationName,
      JobName,
      JobID,
      JobCount,
      JobStart,
      JobEnd,
      LogHandle,
      ExecutionType,
      MessageSeverity,
      ExecutionStatus,
      NumberOfErrors,
      SeverityCodeError,
      NumberOfSuccess,
      SeverityCodeSuccess,
      CurrentlyProcessedNumber,
      TotalNumber,
      CreatedBy,

      _Parameter: redirected to ZC_PRC_RunParameter,

      _ExecutionStatusText,
      _ExecutionTypeText,
      _ProcessedObjectsErrors,
      _ProcessedObjectsSuccess
}
