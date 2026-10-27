@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Available States'
@Search.searchable: true
// Reads the table directly: a view on ZR_PRC_ProcessedObject inherits the
// value help annotation of State and would point to itself (dump in the app).
define view entity ZI_PRC_StateVH
  as select distinct from zprc_proc_object
{
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.6
  key state as State
}
