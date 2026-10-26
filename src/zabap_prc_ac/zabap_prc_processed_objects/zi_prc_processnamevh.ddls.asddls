@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Available application Names'
@Search.searchable: true
// Reads the table directly: a view on ZI_/ZR_PRC_ProcessedObject inherits the
// value help annotation of ProcessName and would point to itself (dump in the app).
define view entity ZI_PRC_ProcessNameVH
  as select distinct from zprc_proc_object
{
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.6
  key process_name as ProcessName
}
