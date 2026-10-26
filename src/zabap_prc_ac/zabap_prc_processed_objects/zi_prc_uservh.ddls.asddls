@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Users of processed objects'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.dataCategory: #VALUE_HELP
@ObjectModel.usageType: { serviceQuality: #B, sizeCategory: #M, dataClass: #TRANSACTIONAL }
@Search.searchable: true

// Value help for CreatedBy / LastChangedBy: only users who appear on processed objects
// (technical users included). Name from the released I_BusinessUserVH, if the user is a business user.
define view entity ZI_PRC_UserVH
  as select from    ZI_PRC_ProcessedObjectUser as ObjectUser
    left outer join I_BusinessUserVH           as BusinessUser on BusinessUser.UserID = ObjectUser.UserID

  association [1..*] to ZI_PRC_ProcessedObjectUser as _ObjectUser on $projection.UserID = _ObjectUser.UserID
{
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      @ObjectModel.text.element: [ 'PersonFullName' ]
      @EndUserText.label: 'User'
  key ObjectUser.UserID,

      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.7
      @Semantics.text: true
      @EndUserText.label: 'Name'
      BusinessUser.PersonFullName,

      // authorization only: users of processes the viewer may display
      @UI.hidden: true
      _ObjectUser
}
group by
  ObjectUser.UserID,
  BusinessUser.PersonFullName
