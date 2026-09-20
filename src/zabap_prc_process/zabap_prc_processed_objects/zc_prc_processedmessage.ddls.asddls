@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Processed Step'
@Metadata.allowExtensions: true

define view entity ZC_PRC_ProcessedMessage
  provider contract transactional_query
  as projection on ZR_PRC_ProcessedMessage
{

  key UUID,
      ProcessedObjectUUID,
      ProcessedStepUUID,
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

      _ProcessedStep: redirected to ZC_PRC_ProcessedStep,
      _ProcessedObject: redirected to ZC_PRC_ProcessedObject
}
