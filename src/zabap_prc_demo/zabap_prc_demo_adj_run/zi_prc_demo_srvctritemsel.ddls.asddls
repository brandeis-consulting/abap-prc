@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Service Contract Items'
@Metadata.allowExtensions: true

define root view entity ZI_PRC_Demo_SrvCtrItemSel
  as select from ZI_PRC_DEMO_ServiceContractItm as ServiceContractItem
  association [1] to ZI_PRC_DEMO_ServiceContract as _ServiceContract on _ServiceContract.UUID = ServiceContractItem.ParentUUID
{

  key ServiceContractItem.UUID as ItemUUID,
      _ServiceContract.UUID as ContractUUID,
      _ServiceContract.ServiceContractID,
      _ServiceContract.SoldToPartyID,
      _ServiceContract.ShipToPartyID,
      _ServiceContract.LifecycleStatus,
      _ServiceContract.ErrorStatus,
      ServiceContractItem.ItemNumber,
      ServiceContractItem.ProductId,
      ServiceContractItem.Quantity,
      ServiceContractItem.QuantityUom,
      ServiceContractItem.Currency,
      ServiceContractItem.NetPrice,
      ServiceContractItem.DiscountPercent,
      ServiceContractItem.EquipmentId
}
