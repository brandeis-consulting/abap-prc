@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Messages processed'
@Metadata.allowExtensions: true
@Search.searchable: true

define root view entity ZC_PRC_Message
  provider contract transactional_query
  as projection on ZR_PRC_Message

{
  key MessageClass,
  key MessageNumber,
  key MessageSeverity,
  key MessageVariable1,
  key MessageVariable2,
  key MessageVariable3,
  key MessageVariable4,

      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.7
  key MessageText         as MessageText,
  key ProcessName         as ProcessName,
      MessageSeverityCode as MessageSeverityCode,
      AffectedObjectCount,
      
     _ObjectsForMessage : redirected to ZC_PRC_ObjectForMessage
}
