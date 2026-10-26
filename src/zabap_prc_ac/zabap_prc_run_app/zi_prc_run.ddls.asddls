@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Run - Basic'
@Metadata.allowExtensions: true
@ObjectModel.usageType: { serviceQuality: #B, sizeCategory: #M, dataClass: #TRANSACTIONAL }

define view entity ZI_PRC_Run
  as select from zprc_run as Run

  association [0..*] to ZI_PRC_RunParameter         as _Parameter               on $projection.UUID = _Parameter.JobUUID
  association [0..1] to ZR_PRC_RunProgress          as _RunProgress             on $projection.UUID = _RunProgress.RunUUID
  association [0..1] to ZC_PRC_RunExecutionStatusVH as _ExecutionStatusText     on $projection.ExecutionStatus = _ExecutionStatusText.Value
  // Unfiltered on purpose: the lists filter by severity at runtime (selection variants).
  // A filter in the ON condition loses an object whose severity changed, e.g. after
  // a resume, and the UI reports "instance not found".
  association [0..*] to ZI_PRC_ProcessedObject      as _ProcessedObjectsErrors  on $projection.UUID = _ProcessedObjectsErrors.RunUUID
  association [0..*] to ZI_PRC_ProcessedObject      as _ProcessedObjectsSuccess on $projection.UUID = _ProcessedObjectsSuccess.RunUUID
{
  key Run.uuid                              as UUID,

      Run.app_name                          as ApplicationName,
      Run.job_name                          as JobName,
      Run.job_id                            as JobID,
      Run.job_count                         as JobCount,
      Run.job_start                         as JobStart,
      Run.job_end                           as JobEnd,

      _RunProgress.WorstMessageSeverityCode as MessageSeverity,
      _RunProgress.AlreadyProcessedObjects  as CurrentlyProcessedNumber,

      @ObjectModel.foreignKey.association: '_ExecutionStatusText'
      Run.execution_status                  as ExecutionStatus,

      _RunProgress.NumberOfSuccess          as NumberOfSuccess,
      3                                     as SeverityCodeSuccess,

      _RunProgress.NumberOfErrors           as NumberOfErrors,

      case coalesce(_RunProgress.NumberOfErrors, 0)
      when 0 then 3 else 1 end              as SeverityCodeError,

      Run.total_number                      as TotalNumber,
      Run.created_by                        as CreatedBy,

      // Reason of an aborted run (ExecutionStatus AB, Nr. 40.6)
      Run.msgid                             as MessageClass,
      Run.msgno                             as MessageNumber,
      Run.msgv1                             as MessageVariable1,
      Run.msgv2                             as MessageVariable2,
      Run.msgv3                             as MessageVariable3,
      Run.msgv4                             as MessageVariable4,
      Run.message_text                      as MessageText,

      _Parameter,
      _ExecutionStatusText,
      _ProcessedObjectsErrors,
      _ProcessedObjectsSuccess
}
