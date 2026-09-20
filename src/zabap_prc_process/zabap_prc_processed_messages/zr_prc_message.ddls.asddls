@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@EndUserText.label: 'Messages processed'

define root view entity ZR_PRC_Message
  as select from zprc_proc_step             as _Message

    inner join   ZI_PRC_ObjectLatestMessage as _LatestMessage   on  _Message.processed_object_uuid = _LatestMessage.ProcessedObjectUUID
                                                                and _Message.created_at            = _LatestMessage.LatestCreatedAt

    inner join   zprc_proc_object           as _ProcessedObject on _Message.processed_object_uuid = _ProcessedObject.uuid

  composition [*] of ZR_PRC_ObjectForMessage     as _ObjectsForMessage
  association [0..1] to ZI_PRC_MessageSeverityVH as _MessageSeverity on $projection.MessageSeverity = _MessageSeverity.Value

{
  key _Message.msgid            as MessageClass,
  key _Message.msgno            as MessageNumber,

      @ObjectModel.foreignKey.association: '_MessageSeverity'
  key _Message.msgty            as MessageSeverity,

  key _Message.msgv1            as MessageVariable1,
  key _Message.msgv2            as MessageVariable2,
  key _Message.msgv3            as MessageVariable3,
  key _Message.msgv4            as MessageVariable4,
  key _Message.message_text     as MessageText,

  key _ProcessedObject.process_name as ProcessName,

      count(*)                  as AffectedObjectCount,

      case _Message.msgty
          when 'E' then 1
          when 'W' then 2
          when 'S' then 3
          when 'I' then 5
          else 0
      end                       as MessageSeverityCode,

      _ObjectsForMessage,
      _MessageSeverity
}

group by
  _Message.msgid,
  _Message.msgno,
  _Message.msgty,
  _Message.msgv1,
  _Message.msgv2,
  _Message.msgv3,
  _Message.msgv4,
  _Message.message_text,
  _ProcessedObject.process_name
