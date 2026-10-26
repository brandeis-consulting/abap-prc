@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Run Parameter'
@Metadata.allowExtensions: true

define view entity ZC_PRC_RunParameter
  as projection on ZR_PRC_RunParameterTP
{
  key UUID,
      JobUUID,
      ParameterName,
      Operator,
      Sign,
      Low,
      High,

      _Run : redirected to parent ZC_PRC_Run
}
