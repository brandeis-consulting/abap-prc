"! <p class="shorttext synchronized">ABAP-PRC: Object level - run bookkeeping</p>
"!
"! Signals the change of the run of an object once the object is done for now -
"! FINISHED, failed or stopped - and only if a step was written. The run figures
"! are computed by CDS, so the event is a refresh signal only and the run is
"! never updated. Raised in a LUW of its own, so the run app refreshes after
"! every object, as with the former engine.
"!
"! An event that cannot be raised does not change the result of the object.
CLASS zcl_prc_object_run DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_prc_processing_object.

    "! @parameter i_inner | Object level inside: the step loop.
    METHODS constructor IMPORTING i_inner TYPE REF TO zif_prc_processing_object.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA mo_inner TYPE REF TO zif_prc_processing_object.
ENDCLASS.



CLASS zcl_prc_object_run IMPLEMENTATION.

  METHOD constructor.
    mo_inner = i_inner.
  ENDMETHOD.


  METHOD zif_prc_processing_object~process.
    r_state = mo_inner->process( i_state ).

    " Only with a run and at least one written step
    IF r_state-RunUUID IS INITIAL OR r_state-LatestStepUUID = i_state-LatestStepUUID.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zr_prc_runtp PRIVILEGED
           ENTITY Run
           EXECUTE triggerChangedEvent FROM VALUE #( ( %key-uuid = r_state-RunUUID ) )
           FAILED DATA(failed) ##NEEDED
           REPORTED DATA(reported) ##NEEDED.
    " The action changes no data; COMMIT WORK makes sure the LUW is closed and
    " the event is delivered
    COMMIT ENTITIES.
    COMMIT WORK.
    " TODO: an event that cannot be raised goes to the application log (only a refresh signal is lost)
  ENDMETHOD.

ENDCLASS.
