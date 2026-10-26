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

define root view entity ZC_PRC_RunTP
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

      // Reason of an aborted run (Nr. 40.6); persisted fields not displayed
      @UI.hidden: true
      MessageClass,
      @UI.hidden: true
      MessageNumber,
      @UI.hidden: true
      MessageVariable1,
      @UI.hidden: true
      MessageVariable2,
      @UI.hidden: true
      MessageVariable3,
      @UI.hidden: true
      MessageVariable4,
      @UI.hidden: true
      MessageText,

      // Displayed reason in the logon language; empty unless the run was aborted
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_PRC_MESSAGE_TEXT'
      @EndUserText.label: 'Abort Reason'
      @UI.fieldGroup: [ { qualifier: 'qExecRun', position: 10 } ]
      virtual MessageTextTranslated : zprc_message_text,

      _Parameter               : redirected to composition child ZC_PRC_RunParameterTP,
      _ProcessedObjectsErrors  : redirected to ZC_PRC_ProcessedObjectTP,
      _ProcessedObjectsSuccess : redirected to ZC_PRC_ProcessedObjectTP,
      _ExecutionStatusText
}
