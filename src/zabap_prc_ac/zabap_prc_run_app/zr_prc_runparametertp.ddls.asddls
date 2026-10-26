@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Run Parameter - BO'
@Metadata.allowExtensions: true

define view entity ZR_PRC_RunParameterTP
  as select from ZI_PRC_RunParameter

  association to parent ZR_PRC_RunTP as _Run on $projection.JobUUID = _Run.UUID
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
