@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'Processed Step'

define view entity ZC_PRC_AllProcessedMessages
  as select from    ZR_PRC_ProcessedStep    as _ProcessedStep
    left outer join ZR_PRC_ProcessedMessage as _ProcessedMessage on _ProcessedStep.StepUUID = _ProcessedMessage.ProcessedStepUUID
{
  key _ProcessedMessage.UUID,
      _ProcessedMessage.ProcessedStepUUID,
      _ProcessedMessage.ProcessedObjectUUID,
      _ProcessedMessage.MessageText,
      _ProcessedMessage.MessageClass,
      _ProcessedMessage.MessageNumber,
      _ProcessedMessage.MessageSeverity,
      _ProcessedMessage.MessageSeverityCode,
      _ProcessedMessage.MessageVariable1,
      _ProcessedMessage.MessageVariable2,
      _ProcessedMessage.MessageVariable3,
      _ProcessedMessage.MessageVariable4,
      _ProcessedMessage.CreatedBy,
      _ProcessedMessage.CreatedAt,
      _ProcessedStep.StartState,
      _ProcessedStep.EndState
}
