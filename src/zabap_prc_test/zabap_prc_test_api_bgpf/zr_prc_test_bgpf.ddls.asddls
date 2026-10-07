@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PRC Test: BO bgPF aus adjust_numbers'
define root view entity ZR_PRC_Test_Bgpf
  as select from zprc_test_bgpf
{
  key id                    as ID,

      @Semantics.user.createdBy: true
      created_by            as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,

      @Semantics.user.localInstanceLastChangedBy: true
      last_changed_by       as LastChangedBy,

      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt
}
