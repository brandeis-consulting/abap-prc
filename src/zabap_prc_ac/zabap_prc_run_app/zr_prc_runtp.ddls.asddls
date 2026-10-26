@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Run - BO'
@Metadata.allowExtensions: true

define root view entity ZR_PRC_RunTP
  as select from ZI_PRC_Run

  composition [0..*] of ZR_PRC_RunParameterTP    as _Parameter
  // Unfiltered on purpose: the lists filter by severity at runtime
  association [0..*] to ZR_PRC_ProcessedObjectTP as _ProcessedObjectsErrors  on $projection.UUID = _ProcessedObjectsErrors.RunUUID
  association [0..*] to ZR_PRC_ProcessedObjectTP as _ProcessedObjectsSuccess on $projection.UUID = _ProcessedObjectsSuccess.RunUUID
{
  key UUID,

      ApplicationName,
      JobName,
      JobID,
      JobCount,
      JobStart,
      JobEnd,
      MessageSeverity,
      CurrentlyProcessedNumber,
      ExecutionStatus,
      NumberOfSuccess,
      SeverityCodeSuccess,
      NumberOfErrors,
      SeverityCodeError,
      TotalNumber,
      CreatedBy,
      MessageClass,
      MessageNumber,
      MessageVariable1,
      MessageVariable2,
      MessageVariable3,
      MessageVariable4,
      MessageText,

      _Parameter,
      _ExecutionStatusText,
      _ProcessedObjectsErrors,
      _ProcessedObjectsSuccess
}
