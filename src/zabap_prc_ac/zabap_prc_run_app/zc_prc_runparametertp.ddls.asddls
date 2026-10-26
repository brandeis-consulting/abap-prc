@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Run Parameter'
@Metadata.allowExtensions: true

@UI.headerInfo: { typeName: 'Run Parameter',
                  typeNamePlural: 'Run Parameters',
                  title: { type: #STANDARD, value: 'ParameterName' } }

define view entity ZC_PRC_RunParameterTP
  as projection on ZR_PRC_RunParameterTP
{
  key UUID,

      JobUUID,
      ParameterName,
      Operator,
      Sign,
      Low,
      High,

      _Run : redirected to parent ZC_PRC_RunTP
}
