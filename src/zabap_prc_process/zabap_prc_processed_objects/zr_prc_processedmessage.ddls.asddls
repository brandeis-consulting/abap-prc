@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Processed Step'

define view entity ZR_PRC_ProcessedMessage
  as select from zprc_proc_msg as ProcessedMessage

  association     to parent ZR_PRC_ProcessedStep   as _ProcessedStep   on $projection.ProcessedStepUUID = _ProcessedStep.StepUUID
  association [1] to        ZR_PRC_ProcessedObject as _ProcessedObject on $projection.ProcessedObjectUUID = _ProcessedObject.UUID

{
  key ProcessedMessage.uuid                  as UUID,

      ProcessedMessage.processed_step_uuid   as ProcessedStepUUID,
      ProcessedMessage.processed_object_uuid as ProcessedObjectUUID,
      ProcessedMessage.message_text          as MessageText,
      ProcessedMessage.msgid                 as MessageClass,
      ProcessedMessage.msgno                 as MessageNumber,
      ProcessedMessage.msgty                 as MessageSeverity,
      ProcessedMessage.msgv1                 as MessageVariable1,
      ProcessedMessage.msgv2                 as MessageVariable2,
      ProcessedMessage.msgv3                 as MessageVariable3,
      ProcessedMessage.msgv4                 as MessageVariable4,
      ProcessedMessage.message_severity_code as MessageSeverityCode,

      @Semantics.user.createdBy: true
      ProcessedMessage.created_by            as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      ProcessedMessage.created_at            as CreatedAt,

      _ProcessedStep,
      _ProcessedObject
}
