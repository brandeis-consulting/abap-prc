@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Service Contract'

@Metadata.allowExtensions: true

define root view entity ZI_PRC_DEMO_ServiceContractItm
  as select from zprc_demo_sc_itm as ServiceContractItem

  association [0..1] to ZC_PRC_DEMO_Material    as _Material  on $projection.ProductId = _Material.Identifier
  association [0..1] to ZI_PRC_DEMO_EquipmentVH as _Equipment on $projection.EquipmentId = _Equipment.Identifier

{
  key uuid             as UUID,

      parent_uuid      as ParentUUID,
      item_number      as ItemNumber,

      @ObjectModel.foreignKey.association: '_Material'
      product_id       as ProductId,

      quantity         as Quantity,
      quantity_uom     as QuantityUom,
      currency         as Currency,
      net_price        as NetPrice,
      discount_percent as DiscountPercent,

      @ObjectModel.foreignKey.association: '_Equipment'
      equipment_id     as EquipmentId,

      _Equipment,
      _Material
}
