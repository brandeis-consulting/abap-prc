"! <p class="shorttext synchronized">ABAP-PRC: Lock on a processed object</p>
"!
"! The one lock of a processed object, set by the BO (unmanaged lock) and by
"! the processing engine alike, so both collide. A classic lock object: unlike
"! SET LOCKS it opens no RAP transaction, so update function modules of classic
"! BAPIs stay allowed in the step.
"!
"! The lock ends with the LUW - commit or rollback - or with the session.
CLASS zcl_prc_object_lock DEFINITION PUBLIC FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    CONSTANTS co_lock_object TYPE string VALUE `EZPRC_PROC_OBJ`.

    "! Sets the exclusive lock of a processed object.
    "!
    "! @parameter i_uuid             | Processed object.
    "! @parameter r_locked           | ABAP_TRUE if the lock is set, ABAP_FALSE if someone else holds it.
    "! @raising   cx_abap_lock_failure | The lock object is not available.
    CLASS-METHODS enqueue IMPORTING i_uuid          TYPE sysuuid_x16
                          RETURNING VALUE(r_locked) TYPE abap_bool
                          RAISING   cx_abap_lock_failure.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_prc_object_lock IMPLEMENTATION.

  METHOD enqueue.
    DATA(lock) = cl_abap_lock_object_factory=>get_instance( iv_name = CONV #( co_lock_object ) ).
    TRY.
        lock->enqueue( it_parameter = VALUE #( ( name = 'UUID' value = REF #( i_uuid ) ) ) ).
        r_locked = abap_true.
      CATCH cx_abap_foreign_lock.
        r_locked = abap_false.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.

