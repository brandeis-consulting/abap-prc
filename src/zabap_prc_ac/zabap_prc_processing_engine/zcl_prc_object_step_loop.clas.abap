"! <p class="shorttext synchronized">ABAP-PRC: Object level - step loop</p>
"!
"! Drives one object step by step, with a fresh message handler per step. Stops
"! on a criterion read from the processed object alone:
"! <ul>
"! <li>FINISHED reached,</li>
"! <li>error: the failure layer set retry data (RetryCount > 0),</li>
"! <li>nothing happened: no new step written (LatestStepUUID unchanged).</li>
"! </ul>
CLASS zcl_prc_object_step_loop DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_prc_processing_object.

    "! @parameter i_step | Outermost layer of the step level.
    METHODS constructor IMPORTING i_step TYPE REF TO zif_prc_processing_step.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mo_step TYPE REF TO zif_prc_processing_step.
ENDCLASS.



CLASS zcl_prc_object_step_loop IMPLEMENTATION.

  METHOD constructor.
    mo_step = i_step.
  ENDMETHOD.


  METHOD zif_prc_processing_object~process.
    r_state = i_state.

    DO.
      DATA(before) = r_state.
      TRY.
          r_state = mo_step->execute(
                        i_state           = before
                        i_message_handler = zcl_prc_message_handler=>create_message_handler( ) ).
        CATCH zcx_prc_unit_of_work_failed.
          " The step level never raises; should it happen anyway, stop driving the object
          RETURN.
      ENDTRY.

      IF    r_state-State           = zif_prc_process=>co_finished
         OR r_state-RetryCount      > 0
         OR r_state-LatestStepUUID  = before-LatestStepUUID.
        RETURN.
      ENDIF.
    ENDDO.
  ENDMETHOD.

ENDCLASS.

