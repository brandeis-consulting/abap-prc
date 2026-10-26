@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Header Message of the Latest Step'
@Metadata.allowExtensions: true
@ObjectModel.usageType: { serviceQuality: #B, sizeCategory: #L, dataClass: #TRANSACTIONAL }

// One row per processed object: the header message of its latest step
define view entity ZI_PRC_LatestHeaderMessage
  as select from ZI_PRC_ProcessedObject  as ProcessedObject
    inner join   ZI_PRC_ProcessedMessage as Message on  Message.ProcessedStepUUID = ProcessedObject.LatestStepUUID
                                                    and Message.IsHeader          = 'X'
{
  key Message.ProcessedStepUUID             as StepUUID,

      ProcessedObject.UUID                  as ProcessedObjectUUID,
      ProcessedObject.ExternalProcessedObjectID,
      ProcessedObject.ProcessName,
      Message.StartState,
      Message.EndState,
      Message.MessageText,
      Message.MessageClass,
      Message.MessageNumber,
      Message.MessageSeverity,
      Message.MessageVariable1,
      Message.MessageVariable2,
      Message.MessageVariable3,
      Message.MessageVariable4,
      Message.MessageSeverityCode,
      Message.CreatedBy,
      Message.CreatedAt
}
