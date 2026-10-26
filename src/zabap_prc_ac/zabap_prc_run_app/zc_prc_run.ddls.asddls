@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Run'
@Metadata.allowExtensions: true
@Search.searchable: true

@UI.headerInfo: { typeName: 'Application Run',
                  typeNamePlural: 'Application Runs',
                  title: { type: #STANDARD, value: 'JobName' } }

@UI.presentationVariant: [ { sortOrder: [ { by: 'JobStart', direction: #DESC } ],
                             visualizations: [ { type: #AS_LINEITEM } ] } ]

@UI.lineItem: [ { criticality: 'MessageSeverity' } ]

// Non-transactional projection for own apps: side effects only. The app of the
// PRC uses ZC_PRC_RunTP.
define root view entity ZC_PRC_Run
  provider contract transactional_query
  as projection on ZR_PRC_RunTP
{
  key UUID,

      ApplicationName,
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.7
      JobName,
      JobID,
      JobCount,
      JobStart,
      JobEnd,
      MessageSeverity,
      ExecutionStatus,
      NumberOfErrors,
      SeverityCodeError,
      NumberOfSuccess,
      SeverityCodeSuccess,
      CurrentlyProcessedNumber,
      TotalNumber,
      CreatedBy,

      _Parameter               : redirected to composition child ZC_PRC_RunParameter,
      _ProcessedObjectsErrors  : redirected to ZC_PRC_ProcessedObject,
      _ProcessedObjectsSuccess : redirected to ZC_PRC_ProcessedObject,
      _ExecutionStatusText
}
