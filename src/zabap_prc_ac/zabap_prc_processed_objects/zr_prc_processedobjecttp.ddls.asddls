@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Processed Object - BO'
@Metadata.allowExtensions: true

define root view entity ZR_PRC_ProcessedObjectTP
  as select from ZI_PRC_ProcessedObject

  composition [0..*] of ZR_PRC_ProcessedStepTP     as _ProcessedStep
  association [0..1] to ZR_PRC_ProcessedStepTP     as _LatestStep          on  $projection.LatestStepUUID = _LatestStep.StepUUID
  // Messages other than the headers of the steps; IsHeader never changes, so the filter is safe
  association [0..*] to ZR_PRC_ProcessedMessageTP  as _AdditionalMessages  on  $projection.UUID             = _AdditionalMessages.ProcessedObjectUUID
                                                                           and _AdditionalMessages.IsHeader = ''
{
  key UUID,

      LatestStepUUID,
      ProcessName,
      MailAddress,
      FactoryClassName,
      RunUUID,
      ExternalProcessedObjectID,
      ExternalProcessedObjectUUID,
      PayloadJson,
      State,
      RetryDateTime,
      RetryCount,
      DoNotProcessBefore,
      QueueID,
      QueuePosition,
      StepTotal,
      MessageText,
      MessageSeverity,
      MessageSeverityCode,
      StepCounter,
      CreatedBy,
      CreatedAt,
      LastChangedAt,
      LastChangedBy,
      LocalLastChangedAt,

      _ProcessedStep,
      _LatestStep,
      _AdditionalMessages,
      _ProcessedObjectAggr,
      _Run
}
