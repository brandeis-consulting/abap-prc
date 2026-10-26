"! Prepare step: reads the result of the run and the mail address of the user
"! who started it, puts the mail into the payload.
CLASS lcl_prepare DEFINITION INHERITING FROM zcl_prc_transition_handlr_base FINAL.
  PROTECTED SECTION.
    METHODS perform_transition REDEFINITION.
    METHODS get_success_message REDEFINITION.

  PRIVATE SECTION.
    DATA m_application_name TYPE zprc_run_app_name.
    DATA m_total            TYPE int8.
    DATA m_success          TYPE int8.
ENDCLASS.


CLASS lcl_prepare IMPLEMENTATION.

  METHOD perform_transition.
    DATA ls_payload TYPE zcl_prc_notification=>ty_payload.

    IF zcl_prc_notification=>payload_from_json( EXPORTING i_json    = c_payload_json
                                                IMPORTING e_payload = ls_payload ) = abap_false
       OR ls_payload-run_uuid IS INITIAL.
      MESSAGE e007(zprc_notification) INTO DATA(lv_dummy) ##NEEDED.
      get_message_handler( )->add_message_from_sy( ).
    ENDIF.

    " The notification is a technical part of the run: no authorization for the run needed
    SELECT SINGLE FROM ZI_PRC_Run WITH PRIVILEGED ACCESS
      FIELDS ApplicationName, JobName, JobStart, JobEnd, TotalNumber, NumberOfSuccess, NumberOfErrors, CreatedBy
      WHERE UUID = @ls_payload-run_uuid
      INTO @DATA(ls_run).
    IF sy-subrc <> 0.
      MESSAGE e009(zprc_notification) WITH zcl_prc_notification=>uuid_text( ls_payload-run_uuid ) INTO lv_dummy.
      get_message_handler( )->add_message_from_sy( ).
    ENDIF.
    m_application_name = ls_run-ApplicationName.
    m_total            = ls_run-TotalNumber.
    m_success          = ls_run-NumberOfSuccess.

    " Mail address of the user who started the run (released APIs, all kinds of users).
    " Two reads instead of the path \_AddrCurDefaultEmailAddress: WITH PRIVILEGED ACCESS does not
    " apply to the target of a path (I_AddrCurDefaultEmailAddress is PRIVILEGED_ONLY), and on
    " 2023 it is not allowed for a join.
    SELECT SINGLE FROM I_User WITH PRIVILEGED ACCESS
      FIELDS AddressPersonID, AddressID
      WHERE UserID = @ls_run-CreatedBy
      INTO @DATA(ls_user_address).
    SELECT SINGLE FROM I_AddrCurDefaultEmailAddress WITH PRIVILEGED ACCESS
      FIELDS EmailAddress
      WHERE AddressPersonID = @ls_user_address-AddressPersonID
        AND AddressID       = @ls_user_address-AddressID
      INTO @DATA(lv_mail_address).
    IF lv_mail_address IS INITIAL.
      MESSAGE e004(zprc_notification) WITH ls_run-CreatedBy INTO lv_dummy.
      get_message_handler( )->add_message_from_sy( ).
    ENDIF.

    DATA(lv_launchpad_url) = zcl_prc_notification=>launchpad_url( ).
    IF lv_launchpad_url IS INITIAL.
      MESSAGE w008(zprc_notification) INTO lv_dummy.
      get_message_handler( )->add_message_from_sy( ).
    ENDIF.

    DATA(lv_result) = COND string( WHEN ls_run-NumberOfErrors > 0 THEN `with errors` ELSE `successfully` ).
    DATA(lv_content) =
        |<p>The run of application <strong>{ zcl_prc_notification=>html( ls_run-ApplicationName ) }</strong> | &&
        |completed { lv_result }.</p>| &&
        zcl_prc_notification=>html_table(
            i_header = VALUE #( ( `Job` ) ( `Started` ) ( `Ended` ) ( `Total` ) ( `Successful` ) ( `With errors` ) )
            i_rows   = VALUE #( ( VALUE #( ( zcl_prc_notification=>html( ls_run-JobName ) )
                                           ( zcl_prc_notification=>html( zcl_prc_notification=>timestamp_text( ls_run-JobStart ) ) )
                                           ( zcl_prc_notification=>html( zcl_prc_notification=>timestamp_text( ls_run-JobEnd ) ) )
                                           ( |{ ls_run-TotalNumber }| )
                                           ( |{ ls_run-NumberOfSuccess }| )
                                           ( |{ ls_run-NumberOfErrors }| ) ) ) ) ) &&
        |<p>| && zcl_prc_notification=>html_link(
                     i_launchpad_url = lv_launchpad_url
                     i_intent        = `ABAP_PRC_Run-show`
                     i_parameters    = |UUID={ zcl_prc_notification=>uuid_text( ls_payload-run_uuid ) }|
                     i_text          = `Show the run in the Processing Center` ) && |</p>|.

    ls_payload-notification = VALUE #(
        recipient = lv_mail_address
        subject   = |ABAP Processing Center: run of { ls_run-ApplicationName } completed { lv_result }|
        body_html = zcl_prc_notification=>html_document( i_headline = |Run of { ls_run-ApplicationName } completed { lv_result }|
                                                         i_content  = lv_content ) ).

    c_payload_json = zcl_prc_notification=>payload_to_json( ls_payload ).
    r_new_state = zcl_prc_notification=>co_prepared.
  ENDMETHOD.

  METHOD get_success_message.
    MESSAGE s005(zprc_notification) WITH m_application_name m_success m_total INTO DATA(lv_dummy) ##NEEDED.
    r_message = sy_message( ).
  ENDMETHOD.
ENDCLASS.
