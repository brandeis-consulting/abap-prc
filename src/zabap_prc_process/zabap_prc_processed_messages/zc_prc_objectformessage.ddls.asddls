@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Messages processed'
@Metadata.allowExtensions: true

define view entity ZC_PRC_ObjectForMessage
  provider contract transactional_query
  as projection on ZR_PRC_ObjectForMessage

{
  key StepUUID,

      ExternalProcessedObjectID,
      ProcessedObjectUUID,
      StartState,
      EndState,
      ProcessName,
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

      _Message : redirected to ZC_PRC_Message
}
