@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Latest Message per Object'

define view entity ZI_PRC_ObjectLatestMessage
  as select from ZR_PRC_ProcessedStep 
{
  ProcessedObjectUUID as ProcessedObjectUUID,
  _ProcessedObject.ExternalProcessedObjectID,
  max(CreatedAt)      as LatestCreatedAt
}
group by
  ProcessedObjectUUID,
  _ProcessedObject.ExternalProcessedObjectID
