@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Processed Object'

// Read view for existing consumers (engine state ZIF_PRC_PROCESSING_ENGINE=>ty_state,
// selections); persisted fields only. The BO is ZR_PRC_ProcessedObjectTP.
define view entity ZR_PRC_ProcessedObject
  as select from ZI_PRC_ProcessedObject

  association [0..*] to ZR_PRC_ProcessedStep       as _ProcessedStep       on $projection.UUID = _ProcessedStep.ProcessedObjectUUID
  association [0..1] to ZR_PRC_ProcessedStep       as _LatestStep          on $projection.LatestStepUUID = _LatestStep.StepUUID
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
      CreatedBy,
      CreatedAt,
      LastChangedAt,
      LastChangedBy,
      LocalLastChangedAt,

      _ProcessedStep,
      _LatestStep,
      _ProcessedObjectAggr
}
