@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Processed Message'

// Read view for existing consumers; the BO is ZR_PRC_ProcessedObjectTP
define view entity ZR_PRC_ProcessedMessage
  as select from ZI_PRC_ProcessedMessage

  association [1..1] to ZR_PRC_ProcessedStep   as _ProcessedStep   on $projection.ProcessedStepUUID = _ProcessedStep.StepUUID
  association [1..1] to ZR_PRC_ProcessedObject as _ProcessedObject on $projection.ProcessedObjectUUID = _ProcessedObject.UUID
{
  key UUID,

      ProcessedStepUUID,
      ProcessedObjectUUID,
      MessageText,
      MessageClass,
      MessageNumber,
      MessageSeverity,
      MessageVariable1,
      MessageVariable2,
      MessageVariable3,
      MessageVariable4,
      MessageSeverityCode,
      IsHeader,
      CreatedBy,
      CreatedAt,

      _ProcessedStep,
      _ProcessedObject
}
