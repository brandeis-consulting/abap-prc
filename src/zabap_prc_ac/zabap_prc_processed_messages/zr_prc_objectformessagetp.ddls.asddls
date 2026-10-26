@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Object for Message - BO'
@Metadata.allowExtensions: true

define view entity ZR_PRC_ObjectForMessageTP
  as select from ZI_PRC_LatestHeaderMessage

  association to parent ZR_PRC_MessageTP as _Message on  $projection.ProcessName      = _Message.ProcessName
                                                     and $projection.MessageClass     = _Message.MessageClass
                                                     and $projection.MessageNumber    = _Message.MessageNumber
                                                     and $projection.MessageSeverity  = _Message.MessageSeverity
                                                     and $projection.MessageVariable1 = _Message.MessageVariable1
                                                     and $projection.MessageVariable2 = _Message.MessageVariable2
                                                     and $projection.MessageVariable3 = _Message.MessageVariable3
                                                     and $projection.MessageVariable4 = _Message.MessageVariable4
                                                     and $projection.MessageText      = _Message.MessageText
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

      _Message
}
