@AccessControl.authorizationCheck: #CHECK

@EndUserText.label: 'Processed Object'

define root view entity ZR_PRC_ProcessedObject
  as select from zprc_proc_object as ProcessedObject

  composition [*] of    ZR_PRC_ProcessedStep       as _ProcessedStep
  association [0..1] to ZR_PRC_ProcessedStep       as _LatestStep          on _LatestStep.StepUUID = ProcessedObject.latest_step_uuid
  association [0..1] to ZI_PRC_ProcessedObjectAggr as _ProcessedObjectAggr on $projection.UUID = _ProcessedObjectAggr.ProcessedObjectUUID

{
  key uuid                      as UUID,

      latest_step_uuid          as LatestStepUUID,
      process_name              as ProcessName,
      mail_address              as MailAddress,
      factory_class_name        as FactoryClassName,
      run_uuid                  as RunUUID,
      ext_processed_object_id   as ExternalProcessedObjectID,
      ext_processed_object_uuid as ExternalProcessedObjectUUID,
      payload_json              as PayloadJson,
      state                     as State,
      retry_datetime            as RetryDateTime,
      retry_count               as RetryCount,

      do_not_process_before     as DoNotProcessBefore,
      queue_id                  as QueueID,
      queue_pos                 as QueuePosition,

      step_total                as StepTotal,

      @Semantics.user.createdBy: true
      created_by                as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at                as CreatedAt,

      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at           as LastChangedAt,

      @Semantics.user.lastChangedBy: true
      last_changed_by           as LastChangedBy,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at     as LocalLastChangedAt,

      _ProcessedStep,
      _LatestStep,
      _ProcessedObjectAggr
}
