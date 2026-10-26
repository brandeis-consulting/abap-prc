@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Processed Object'
@Metadata.allowExtensions: true
@Search.searchable: true

@UI.headerInfo: { typeName: 'Processed Object',
                  typeNamePlural: 'Processed Objects',
                  title: { type: #STANDARD, value: 'ExternalProcessedObjectID' },
                  description: { type: #STANDARD, value: 'MessageTextTranslated' },
                  typeImageUrl: 'sap-icon://blank-tag' }

@UI.lineItem: [ { criticality: 'MessageSeverityCode' } ]

@UI.presentationVariant: [ { qualifier: 'pVariant',
                             maxItems: 5,
                             sortOrder: [ { by: 'LastChangedAt', direction: #DESC } ],
                             visualizations: [ { type: #AS_LINEITEM } ] },
                           { qualifier: 'p50Variant',
                             maxItems: 50,
                             sortOrder: [ { by: 'LastChangedAt', direction: #DESC } ],
                             visualizations: [ { type: #AS_LINEITEM } ] } ]

// Lists of a run filter by severity at runtime: an object whose severity changes
// (resume) stays reachable, no "instance not found"
@UI.selectionVariant: [ { qualifier: 'sVariant',        text: 'Errors',  filter: 'MessageSeverity EQ E' },
                        { qualifier: 'sVariantSuccess', text: 'Success', filter: 'MessageSeverity NE E' } ]

@UI.selectionPresentationVariant: [ { qualifier: 'spVariant',
                                      presentationVariantQualifier: 'pVariant',
                                      selectionVariantQualifier: 'sVariant' },
                                    { qualifier: 'spVariantSuccess',
                                      presentationVariantQualifier: 'pVariant',
                                      selectionVariantQualifier: 'sVariantSuccess' },
                                    { presentationVariantQualifier: 'p50Variant' } ]

define root view entity ZC_PRC_ProcessedObjectTP
  provider contract transactional_query
  as projection on ZR_PRC_ProcessedObjectTP
{
  key UUID,

      LatestStepUUID,
      RunUUID,
      ProcessName,
      MailAddress,
      FactoryClassName,
      RetryCount,
      RetryDateTime,
      DoNotProcessBefore,
      QueueID,
      QueuePosition,
      CreatedAt,
      CreatedBy,
      LastChangedAt,
      LastChangedBy,
      LocalLastChangedAt,
      PayloadJson,

      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      State,

      @Search.defaultSearchElement: true
      ExternalProcessedObjectID,

      ExternalProcessedObjectUUID,

      // Persisted text (language of the processing user): search and filter only (Nr. 17)
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.7
      @UI.fieldGroup: null
      @UI.lineItem: null
      @UI.hidden: true
      MessageText,

      // Displayed text: header of the latest step in the logon language (Nr. 17)
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_PRC_MESSAGE_TEXT'
      @EndUserText.label: 'Message'
      @UI.fieldGroup: [ { qualifier: 'qLatestInfos',
                          position: 10,
                          importance: #HIGH,
                          criticality: 'MessageSeverityCode',
                          criticalityRepresentation: #WITH_ICON },
                        { qualifier: 'qHeader',
                          position: 10,
                          importance: #HIGH,
                          criticality: 'MessageSeverityCode',
                          criticalityRepresentation: #WITH_ICON } ]
      @UI.lineItem: [ { position: 10,
                        importance: #HIGH,
                        criticality: 'MessageSeverityCode',
                        criticalityRepresentation: #WITH_ICON } ]
      virtual MessageTextTranslated : zprc_message_text,

      MessageSeverity,
      MessageSeverityCode,
      StepCounter,
      StepTotal,

      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_PRC_PROC_OBJ_LINK'
      virtual link : abap.char(1000),

      _ProcessedStep      : redirected to composition child ZC_PRC_ProcessedStepTP,
      _LatestStep         : redirected to ZC_PRC_ProcessedStepTP,
      _AdditionalMessages : redirected to ZC_PRC_ProcessedMessageTP,
      _ProcessedObjectAggr
}
