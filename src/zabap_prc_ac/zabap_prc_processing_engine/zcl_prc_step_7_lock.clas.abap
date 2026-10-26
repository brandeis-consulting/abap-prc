"! <p class="shorttext synchronized">ABAP-PRC: Step layer 7 - lock</p>
"!
"! Decides whether the object can be locked. Uses the lock object of the
"! processed object, shared with the unmanaged lock of the BO, so it collides
"! with every other editor - Fiori, another run, a job - without opening a RAP
"! transaction. Without a lock nothing happens and the state is returned
"! unchanged.
"!
"! With the lock set, the object is read fresh: if another run processed it in
"! the meantime (other state or other latest step), nothing happens either.
"! The lock ends with the commit or rollback of the step, at the latest with the
"! isolated session.
CLASS zcl_prc_step_7_lock DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_prc_processing_step.

    METHODS constructor IMPORTING i_inner TYPE REF TO zif_prc_processing_step.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mo_inner TYPE REF TO zif_prc_processing_step.

    "! ABAP_TRUE if the object on the database is still in the state the step starts from.
    METHODS is_unchanged IMPORTING i_state         TYPE zif_prc_processing_engine=>ty_state
                         RETURNING VALUE(r_result) TYPE abap_bool.
ENDCLASS.



CLASS zcl_prc_step_7_lock IMPLEMENTATION.

  METHOD constructor.
    mo_inner = i_inner.
  ENDMETHOD.


  METHOD zif_prc_processing_step~execute.
    r_state = i_state.

    " A missing lock object is a technical error: it leaves the step level
    " undeclared and the isolation writes it as failed step
    IF zcl_prc_object_lock=>enqueue( i_state-UUID ) = abap_false.
      " Locked by someone else: nothing happens
      RETURN.
    ENDIF.

    IF is_unchanged( i_state ) = abap_false.
      " Processed by someone else in the meantime: release the lock, nothing happens
      ROLLBACK ENTITIES.
      RETURN.
    ENDIF.

    " The state of the list is passed on, not the database row: the selection may
    " have reset the retry data (ignore retry scheduling)
    r_state = mo_inner->execute( EXPORTING i_state           = i_state
                                           i_message_handler = i_message_handler
                                 IMPORTING e_transition      = e_transition ).
  ENDMETHOD.


  METHOD is_unchanged.
    SELECT SINGLE FROM ZR_PRC_ProcessedObject
      FIELDS State, LatestStepUUID
      WHERE UUID = @i_state-UUID
      INTO @DATA(current)
      PRIVILEGED ACCESS.

    r_result = xsdbool(     sy-subrc               = 0
                        AND current-State          = i_state-State
                        AND current-LatestStepUUID = i_state-LatestStepUUID ).
  ENDMETHOD.

ENDCLASS.

