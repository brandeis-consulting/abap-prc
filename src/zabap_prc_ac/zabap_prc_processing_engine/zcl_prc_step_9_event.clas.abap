"! <p class="shorttext synchronized">ABAP-PRC: Step layer 9 - event</p>
"!
"! Outermost layer of the step level: only here every outcome of a step arrives
"! - success, business error, unexpected error, aborted session. If a step was
"! written, the changed event of the processed object is raised in a LUW of its
"! own after the step, so consumers read the committed state and the business
"! LUW stays free of EML of the engine.
"!
"! Nothing written - no lock, for example - means no event. An event that cannot
"! be raised does not change the result of the step.
CLASS zcl_prc_step_9_event DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_prc_processing_step.

    METHODS constructor IMPORTING i_inner TYPE REF TO zif_prc_processing_step.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mo_inner TYPE REF TO zif_prc_processing_step.
ENDCLASS.



CLASS zcl_prc_step_9_event IMPLEMENTATION.

  METHOD constructor.
    mo_inner = i_inner.
  ENDMETHOD.


  METHOD zif_prc_processing_step~execute.
    TRY.
        r_state = mo_inner->execute( EXPORTING i_state           = i_state
                                               i_message_handler = i_message_handler
                                     IMPORTING e_transition      = e_transition ).
      CATCH zcx_prc_unit_of_work_failed.
        " The layers inside write every failure themselves and never raise;
        " should one arrive anyway, nothing was written
        r_state = i_state.
    ENDTRY.

    IF r_state-LatestStepUUID = i_state-LatestStepUUID.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zr_prc_processedobjecttp PRIVILEGED
           ENTITY ProcessedObject
           EXECUTE triggerChangedEvent FROM VALUE #( ( %key-UUID = r_state-UUID ) )
           FAILED DATA(failed) ##NEEDED
           REPORTED DATA(reported) ##NEEDED.

    " Message app: the group of the previous header loses the object, the group of the
    " new header gains it - both rows are refreshed
    DATA lt_steps TYPE RANGE OF sysuuid_x16.
    lt_steps = VALUE #( sign = 'I' option = 'EQ' ( low = r_state-LatestStepUUID ) ).
    IF i_state-LatestStepUUID IS NOT INITIAL.
      APPEND VALUE #( sign = 'I' option = 'EQ' low = i_state-LatestStepUUID ) TO lt_steps.
    ENDIF.
    SELECT DISTINCT MessageClass, MessageNumber, MessageSeverity, MessageVariable1, MessageVariable2,
                    MessageVariable3, MessageVariable4, MessageText, ProcessName
      FROM zi_prc_headermessage WITH PRIVILEGED ACCESS
      WHERE StepUUID IN @lt_steps
      INTO TABLE @DATA(lt_groups).
    IF lt_groups IS NOT INITIAL.
      MODIFY ENTITIES OF zr_prc_messagetp
             ENTITY Message
             EXECUTE triggerChangedEvent FROM CORRESPONDING #( lt_groups )
             FAILED DATA(failed_message) ##NEEDED
             REPORTED DATA(reported_message) ##NEEDED.
    ENDIF.

    " The actions change no data; COMMIT WORK makes sure the LUW is closed and
    " the events are delivered
    COMMIT ENTITIES.
    COMMIT WORK.
    " TODO: an event that cannot be raised goes to the application log (only a refresh signal is lost)
  ENDMETHOD.

ENDCLASS.

