@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Processed Message - Basic'
@Metadata.allowExtensions: true
@ObjectModel.usageType: { serviceQuality: #A, sizeCategory: #XL, dataClass: #TRANSACTIONAL }

// States are read from the step table, not via ZI_PRC_ProcessedStep: the step takes
// its header fields from this view (_HeaderMessage), a path back would be a cycle.
define view entity ZI_PRC_ProcessedMessage
  as select from    zprc_proc_msg  as ProcessedMessage
    left outer to one join zprc_proc_step as Step on Step.step_uuid = ProcessedMessage.processed_step_uuid

  association [1..1] to ZI_PRC_ProcessedStep   as _ProcessedStep   on $projection.ProcessedStepUUID = _ProcessedStep.StepUUID
  association [1..1] to ZI_PRC_ProcessedObject as _ProcessedObject on $projection.ProcessedObjectUUID = _ProcessedObject.UUID
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
      // The header of its step; all other messages are additional messages
      ProcessedMessage.is_header             as IsHeader,

      // States of the step, for lists of all messages of an object
      Step.start_state                       as StartState,
      Step.end_state                         as EndState,

      @Semantics.user.createdBy: true
      ProcessedMessage.created_by            as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      ProcessedMessage.created_at            as CreatedAt,

      _ProcessedStep,
      _ProcessedObject
}
