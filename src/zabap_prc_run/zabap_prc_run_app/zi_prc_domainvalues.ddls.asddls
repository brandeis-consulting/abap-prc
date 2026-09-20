@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZI_PRC_DomainValues
  with parameters
    p_domain_name : sxco_ad_object_name

  as select from DDCDS_CUSTOMER_DOMAIN_VALUE(
                   p_domain_name : $parameters.p_domain_name) as DomainValue

  association [0..*] to DDCDS_CUSTOMER_DOMAIN_VALUE_T as _DomainValueText
    on  DomainValue.domain_name    = _DomainValueText.domain_name
    and DomainValue.value_position = _DomainValueText.value_position

{
      @ObjectModel.text.element: [ 'Text' ]
      @UI.textArrangement: #TEXT_FIRST
  key DomainValue.value_low as Value,

      @Semantics.text: true
      coalesce(
          _DomainValueText(p_domain_name: $parameters.p_domain_name)[1: language = $session.system_language].text,
          _DomainValueText(p_domain_name: $parameters.p_domain_name)[1: language = 'E'].text
          )                 as Text
}
