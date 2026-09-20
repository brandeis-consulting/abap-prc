@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Service Contract Item'
@Metadata.allowExtensions: true
//@Search.searchable: true

define view entity ZR_PRC_DEMO_ServiceContractItm
  as select from ZI_PRC_DEMO_ServiceContractItm as ServiceContractItem
  association to parent ZR_PRC_DEMO_ServiceContract as _ServiceContract on $projection.ParentUUID = _ServiceContract.UUID
{
  key UUID as UUID,

      ParentUUID,
      ItemNumber,

      ProductId,
      Quantity,
      QuantityUom,
      Currency,
      NetPrice,
      DiscountPercent,
      EquipmentId,

      _ServiceContract,
      _Equipment,
      _Material
}
