@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Users of processed objects per process'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType: { serviceQuality: #B, sizeCategory: #M, dataClass: #TRANSACTIONAL }

// Every user who created or last changed a processed object, per process.
// Basis of the user value help; the process name carries the authorization.
define view entity ZI_PRC_ProcessedObjectUser
  as select distinct from zprc_proc_object
{
  key created_by   as UserID,
  key process_name as ProcessName
}
where
  created_by <> ''

union

select distinct from zprc_proc_object
{
  key last_changed_by as UserID,
  key process_name    as ProcessName
}
where
  last_changed_by <> ''
