@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Message'
@Metadata.allowExtensions: true
@Search.searchable: true

@UI.headerInfo: { typeName: 'Message',
                  typeNamePlural: 'Messages',
                  title: { type: #STANDARD, value: 'MessageClass' },
                  description: { type: #STANDARD, value: 'MessageTextTranslated' } }

@UI.lineItem: [ { criticality: 'MessageSeverityCode' } ]

// Non-transactional projection for own apps: resume only. The app of the PRC
// uses ZC_PRC_MessageTP.
define root view entity ZC_PRC_Message
  provider contract transactional_query
  as projection on ZR_PRC_MessageTP
{
  key MessageClass,
  key MessageNumber,
  key MessageSeverity,
  key MessageVariable1,
  key MessageVariable2,
  key MessageVariable3,
  key MessageVariable4,
      // Persisted text (language of the processing user): search only (Nr. 17);
      // the facets stay on this element
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.7
      @UI.lineItem: null
      @UI.identification: null
  key MessageText,
  key ProcessName,

      // Displayed text in the logon language (Nr. 17)
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_PRC_MESSAGE_TEXT'
      @EndUserText.label: 'Message Text'
      @UI.lineItem: [ { position: 10,
                        importance: #HIGH,
                        criticality: 'MessageSeverityCode',
                        criticalityRepresentation: #WITH_ICON },
                      { position: 15,
                        type: #FOR_ACTION,
                        dataAction: 'resumeProcessing',
                        label: 'Resume Processing',
                        inline: true,
                        invocationGrouping: #ISOLATED } ]
      @UI.identification: [ { position: 3, qualifier: 'MSG_INFO' } ]
      virtual MessageTextTranslated : zprc_message_text,

      MessageSeverityCode,
      AffectedObjectCount,

      _ObjectsForMessage : redirected to composition child ZC_PRC_ObjectForMessage,
      _MessageSeverity
}
