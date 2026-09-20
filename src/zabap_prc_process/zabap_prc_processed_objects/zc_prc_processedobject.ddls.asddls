@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Processed Object'

@Metadata.allowExtensions: true

@Search.searchable: true

@UI.headerInfo: { typeName: 'Processed Object',
                  typeNamePlural: 'Processed Objects',
                  title: { type: #STANDARD, value: 'ExternalProcessedObjectID' },
                  description: { type: #STANDARD, value: 'MessageText' },
                  typeImageUrl: 'sap-icon://blank-tag' }

@UI.presentationVariant: [ { qualifier: 'pVariant',
                             maxItems: 5,
                             sortOrder: [ { by: 'LastChangedAt', direction: #DESC } ],
                             visualizations: [ { type: #AS_LINEITEM } ] },
                           { qualifier: 'p50Variant',
                             maxItems: 50,
                             sortOrder: [ { by: 'LastChangedAt', direction: #DESC } ],
                             visualizations: [ { type: #AS_LINEITEM } ] } ]

@UI.selectionPresentationVariant: [ { qualifier: 'spVariant',
                                      presentationVariantQualifier: 'pVariant',
                                      selectionVariantQualifier: 'sVariant' },
                                    { presentationVariantQualifier: 'p50Variant' } ]

@UI.selectionVariant: [ { qualifier: 'sVariant', text: 'SelectionVariant', filter: 'MessageSeverity EQ E' } ]

define root view entity ZC_PRC_ProcessedObject
  provider contract transactional_query
  
  
  as projection on ZR_PRC_ProcessedObject
  association [1..1] to ZC_PRC_ProcessedObject as _ProcessedObjectsErrors
    on $projection.UUID = _ProcessedObjectsErrors.UUID
  association [1..1] to ZC_PRC_ProcessedObject as _ProcessedObjectsSuccess
    on $projection.UUID = _ProcessedObjectsSuccess.UUID
    association [0..*] to ZC_PRC_AllProcessedMessages as _AllProcessedMessages
    on $projection.UUID = _AllProcessedMessages.ProcessedObjectUUID
{
  key     UUID,

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

          @Search.defaultSearchElement: true
          @Search.fuzzinessThreshold: 0.7
          _LatestStep.MessageText          as MessageText,

          _LatestStep.MessageSeverity      as MessageSeverity,
          _LatestStep.MessageSeverityCode  as MessageSeverityCode,
          _ProcessedObjectAggr.StepCounter as StepCounter,

          StepTotal,

          @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_PRC_PROC_OBJ_LINK'
  virtual link : abap.char(1000),

          _ProcessedStep : redirected to composition child ZC_PRC_ProcessedStep,
          _LatestStep    : redirected to ZC_PRC_ProcessedStep,

          _ProcessedObjectAggr,
          _ProcessedObjectsErrors,
          _ProcessedObjectsSuccess,
          _AllProcessedMessages
}
