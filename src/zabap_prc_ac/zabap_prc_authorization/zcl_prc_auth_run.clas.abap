"! <p class="shorttext synchronized">ABAP-PRC: Authorization checks for object ZPRC_RUN</p>
"! Central place for all checks against authorization object ZPRC_RUN
"! (fields ACTVT and ZPRCRUNAPP). Used by the RAP behavior implementation
"! of the runs.
"! <p class="shorttext synchronized">ABAP-PRC: Authorization checks for object ZPRC_RUN</p>
"! Central place for all checks against authorization object ZPRC_RUN
"! (fields ACTVT and ZPRCRUNAPP). Used by the RAP behavior implementation
"! of the runs.
"! <p class="shorttext synchronized">ABAP-PRC: Authorization checks for object ZPRC_RUN</p>
"! Central place for all checks against authorization object ZPRC_RUN
"! (fields ACTVT and ZPRCRUNAPP). Used by the RAP behavior implementation
"! of the runs.
CLASS zcl_prc_auth_run DEFINITION
  PUBLIC FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    TYPES ty_activity TYPE c LENGTH 2.

    CONSTANTS co_auth_object TYPE c LENGTH 10 VALUE 'ZPRC_RUN'.

    CONSTANTS:
      BEGIN OF co_activity,
        "! Create runs (create, initiateRun)
        create  TYPE ty_activity VALUE '01',
        "! Change runs (update, trigger changed event)
        change  TYPE ty_activity VALUE '02',
        "! Display runs
        display TYPE ty_activity VALUE '03',
        "! Delete runs
        delete  TYPE ty_activity VALUE '06',
      END OF co_activity.

    "! Checks the authorization of the current user for an application
    "! @parameter i_application_name | Name of the application applying the run pattern
    "! @parameter i_activity         | Activity, see CO_ACTIVITY
    "! @parameter r_authorized       | ABAP_TRUE if the user is authorized
    CLASS-METHODS is_authorized
      IMPORTING i_application_name  TYPE zprc_run_app_name
                i_activity          TYPE ty_activity
      RETURNING VALUE(r_authorized) TYPE abap_bool.

    "! Same check as IS_AUTHORIZED, result in the format of a RAP
    "! authorization result (if_abap_behv=>auth-allowed / -unauthorized)
    CLASS-METHODS get_behv_authorization
      IMPORTING i_application_name TYPE zprc_run_app_name
                i_activity         TYPE ty_activity
      RETURNING VALUE(r_result)    TYPE abp_behv_auth.

ENDCLASS.


CLASS zcl_prc_auth_run IMPLEMENTATION.
  METHOD is_authorized.
    AUTHORITY-CHECK OBJECT 'ZPRC_RUN'
                    ID 'ZPRCRUNAPP' FIELD i_application_name
                    ID 'ACTVT'      FIELD i_activity.
    r_authorized = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD get_behv_authorization.
    r_result = COND #( WHEN is_authorized( i_application_name = i_application_name
                                           i_activity         = i_activity )
                       THEN if_abap_behv=>auth-allowed
                       ELSE if_abap_behv=>auth-unauthorized ).
  ENDMETHOD.
ENDCLASS.
