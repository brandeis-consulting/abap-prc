@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Processed Step - BO'
@Metadata.allowExtensions: true

define view entity ZR_PRC_ProcessedStepTP
  as select from ZI_PRC_ProcessedStep

  association to parent ZR_PRC_ProcessedObjectTP as _ProcessedObject  on $projection.ProcessedObjectUUID = _ProcessedObject.UUID
  composition [0..*] of ZR_PRC_ProcessedMessageTP  as _ProcessedMessage
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

      _ProcessedObject,
      _ProcessedMessage,
      _MessageSeverity
}
