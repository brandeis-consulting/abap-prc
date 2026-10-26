@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Processed Message - BO'
@Metadata.allowExtensions: true

define view entity ZR_PRC_ProcessedMessageTP
  as select from ZI_PRC_ProcessedMessage

  association     to parent ZR_PRC_ProcessedStepTP   as _ProcessedStep   on $projection.ProcessedStepUUID = _ProcessedStep.StepUUID
  association [1..1] to     ZR_PRC_ProcessedObjectTP as _ProcessedObject on $projection.ProcessedObjectUUID = _ProcessedObject.UUID
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
      StartState,
      EndState,
      CreatedBy,
      CreatedAt,

      _ProcessedStep,
      _ProcessedObject
}
