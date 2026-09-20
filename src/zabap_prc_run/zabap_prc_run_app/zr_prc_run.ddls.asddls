@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Runs'

@Metadata.allowExtensions: true

@Search.searchable: true

define root view entity ZR_PRC_Run
  as select from zprc_run as Run

//  association [0..*] to ZR_PRC_ProcessedObject      as _ProcessedObjectsErrors  on  _ProcessedObjectsErrors.RunUUID         = Run.uuid
////                                                                                and _ProcessedObjectsErrors.MessageSeverity = 'E'
//  association [0..*] to ZR_PRC_ProcessedObject      as _ProcessedObjectsSuccess on  _ProcessedObjectsSuccess.RunUUID         =  Run.uuid
//                                                                                and _ProcessedObjectsSuccess.MessageSeverity <> 'E'

  composition [0..*] of ZR_PRC_RunParameter         as _Parameter
  association [0..1] to ZR_PRC_RunProgress          as _RunProgress             on  Run.uuid = _RunProgress.RunUUID

  association [0..1] to ZR_PRC_RunErrors            as _RunErrors               on  Run.uuid = _RunErrors.RunUUID
  association [0..1] to ZR_PRC_RunSuccess           as _RunSuccess              on  Run.uuid = _RunSuccess.RunUUID
  association [0..1] to ZC_PRC_RunExecutionStatusVH as _ExecutionStatusText     on  _ExecutionStatusText.Value = Run.execution_status

//    association [0..1] to ZC_R1_RunMessageSeverity_VH as _MessageSeverityText on _MessageSeverityText.Value = $projection.MessageSeverity
  association [0..1] to ZC_PRC_RunExecutionTypeVH   as _ExecutionTypeText       on  _ExecutionTypeText.Value = Run.execution_type

{
  key Run.uuid                              as UUID,

      Run.app_name                          as ApplicationName,
      Run.job_name                          as JobName,
      Run.job_id                            as JobID,
      Run.job_count                         as JobCount,
      Run.job_start                         as JobStart,
      Run.job_end                           as JobEnd,

      cast(Run.log_handle as abap.char(22)) as LogHandle,

      @ObjectModel.foreignKey.association: '_ExecutionTypeText'
      Run.execution_type                    as ExecutionType,

      _RunProgress.WorstMessageSeverityCode as MessageSeverity,
      _RunProgress.AlreadyProcessedObjects  as CurrentlyProcessedNumber,

      @ObjectModel.foreignKey.association: '_ExecutionStatusText'
      Run.execution_status                  as ExecutionStatus,

      _RunSuccess.NumberOfSuccess           as NumberOfSuccess,
      3                                     as SeverityCodeSuccess,

      _RunErrors.NumberOfErrors             as NumberOfErrors,

      case coalesce(_RunErrors.NumberOfErrors, 0)
      when 0 then 3 else 1 end              as SeverityCodeError,

      Run.total_number                      as TotalNumber,
      Run.created_by                        as CreatedBy,

      @Search.defaultSearchElement: true
      _Parameter,

      _ExecutionTypeText,

      _ExecutionStatusText
//      ,
//      _ProcessedObjectsErrors,
//      _ProcessedObjectsSuccess
}
