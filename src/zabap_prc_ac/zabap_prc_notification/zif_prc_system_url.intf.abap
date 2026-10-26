"! <p class="shorttext synchronized">ABAP-PRC: System URL for links in mails</p>
"!
"! Mails link into the Fiori launchpad. In the cloud the system URL comes from
"! CL_ABAP_CONTEXT_INFO=>GET_SYSTEM_URL; on premise and in the private cloud that
"! is empty. There the ICM knows the host: reading it is Standard ABAP, so the
"! implementation lives in a Standard ABAP package, is released (C1) and is
"! created dynamically (like the dump finder). Without it the mails go out
"! without links (warning ZPRC_NOTIFICATION/008).
INTERFACE zif_prc_system_url PUBLIC.

  CONSTANTS co_implementation TYPE string VALUE `ZCL_PRC_SYSTEM_URL`.

  "! Base URL of the system, e.g. https://host:44300.
  "!
  "! @parameter r_url | Protocol, host and port; initial if unknown.
  METHODS get_system_url RETURNING VALUE(r_url) TYPE string.

ENDINTERFACE.
