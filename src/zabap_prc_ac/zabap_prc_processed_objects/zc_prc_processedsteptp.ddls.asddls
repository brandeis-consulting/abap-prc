@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Processed Step'
@Metadata.allowExtensions: true

@UI.headerInfo: { typeName: 'Processed Step',
                  typeNamePlural: 'Processed Steps',
                  title: { type: #STANDARD, value: 'MessageTextTranslated' } }

@UI.lineItem: [ { criticality: 'MessageSeverityCode' } ]

define view entity ZC_PRC_ProcessedStepTP
  as projection on ZR_PRC_ProcessedStepTP
{
  key StepUUID,

      ProcessedObjectUUID,
      StartState,
      EndState,

      // Persisted header text (language of the processing user), not displayed (Nr. 17)
      @UI.identification: null
      @UI.lineItem: null
      @UI.hidden: true
      MessageText,

      // Displayed header text in the logon language (Nr. 17)
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_PRC_MESSAGE_TEXT'
      @EndUserText.label: 'Message Text'
      @UI.identification: [ { position: 20 } ]
      @UI.lineItem: [ { position: 20,
                        importance: #HIGH,
                        criticality: 'MessageSeverityCode',
                        criticalityRepresentation: #WITH_ICON } ]
      virtual MessageTextTranslated : zprc_message_text,

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

      _ProcessedObject  : redirected to parent ZC_PRC_ProcessedObjectTP,
      _ProcessedMessage : redirected to composition child ZC_PRC_ProcessedMessageTP
}
