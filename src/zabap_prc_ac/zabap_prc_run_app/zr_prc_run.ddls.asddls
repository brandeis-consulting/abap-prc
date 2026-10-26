@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Runs'

// Read view for existing consumers; the run BO is ZR_PRC_RunTP
define view entity ZR_PRC_Run
  as select from ZI_PRC_Run
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

      _Parameter,
      _ExecutionStatusText
}
