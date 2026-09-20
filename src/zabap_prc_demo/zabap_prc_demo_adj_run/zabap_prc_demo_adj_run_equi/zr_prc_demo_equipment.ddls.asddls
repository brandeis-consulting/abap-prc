@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Equipment'
@Metadata.allowExtensions: true
@Search.searchable: true

define root view entity ZR_PRC_DEMO_Equipment
  as select from zprc_demo_equi as Equipment
  association [0..1] to ZC_PRC_DEMO_EquipmentCategory as _EquipmentCategory on $projection.EquipmentCategory = _EquipmentCategory.Identifier
{
  key id                    as Identifier,

      @ObjectModel.foreignKey.association: '_EquipmentCategory'
      equipment_category_id as EquipmentCategory,

      @Semantics.user.createdBy: true
      created_by            as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by       as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,

      @Search.defaultSearchElement: true
      _EquipmentCategory
}
