@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Processed Message'
@Metadata.allowExtensions: true

@UI.headerInfo: { typeName: 'Message',
                  typeNamePlural: 'Messages',
                  title: { type: #STANDARD, value: 'MessageTextTranslated' } }

@UI.lineItem: [ { criticality: 'MessageSeverityCode' } ]

// Tables on the object pages (additional messages, messages of a step): the newest first.
// Referenced by the facets (PRESENTATIONVARIANT_REFERENCE) - a table does not pick it up by itself.
@UI.presentationVariant: [ { qualifier: 'pvNewestFirst',
                             sortOrder: [ { by: 'CreatedAt', direction: #DESC } ],
                             visualizations: [ { type: #AS_LINEITEM } ] } ]

define view entity ZC_PRC_ProcessedMessageTP
  as projection on ZR_PRC_ProcessedMessageTP
{
  key UUID,

      ProcessedStepUUID,
      ProcessedObjectUUID,

      // Persisted text (language of the processing user), not displayed
      @UI.identification: null
      @UI.lineItem: null
      @UI.hidden: true
      MessageText,

      // Displayed text in the logon language
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_PRC_MESSAGE_TEXT'
      @EndUserText.label: 'Message Text'
      @UI.identification: [ { position: 20 } ]
      @UI.lineItem: [ { position: 10,
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
      IsHeader,
      StartState,
      EndState,
      CreatedBy,
      CreatedAt,

      _ProcessedStep   : redirected to parent ZC_PRC_ProcessedStepTP,
      _ProcessedObject : redirected to ZC_PRC_ProcessedObjectTP
}
