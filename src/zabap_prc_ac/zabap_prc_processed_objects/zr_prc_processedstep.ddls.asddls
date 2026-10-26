@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Processed Step'

// Read view for existing consumers; the BO is ZR_PRC_ProcessedObjectTP
define view entity ZR_PRC_ProcessedStep
  as select from ZI_PRC_ProcessedStep

  association [0..*] to ZR_PRC_ProcessedMessage as _ProcessedMessage on $projection.StepUUID = _ProcessedMessage.ProcessedStepUUID
  association [1..1] to ZR_PRC_ProcessedObject  as _ProcessedObject  on $projection.ProcessedObjectUUID = _ProcessedObject.UUID
{
  key StepUUID,

      ProcessedObjectUUID,
      StartState,
      EndState,
      MessageText,
      MessageClass,
      MessageNumber,
      MessageSeverity,
      MessageVariable1,
      MessageVariable2,
      MessageVariable3,
      MessageVariable4,
      MessageSeverityCode,
      CreatedBy,
      CreatedAt,

      _ProcessedMessage,
      _ProcessedObject,
      _MessageSeverity
}
