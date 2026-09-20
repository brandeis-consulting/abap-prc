@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Processed Step'
@Metadata.allowExtensions: true

define view entity ZC_PRC_ProcessedStep
  as projection on ZR_PRC_ProcessedStep
{
  key StepUUID,

      ProcessedObjectUUID,
      StartState,
      EndState,
      MessageText,
      MessageClass,
      MessageNumber,
      MessageSeverity,
      MessageSeverityCode,
      MessageVariable1,
      MessageVariable2,
      MessageVariable3,
      MessageVariable4,
      CreatedBy,
      CreatedAt,

      _ProcessedMessage: redirected to ZC_PRC_ProcessedMessage,
      _ProcessedObject: redirected to parent ZC_PRC_ProcessedObject
}
