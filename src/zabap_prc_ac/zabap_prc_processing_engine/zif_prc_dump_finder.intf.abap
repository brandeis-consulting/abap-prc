"! <p class="shorttext synchronized">ABAP-PRC: Finds the short dump of an aborted step</p>
"!
"! The step session registers its EPP transaction ID under a marker before the
"! transition starts; every short dump of that session carries the same ID. If
"! the session aborts, the isolation layer looks the dump up by that ID - exact,
"! without knowing anything about the BAPI or the update function module.
"!
"! Reading the EPP data and the short dumps is Standard ABAP: the implementation
"! lives in a Standard ABAP package, is released (C1) and is created dynamically.
"! Without it (ABAP Cloud, BTP) the step carries the hint message only.
INTERFACE zif_prc_dump_finder PUBLIC.

  CONSTANTS co_implementation TYPE string VALUE `ZCL_PRC_DUMP_FINDER`.

  TYPES: BEGIN OF ty_dump,
           runtime_error TYPE string,
           program       TYPE string,
           short_text    TYPE string,
         END OF ty_dump.

  "! Registers the current session under the marker. Call in the step session,
  "! before anything can abort it.
  "!
  "! @parameter i_marker | Marker of the step.
  METHODS register_session IMPORTING i_marker TYPE sysuuid_x16.

  "! Drops the registration of a step that did not abort.
  "!
  "! @parameter i_marker | Marker of the step.
  METHODS forget IMPORTING i_marker TYPE sysuuid_x16.

  "! Finds the short dump of the registered session and drops the registration.
  "!
  "! @parameter i_marker  | Marker of the step.
  "! @parameter i_from    | Start of the step (UTC).
  "! @parameter r_dump    | The short dump; initial if there is none (MESSAGE A/E abort no session with a dump).
  METHODS find_dump IMPORTING i_marker      TYPE sysuuid_x16
                              i_from        TYPE timestampl
                    RETURNING VALUE(r_dump) TYPE ty_dump.

ENDINTERFACE.
