@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Run Parameter - Basic'
@Metadata.allowExtensions: true
@ObjectModel.usageType: { serviceQuality: #A, sizeCategory: #M, dataClass: #TRANSACTIONAL }

define view entity ZI_PRC_RunParameter
  as select from zprc_run_params as RunParams

  association [1..1] to ZI_PRC_Run as _Run on $projection.JobUUID = _Run.UUID
{
  key uuid           as UUID,

      job_uuid       as JobUUID,
      parameter_name as ParameterName,
      operator       as Operator,
      sign           as Sign,
      low            as Low,
      high           as High,

      _Run
}
