@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Header Messages of All Steps'
@Metadata.allowExtensions: true
@ObjectModel.usageType: { serviceQuality: #C, sizeCategory: #XL, dataClass: #TRANSACTIONAL }

// One row per step header, with a flag whether it is the header of the latest step of
// its object. The message app groups over all of them, so a group does not vanish when
// its last object is resumed (the event side effect re-reads the group, Nr. 5 of 25.10.).
define view entity ZI_PRC_HeaderMessage
  as select from ZI_PRC_ProcessedMessage as Message
    inner join   ZI_PRC_ProcessedObject  as ProcessedObject on ProcessedObject.UUID = Message.ProcessedObjectUUID
{
  key Message.UUID                          as MessageUUID,

      Message.ProcessedStepUUID             as StepUUID,
      ProcessedObject.UUID                  as ProcessedObjectUUID,
      ProcessedObject.ProcessName,
      Message.MessageText,
      Message.MessageClass,
      Message.MessageNumber,
      Message.MessageSeverity,
      Message.MessageVariable1,
      Message.MessageVariable2,
      Message.MessageVariable3,
      Message.MessageVariable4,
      Message.MessageSeverityCode,

      // 1 = header of the latest step, i.e. the current message of the object
      cast( case when Message.ProcessedStepUUID = ProcessedObject.LatestStepUUID
                 then 1 else 0 end as abap.int4 ) as IsLatestHeader
}
where
  Message.IsHeader = 'X'
