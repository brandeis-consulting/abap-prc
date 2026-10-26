@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Message - BO'
@Metadata.allowExtensions: true

define root view entity ZR_PRC_MessageTP
  as select from ZI_PRC_HeaderMessageGroup

  composition [0..*] of ZR_PRC_ObjectForMessageTP as _ObjectsForMessage
{
  key MessageClass,
  key MessageNumber,
  key MessageSeverity,
  key MessageVariable1,
  key MessageVariable2,
  key MessageVariable3,
  key MessageVariable4,
  key MessageText,
  key ProcessName,

      MessageSeverityCode,
      AffectedObjectCount,
      // 'X' = at least one object currently shows this message (default filter of the app)
      cast( case when AffectedObjectCount > 0 then 'X' else '' end as abap_boolean ) as HasAffectedObjects,

      _ObjectsForMessage,
      _MessageSeverity
}
