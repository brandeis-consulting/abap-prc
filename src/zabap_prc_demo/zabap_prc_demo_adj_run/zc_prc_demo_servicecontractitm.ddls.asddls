@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Service Contract Item'
@Metadata.allowExtensions: true
//@Search.searchable: true

define view entity ZC_PRC_DEMO_ServiceContractItm
  provider contract transactional_query
  as projection on ZR_PRC_DEMO_ServiceContractItm as ServiceContractItem
{
  key UUID,

      ParentUUID,
      ItemNumber,
      ProductId,
      Quantity,
      QuantityUom,
      Currency,
      NetPrice,
      DiscountPercent,
      EquipmentId,
      _ServiceContract: redirected to ZC_PRC_DEMO_ServiceContract,
      _Material
}
