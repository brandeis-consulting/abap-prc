@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Service Contract'
@Metadata.allowExtensions: true
@Search.searchable: true

define root view entity ZI_PRC_DEMO_ServiceContract
  as select from zprc_demo_srvctr as ServiceContract

  association [0..1] to ZC_PRC_DEMO_BusinessPartner as _ShipToParty     on $projection.ShipToPartyID = _ShipToParty.Identifier
  association [0..1] to ZC_PRC_DEMO_BusinessPartner as _SoldToParty     on $projection.SoldToPartyID = _SoldToParty.Identifier
  association [0..1] to ZI_PRC_DEMO_LifecycleStatus as _LifecycleStatus on $projection.LifecycleStatus = _LifecycleStatus.Value
  association [0..1] to ZI_PRC_DEMO_ErrorStatus     as _ErrorStatus     on $projection.ErrorStatus = _ErrorStatus.Value

{
  key uuid                                         as UUID,

      service_contract_id                          as ServiceContractID,

      @Search.defaultSearchElement: true
      description                                  as Description,

      @ObjectModel.foreignKey.association: '_SoldToParty'
      sold_to_party_id                             as SoldToPartyID,

      @ObjectModel.foreignKey.association: '_ShipToParty'
      ship_to_party_id                             as ShipToPartyID,

      @ObjectModel.foreignKey.association: '_LifecycleStatus'
      lifecycle_status                             as LifecycleStatus,

      @ObjectModel.foreignKey.association: '_ErrorStatus'
      error_status                                 as ErrorStatus,

      case error_status when 'E' then 1 else 3 end as ErrorStatusCriticality,


      local_created_by                             as LocalCreatedBy,
      local_created_at                             as LocalCreatedAt,
      local_last_changed_by                        as LocalLastChangedBy,
      local_last_changed_at                        as LocalLastChangedAt,
      last_changed_at                              as LastChangedAt,

      _ShipToParty,
      _SoldToParty,
      _LifecycleStatus,
      _ErrorStatus
}
