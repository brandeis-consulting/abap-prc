@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Affected Object'
@Metadata.allowExtensions: true

@UI.headerInfo: { typeName: 'Affected Object',
                  typeNamePlural: 'Affected Objects',
                  title: { type: #STANDARD, value: 'ExternalProcessedObjectID' } }

define view entity ZC_PRC_ObjectForMessage
  as projection on ZR_PRC_ObjectForMessageTP
{
  key StepUUID,

      ProcessedObjectUUID,
      ExternalProcessedObjectID,
      ProcessName,
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

      _Message : redirected to parent ZC_PRC_Message
}
