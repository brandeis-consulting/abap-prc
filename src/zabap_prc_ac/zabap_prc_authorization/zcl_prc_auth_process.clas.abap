"! <p class="shorttext synchronized">ABAP-PRC: Authorization checks for object ZPRC_PROC</p>
"! Central place for all checks against authorization object ZPRC_PROC
"! (fields ACTVT and ZPRCNAME). Used by the RAP behavior implementations
"! of the processed objects and by the jobs of the processing center.
"! <p class="shorttext synchronized">ABAP-PRC: Authorization checks for object ZPRC_PROC</p>
"! Central place for all checks against authorization object ZPRC_PROC
"! (fields ACTVT and ZPRCNAME). Used by the RAP behavior implementations
"! of the processed objects and by the jobs of the processing center.
CLASS zcl_prc_auth_process DEFINITION
  PUBLIC FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    TYPES ty_activity TYPE c LENGTH 2.

    CONSTANTS co_auth_object TYPE c LENGTH 10 VALUE 'ZPRC_PROC'.

    CONSTANTS:
      BEGIN OF co_activity,
        "! Create processed objects (createProcessedObject)
        create  TYPE ty_activity VALUE '01',
        "! Change processed objects (technical, direct EML access)
        change  TYPE ty_activity VALUE '02',
        "! Display processed objects, steps and messages
        display TYPE ty_activity VALUE '03',
        "! Delete processed objects
        delete  TYPE ty_activity VALUE '06',
        "! Execute / resume processing (also retry job)
        execute TYPE ty_activity VALUE '16',
      END OF co_activity.

    "! Checks the authorization of the current user for a process
    "! @parameter i_process_name | Name of the process
    "! @parameter i_activity     | Activity, see CO_ACTIVITY
    "! @parameter r_authorized   | ABAP_TRUE if the user is authorized
    CLASS-METHODS is_authorized
      IMPORTING i_process_name      TYPE zprc_process_name
                i_activity          TYPE ty_activity
      RETURNING VALUE(r_authorized) TYPE abap_bool.

    "! Same check as IS_AUTHORIZED, result in the format of a RAP
    "! authorization result (if_abap_behv=>auth-allowed / -unauthorized)
    "! Same check as IS_AUTHORIZED, result in the format of a RAP
    "! authorization result (if_abap_behv=>auth-allowed / -unauthorized).
    "! Typed with the released IF_ABAP_BEHV=>T_XFLAG (technically the same as
    "! ABP_BEHV_AUTH, which is not released for ABAP Cloud in 2023).
    CLASS-METHODS get_behv_authorization
      IMPORTING i_process_name  TYPE zprc_process_name
                i_activity      TYPE ty_activity
      RETURNING VALUE(r_result) TYPE if_abap_behv=>t_xflag.

ENDCLASS.


CLASS zcl_prc_auth_process IMPLEMENTATION.
  METHOD is_authorized.
    AUTHORITY-CHECK OBJECT 'ZPRC_PROC'
                    ID 'ZPRCNAME' FIELD i_process_name
                    ID 'ACTVT'    FIELD i_activity.
    r_authorized = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD get_behv_authorization.
    r_result = COND #( WHEN is_authorized( i_process_name = i_process_name
                                           i_activity     = i_activity )
                       THEN if_abap_behv=>auth-allowed
                       ELSE if_abap_behv=>auth-unauthorized ).
  ENDMETHOD.
ENDCLASS.
