@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Processed Step - Basic'
@Metadata.allowExtensions: true
@ObjectModel.usageType: { serviceQuality: #A, sizeCategory: #L, dataClass: #TRANSACTIONAL }

// The header of a step is the message with IsHeader = 'X' (exactly one per step,
// written by ZCL_PRC_STEP_WRITER); the step table holds no message fields.
define view entity ZI_PRC_ProcessedStep
  as select from zprc_proc_step as ProcessedStep

  association [1..1] to ZI_PRC_ProcessedObject   as _ProcessedObject  on  $projection.ProcessedObjectUUID = _ProcessedObject.UUID
  association [0..*] to ZI_PRC_ProcessedMessage  as _ProcessedMessage on  $projection.StepUUID = _ProcessedMessage.ProcessedStepUUID
  association [0..1] to ZI_PRC_ProcessedMessage  as _HeaderMessage    on  $projection.StepUUID = _HeaderMessage.ProcessedStepUUID
                                                                      and _HeaderMessage.IsHeader = 'X'
  association [0..1] to ZI_PRC_MessageSeverityVH as _MessageSeverity  on  $projection.MessageSeverity = _MessageSeverity.Value
{
  key step_uuid                          as StepUUID,

      processed_object_uuid              as ProcessedObjectUUID,
      start_state                        as StartState,
      end_state                          as EndState,

      _HeaderMessage.MessageText         as MessageText,
      _HeaderMessage.MessageClass        as MessageClass,
      _HeaderMessage.MessageNumber       as MessageNumber,

      @ObjectModel.foreignKey.association: '_MessageSeverity'
      _HeaderMessage.MessageSeverity     as MessageSeverity,

      _HeaderMessage.MessageVariable1    as MessageVariable1,
      _HeaderMessage.MessageVariable2    as MessageVariable2,
      _HeaderMessage.MessageVariable3    as MessageVariable3,
      _HeaderMessage.MessageVariable4    as MessageVariable4,

      _HeaderMessage.MessageSeverityCode as MessageSeverityCode,

      @Semantics.user.createdBy: true
      created_by                         as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at                         as CreatedAt,

      _ProcessedObject,
      _ProcessedMessage,
      _HeaderMessage,
      _MessageSeverity
}
