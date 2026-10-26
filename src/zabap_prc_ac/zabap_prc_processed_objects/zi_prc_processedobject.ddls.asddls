@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Processed Object - Basic'
@Metadata.allowExtensions: true
@ObjectModel.usageType: { serviceQuality: #A, sizeCategory: #L, dataClass: #TRANSACTIONAL }

define view entity ZI_PRC_ProcessedObject
  as select from zprc_proc_object as ProcessedObject

  association [0..*] to ZI_PRC_ProcessedStep       as _ProcessedStep        on  $projection.UUID = _ProcessedStep.ProcessedObjectUUID
  association [0..1] to ZI_PRC_ProcessedStep       as _LatestStep           on  $projection.LatestStepUUID = _LatestStep.StepUUID
  association [0..*] to ZI_PRC_ProcessedMessage    as _AllProcessedMessages on  $projection.UUID = _AllProcessedMessages.ProcessedObjectUUID
  // Messages other than the headers of the steps; IsHeader never changes, so the filter is safe
  association [0..*] to ZI_PRC_ProcessedMessage    as _AdditionalMessages   on  $projection.UUID              = _AdditionalMessages.ProcessedObjectUUID
                                                                            and _AdditionalMessages.IsHeader  = ''
  association [0..1] to ZI_PRC_ProcessedObjectAggr as _ProcessedObjectAggr  on  $projection.UUID = _ProcessedObjectAggr.ProcessedObjectUUID
  association [0..1] to ZI_PRC_Run                 as _Run                  on  $projection.RunUUID = _Run.UUID
{
  key uuid                             as UUID,

      latest_step_uuid                 as LatestStepUUID,
      process_name                     as ProcessName,
      mail_address                     as MailAddress,
      factory_class_name               as FactoryClassName,
      run_uuid                         as RunUUID,
      ext_processed_object_id          as ExternalProcessedObjectID,
      ext_processed_object_uuid        as ExternalProcessedObjectUUID,
      payload_json                     as PayloadJson,
      state                            as State,
      retry_datetime                   as RetryDateTime,
      retry_count                      as RetryCount,

      do_not_process_before            as DoNotProcessBefore,
      queue_id                         as QueueID,
      queue_pos                        as QueuePosition,

      step_total                       as StepTotal,

      // Header of the latest step and progress, for every list of objects
      _LatestStep.MessageText          as MessageText,
      _LatestStep.MessageSeverity      as MessageSeverity,
      _LatestStep.MessageSeverityCode  as MessageSeverityCode,
      _ProcessedObjectAggr.StepCounter as StepCounter,

      @Semantics.user.createdBy: true
      created_by                       as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at                       as CreatedAt,

      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at                  as LastChangedAt,

      @Semantics.user.lastChangedBy: true
      last_changed_by                  as LastChangedBy,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at            as LocalLastChangedAt,

      _ProcessedStep,
      _LatestStep,
      _AllProcessedMessages,
      _AdditionalMessages,
      _ProcessedObjectAggr,
      _Run
}
