@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Messages processed'
@Metadata.allowExtensions: true

define view entity ZR_PRC_ObjectForMessage
  as select from ZR_PRC_ProcessedStep       as _ProcessedStep

    inner join   ZI_PRC_ObjectLatestMessage as _LatestMessage on  _ProcessedStep.CreatedAt           = _LatestMessage.LatestCreatedAt
                                                              and _ProcessedStep.ProcessedObjectUUID = _LatestMessage.ProcessedObjectUUID

  association to ZR_PRC_ProcessedObject as _ProcessedObject on  _ProcessedStep.ProcessedObjectUUID = _ProcessedObject.UUID

  association to parent ZR_PRC_Message  as _Message         on  $projection.MessageNumber    = _Message.MessageNumber
                                                            and $projection.MessageClass     = _Message.MessageClass
                                                            and $projection.MessageSeverity  = _Message.MessageSeverity
                                                            and $projection.MessageVariable1 = _Message.MessageVariable1
                                                            and $projection.MessageVariable2 = _Message.MessageVariable2
                                                            and $projection.MessageVariable3 = _Message.MessageVariable3
                                                            and $projection.MessageVariable4 = _Message.MessageVariable4
                                                            and $projection.MessageText      = _Message.MessageText
                                                            and $projection.processname      = _Message.ProcessName
{
  key _ProcessedStep.StepUUID,

      _ProcessedObject.ProcessName,
      _ProcessedStep._ProcessedObject.ExternalProcessedObjectID,
      _ProcessedStep.ProcessedObjectUUID,
      _ProcessedStep.StartState,
      _ProcessedStep.EndState,
      _ProcessedStep.MessageText,
      _ProcessedStep.MessageClass,
      _ProcessedStep.MessageNumber,
      _ProcessedStep.MessageSeverity,
      _ProcessedStep.MessageVariable1,
      _ProcessedStep.MessageVariable2,
      _ProcessedStep.MessageVariable3,
      _ProcessedStep.MessageVariable4,
      _ProcessedStep.MessageSeverityCode,
      _ProcessedStep.CreatedBy,

      _ProcessedStep.CreatedAt,

      _Message
}
