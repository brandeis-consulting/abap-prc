@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Run - Simulation flag'
@ObjectModel.usageType: { serviceQuality: #A, sizeCategory: #M, dataClass: #TRANSACTIONAL }

// Simulation flag of a run for the processed objects. Reads the table directly:
// a path over ZI_PRC_Run would close the cycle ZI_PRC_Run -> ZR_PRC_RunProgress
// -> ZR_PRC_ProcessedObject -> ZI_PRC_ProcessedObject.
define view entity ZI_PRC_RunSimulation
  as select from zprc_run
{
  key uuid       as RunUUID,
      simulation as Simulation
}
