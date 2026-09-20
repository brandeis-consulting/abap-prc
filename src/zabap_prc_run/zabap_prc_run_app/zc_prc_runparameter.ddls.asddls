@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Run Parameter'
@Metadata.allowExtensions: true

define view entity ZC_PRC_RunParameter
  provider contract transactional_query
  as projection on ZR_PRC_RunParameter as Run

{
  key UUID,
      JobUUID,
      ParameterName,
      Operator,
      Sign,
      Low,
      High,
      /* Associations */
      _Run : redirected to ZC_PRC_Run
}
