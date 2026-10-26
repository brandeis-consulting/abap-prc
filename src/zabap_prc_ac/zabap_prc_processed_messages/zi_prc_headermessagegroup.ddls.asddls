@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Header Messages Grouped'
@Metadata.allowExtensions: true
@ObjectModel.usageType: { serviceQuality: #C, sizeCategory: #L, dataClass: #TRANSACTIONAL }

// Header messages per process over all steps; the count only includes objects whose
// current (latest) header is this message. Groups with count 0 stay readable, so the
// event side effect after a resume finds the row; the app hides them by default.
define view entity ZI_PRC_HeaderMessageGroup
  as select from ZI_PRC_HeaderMessage

  association [0..*] to ZI_PRC_LatestHeaderMessage as _ObjectsForMessage on  $projection.ProcessName      = _ObjectsForMessage.ProcessName
                                                                         and $projection.MessageClass     = _ObjectsForMessage.MessageClass
                                                                         and $projection.MessageNumber    = _ObjectsForMessage.MessageNumber
                                                                         and $projection.MessageSeverity  = _ObjectsForMessage.MessageSeverity
                                                                         and $projection.MessageVariable1 = _ObjectsForMessage.MessageVariable1
                                                                         and $projection.MessageVariable2 = _ObjectsForMessage.MessageVariable2
                                                                         and $projection.MessageVariable3 = _ObjectsForMessage.MessageVariable3
                                                                         and $projection.MessageVariable4 = _ObjectsForMessage.MessageVariable4
                                                                         and $projection.MessageText      = _ObjectsForMessage.MessageText
  association [0..1] to ZI_PRC_MessageSeverityVH   as _MessageSeverity   on  $projection.MessageSeverity = _MessageSeverity.Value
{
  key MessageClass,
  key MessageNumber,
      @ObjectModel.foreignKey.association: '_MessageSeverity'
  key MessageSeverity,
  key MessageVariable1,
  key MessageVariable2,
  key MessageVariable3,
  key MessageVariable4,
  key MessageText,
  key ProcessName,

      MessageSeverityCode,
      sum( IsLatestHeader ) as AffectedObjectCount,

      _ObjectsForMessage,
      _MessageSeverity
}
group by
  MessageClass,
  MessageNumber,
  MessageSeverity,
  MessageVariable1,
  MessageVariable2,
  MessageVariable3,
  MessageVariable4,
  MessageText,
  ProcessName,
  MessageSeverityCode
