@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Service Contract'

@Metadata.allowExtensions: true

@Search.searchable: true

define root view entity ZC_PRC_DEMO_ServiceContract
  provider contract transactional_query
  as projection on ZR_PRC_DEMO_ServiceContract as ServiceContract

{
  key UUID,

      @ObjectModel.text.element: [ 'Description' ]
      ServiceContractID       as S_CTR,

      Description,

      @Search.defaultSearchElement: true
      SoldToPartyID           as S_SOLD,

      ShipToPartyID           as S_SHIP,
      LifecycleStatus         as S_LIFE,

      @Search.defaultSearchElement: true
      ErrorStatus             as S_ERR,

      ErrorStatusCriticality,

      LocalCreatedBy,
      LocalCreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,
      _ServiceContractItem : redirected to ZC_PRC_DEMO_ServiceContractItm,

      @Search.defaultSearchElement: true
      _ShipToParty,

      @Search.defaultSearchElement: true
      _SoldToParty,

      @Search.defaultSearchElement: true
      _LifecycleStatus,

      //      @Search.defaultSearchElement: true
      _ErrorStatus
}
