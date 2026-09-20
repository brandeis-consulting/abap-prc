@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Service Contract'

@Metadata.allowExtensions: true

@Search.searchable: true

define root view entity ZR_PRC_DEMO_ServiceContract
  as select from ZI_PRC_DEMO_ServiceContract as ServiceContract

  composition [0..*] of ZR_PRC_DEMO_ServiceContractItm as _ServiceContractItem

{
  key UUID                    as UUID,

      ServiceContractID,
      Description,
      SoldToPartyID,
      ShipToPartyID,
      LifecycleStatus,
      ErrorStatus,
      ErrorStatusCriticality,
      LocalCreatedBy,
      LocalCreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,

      _ServiceContractItem,
      _ShipToParty,
      _SoldToParty,
      _LifecycleStatus,
      _ErrorStatus
}
