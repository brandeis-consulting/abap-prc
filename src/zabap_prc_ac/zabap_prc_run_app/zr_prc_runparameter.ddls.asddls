@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Parameter for run'

// Read view for existing consumers; the run BO is ZR_PRC_RunTP
define view entity ZR_PRC_RunParameter
  as select from ZI_PRC_RunParameter
  association [1..1] to ZR_PRC_Run as _Run on $projection.JobUUID = _Run.UUID
{
  key UUID,
      JobUUID,
      ParameterName,
      Operator,
      Sign,
      Low,
      High,

      _Run
}
