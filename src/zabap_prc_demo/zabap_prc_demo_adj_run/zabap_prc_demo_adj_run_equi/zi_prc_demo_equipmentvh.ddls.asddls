@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Equipment Value Help'
@Metadata.allowExtensions: true
@Search.searchable: true

@ObjectModel.resultSet.sizeCategory: #XS
@ObjectModel.dataCategory: #VALUE_HELP

// Read-only view on the equipment root entity.
// Exists so that consumers outside the equipment business object
// (e.g. the service contract model) can associate to equipment
// without pointing at the transactional projection ZC_PRC_DEMO_Equipment.
define view entity ZI_PRC_DEMO_EquipmentVH
  as select from ZR_PRC_DEMO_Equipment as Equipment
  association [0..1] to ZC_PRC_DEMO_EquipmentCategory as _EquipmentCategory on $projection.EquipmentCategory = _EquipmentCategory.Identifier
{
      @Search.defaultSearchElement: true
  key Identifier,

      @Search.defaultSearchElement: true
      @ObjectModel.foreignKey.association: '_EquipmentCategory'
      EquipmentCategory,

      _EquipmentCategory
}
