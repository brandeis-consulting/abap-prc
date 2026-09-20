@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Processed Step'

define view entity ZR_PRC_ProcessedStep
  as select from zprc_proc_step as ProcessedStep

  composition [0..*] of ZR_PRC_ProcessedMessage as _ProcessedMessage
  association        to parent ZR_PRC_ProcessedObject   as _ProcessedObject on $projection.ProcessedObjectUUID = _ProcessedObject.UUID
  association [0..1] to        ZI_PRC_MessageSeverityVH as _MessageSeverity on $projection.MessageSeverity = _MessageSeverity.Value

{
  key step_uuid               as StepUUID,

      processed_object_uuid   as ProcessedObjectUUID,
      start_state             as StartState,
      end_state               as EndState,

      message_text            as MessageText,
      msgid                   as MessageClass,
      msgno                   as MessageNumber,

      @ObjectModel.foreignKey.association: '_MessageSeverity'
      msgty                   as MessageSeverity,

      msgv1                   as MessageVariable1,
      msgv2                   as MessageVariable2,
      msgv3                   as MessageVariable3,
      msgv4                   as MessageVariable4,

      message_severity_code   as MessageSeverityCode,

      @Semantics.user.createdBy: true
      created_by              as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at              as CreatedAt,

      _ProcessedMessage,
      _ProcessedObject,
      _MessageSeverity
}
