"! <p class="shorttext synchronized">ABAP-PRC: System URL from the ICM (Standard ABAP)</p>
"!
"! Implementation of ZIF_PRC_SYSTEM_URL for on premise and private cloud: the
"! HTTPS location (else HTTP) the ICM reports for this system, as configured in
"! transaction SICF / table HTTPURLLOC or the profile. Released (C1) so the
"! notification (ABAP Cloud) can create it dynamically.
CLASS zcl_prc_system_url DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_prc_system_url.
ENDCLASS.



CLASS zcl_prc_system_url IMPLEMENTATION.

  METHOD zif_prc_system_url~get_system_url.
    DATA lv_host     TYPE string.
    DATA lv_port     TYPE string.
    DATA lv_protocol TYPE string.

    " HTTPS first: links in mails should not point to plain HTTP if HTTPS is there
    cl_http_server=>if_http_server~get_location( EXPORTING protocol     = 'https'
                                                 IMPORTING host         = lv_host
                                                           port         = lv_port
                                                           out_protocol = lv_protocol ).
    IF lv_host IS INITIAL.
      cl_http_server=>if_http_server~get_location( IMPORTING host         = lv_host
                                                             port         = lv_port
                                                             out_protocol = lv_protocol ).
    ENDIF.
    IF lv_host IS INITIAL.
      RETURN.
    ENDIF.

    IF lv_protocol IS INITIAL.
      lv_protocol = `https`.
    ENDIF.
    r_url = |{ to_lower( lv_protocol ) }://{ lv_host }|.
    IF lv_port IS NOT INITIAL.
      r_url = |{ r_url }:{ lv_port }|.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
