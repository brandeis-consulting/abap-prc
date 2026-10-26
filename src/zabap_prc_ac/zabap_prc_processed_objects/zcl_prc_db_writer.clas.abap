"! <p class="shorttext synchronized">ABAP-PRC: Writes the PRC persistence</p>
CLASS zcl_prc_db_writer DEFINITION PUBLIC FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES zif_prc_db_writer.

    CLASS-METHODS create RETURNING VALUE(r_writer) TYPE REF TO zif_prc_db_writer.

  PRIVATE SECTION.
    TYPES tt_processed_object  TYPE STANDARD TABLE OF zprc_proc_object WITH EMPTY KEY.
    TYPES tt_processed_step    TYPE STANDARD TABLE OF zprc_proc_step WITH EMPTY KEY.
    TYPES tt_processed_message TYPE STANDARD TABLE OF zprc_proc_msg WITH EMPTY KEY.
    TYPES tt_uuid_range        TYPE RANGE OF sysuuid_x16.
    TYPES tt_state             TYPE STANDARD TABLE OF zif_prc_process=>ty_state WITH EMPTY KEY.
    TYPES: BEGIN OF ty_process,
             class_name  TYPE zprc_process_impl_class,
             transitions TYPE zif_prc_process=>tt_transition,
           END OF ty_process.

    DATA m_timestamp  TYPE timestampl.
    DATA m_user       TYPE abp_creation_user.
    "! Transitions per process class, filled once per class name
    DATA mt_processes TYPE HASHED TABLE OF ty_process WITH UNIQUE KEY class_name.

    METHODS save_processed_message IMPORTING i_create TYPE zif_prc_db_writer=>ty_create-processedmessage
                                             i_update TYPE zif_prc_db_writer=>ty_update-processedmessage
                                             i_delete TYPE zif_prc_db_writer=>ty_delete-processedmessage.

    METHODS save_processed_step    IMPORTING i_create TYPE zif_prc_db_writer=>ty_create-processedstep
                                             i_update TYPE zif_prc_db_writer=>ty_update-processedstep
                                             i_delete TYPE zif_prc_db_writer=>ty_delete-processedstep.

    METHODS save_processed_object  IMPORTING i_create    TYPE zif_prc_db_writer=>ty_create-processedobject
                                             i_update    TYPE zif_prc_db_writer=>ty_update-processedobject
                                             i_delete    TYPE zif_prc_db_writer=>ty_delete-processedobject
                                             i_new_steps TYPE zif_prc_db_writer=>ty_create-processedstep
                                   RAISING   cx_sy_create_object_error.

    METHODS derive_processed_object IMPORTING i_processed_object        TYPE zprc_proc_object
                                              i_new_steps               TYPE zif_prc_db_writer=>ty_create-processedstep
                                    RETURNING VALUE(r_processed_object) TYPE zprc_proc_object
                                    RAISING   cx_sy_create_object_error.

    METHODS get_transitions IMPORTING i_class_name         TYPE zprc_process_impl_class
                            RETURNING VALUE(r_transitions) TYPE zif_prc_process=>tt_transition
                            RAISING   cx_sy_create_object_error.

    "! Severity code as used for criticality: E 1, W 2, S 3, I 5. A and X count as error.
    METHODS get_severity_code IMPORTING i_severity    TYPE zprc_message_severity
                              RETURNING VALUE(r_code) TYPE zprc_message_severity_code.

    "! Number of transitions on the longest path without loops from the state to FINISHED.
    METHODS get_remaining_steps IMPORTING i_transitions  TYPE zif_prc_process=>tt_transition
                                          i_state        TYPE zif_prc_process=>ty_state
                                          i_visited      TYPE tt_state OPTIONAL
                                RETURNING VALUE(r_steps) TYPE int8.
ENDCLASS.



CLASS zcl_prc_db_writer IMPLEMENTATION.

  METHOD create.
    r_writer = NEW zcl_prc_db_writer( ).
  ENDMETHOD.


  METHOD zif_prc_db_writer~save.
    GET TIME STAMP FIELD m_timestamp.
    m_user = cl_abap_context_info=>get_user_technical_name( ).

    save_processed_message( i_create = i_create-processedmessage
                            i_update = i_update-processedmessage
                            i_delete = i_delete-processedmessage ).
    " Steps before objects: StepTotal counts the steps on the database
    save_processed_step( i_create = i_create-processedstep
                         i_update = i_update-processedstep
                         i_delete = i_delete-processedstep ).
    save_processed_object( i_create    = i_create-processedobject
                           i_update    = i_update-processedobject
                           i_delete    = i_delete-processedobject
                           i_new_steps = i_create-processedstep ).
  ENDMETHOD.


  METHOD save_processed_message.
    " Every message carries its object: no caller may leave it to the database
    ASSERT NOT line_exists( i_create[ ProcessedObjectUUID = VALUE #( ) ] ).

    IF i_delete IS NOT INITIAL.
      DATA(deleted) = VALUE tt_processed_message( FOR d IN i_delete ( uuid = d-UUID ) ).
      DELETE zprc_proc_msg FROM TABLE @deleted.
    ENDIF.

    DATA(created) = VALUE tt_processed_message(
        FOR c IN i_create
        LET row = CORRESPONDING zprc_proc_msg( c MAPPING FROM ENTITY ) IN
        ( VALUE #( BASE row
                   message_severity_code = get_severity_code( row-msgty )
                   created_by            = m_user
                   created_at            = m_timestamp ) ) ).
    INSERT zprc_proc_msg FROM TABLE @created.

    DATA(updated) = VALUE tt_processed_message(
        FOR u IN i_update
        LET row = CORRESPONDING zprc_proc_msg( u MAPPING FROM ENTITY ) IN
        ( VALUE #( BASE row message_severity_code = get_severity_code( row-msgty ) ) ) ).
    UPDATE zprc_proc_msg FROM TABLE @updated.
  ENDMETHOD.


  METHOD save_processed_step.
    IF i_delete IS NOT INITIAL.
      " A step takes its messages along
      DATA(deleted) = VALUE tt_uuid_range( FOR d IN i_delete
                                           ( sign = 'I' option = 'EQ' low = d-StepUUID ) ).
      DELETE FROM zprc_proc_msg  WHERE processed_step_uuid IN @deleted.
      DELETE FROM zprc_proc_step WHERE step_uuid           IN @deleted.
    ENDIF.

    " The step holds no header fields: its header is a message (IsHeader = 'X')
    DATA(created) = VALUE tt_processed_step(
        FOR c IN i_create
        LET row = CORRESPONDING zprc_proc_step( c MAPPING FROM ENTITY ) IN
        ( VALUE #( BASE row
                   created_by = m_user
                   created_at = m_timestamp ) ) ).
    INSERT zprc_proc_step FROM TABLE @created.

    DATA(updated) = VALUE tt_processed_step(
        FOR u IN i_update
        ( CORRESPONDING zprc_proc_step( u MAPPING FROM ENTITY ) ) ).
    UPDATE zprc_proc_step FROM TABLE @updated.
  ENDMETHOD.


  METHOD save_processed_object.
    IF i_delete IS NOT INITIAL.
      " An object takes its steps and messages along
      DATA(deleted) = VALUE tt_uuid_range( FOR d IN i_delete
                                           ( sign = 'I' option = 'EQ' low = d-UUID ) ).
      DELETE FROM zprc_proc_msg    WHERE processed_object_uuid IN @deleted.
      DELETE FROM zprc_proc_step   WHERE processed_object_uuid IN @deleted.
      DELETE FROM zprc_proc_object WHERE uuid                  IN @deleted.
    ENDIF.

    DATA(created) = VALUE tt_processed_object(
        FOR c IN i_create
        LET row = CORRESPONDING zprc_proc_object( c MAPPING FROM ENTITY ) IN
        ( derive_processed_object( i_new_steps        = i_new_steps
                                   i_processed_object = VALUE #( BASE row
                                                                 created_by            = m_user
                                                                 created_at            = m_timestamp
                                                                 last_changed_by       = m_user
                                                                 last_changed_at       = m_timestamp
                                                                 local_last_changed_at = m_timestamp ) ) ) ).
    INSERT zprc_proc_object FROM TABLE @created.

    DATA(updated) = VALUE tt_processed_object(
        FOR u IN i_update
        LET row = CORRESPONDING zprc_proc_object( u MAPPING FROM ENTITY ) IN
        ( derive_processed_object( i_new_steps        = i_new_steps
                                   i_processed_object = VALUE #( BASE row
                                                                 last_changed_by       = m_user
                                                                 last_changed_at       = m_timestamp
                                                                 local_last_changed_at = m_timestamp ) ) ) ).
    UPDATE zprc_proc_object FROM TABLE @updated.
  ENDMETHOD.


  METHOD derive_processed_object.
    r_processed_object = i_processed_object.

    " Latest step: the last new step of this object in the change set
    r_processed_object-latest_step_uuid = REDUCE #( INIT latest = i_processed_object-latest_step_uuid
                                                    FOR s IN i_new_steps
                                                    WHERE ( ProcessedObjectUUID = i_processed_object-uuid )
                                                    NEXT latest = s-StepUUID ).

    " Every process has at least one transition; none means the process class cannot be
    " loaded (e.g. syntax error, see ZCL_PRC_PROCESS_LOADER): keep the previous step total
    DATA(lt_transitions) = get_transitions( i_processed_object-factory_class_name ).
    IF lt_transitions IS INITIAL.
      RETURN.
    ENDIF.

    " StepTotal: real transitions done + longest remaining path
    SELECT COUNT(*) FROM zprc_proc_step
      WHERE zprc_proc_step~processed_object_uuid = @i_processed_object-uuid
        AND zprc_proc_step~start_state          <> zprc_proc_step~end_state
      INTO @DATA(done).
    r_processed_object-step_total = done + get_remaining_steps( i_transitions = lt_transitions
                                                                i_state       = i_processed_object-state ).
  ENDMETHOD.


  METHOD get_transitions.
    ASSIGN mt_processes[ class_name = i_class_name ] TO FIELD-SYMBOL(<process>).
    IF sy-subrc <> 0.
      " Via the loader: a syntax error in the process class must not abort the session
      " (the writer runs in the main session of the engine and in the creating session).
      " Not loadable: no transitions - the caller keeps the previous step total.
      DATA(process) = zcl_prc_process_loader=>get_process( i_class_name ).
      INSERT VALUE #( class_name  = i_class_name
                      transitions = COND #( WHEN process IS BOUND THEN process->get_transitions( ) ) )
             INTO TABLE mt_processes ASSIGNING <process>.
    ENDIF.
    r_transitions = <process>-transitions.
  ENDMETHOD.


  METHOD get_remaining_steps.
    " Longest path without loops: a transition back to a state already on the path is skipped
    IF i_state = zif_prc_process=>co_finished.
      RETURN.
    ENDIF.
    DATA(visited) = VALUE tt_state( BASE i_visited ( i_state ) ).
    r_steps = REDUCE #( INIT longest = CONV int8( 0 )
                        FOR t IN i_transitions WHERE ( start_state = i_state )
                        NEXT longest = COND #( WHEN line_exists( visited[ table_line = t-end_state ] )
                                               THEN longest
                                               ELSE nmax( val1 = longest
                                                          val2 = 1 + get_remaining_steps( i_transitions = i_transitions
                                                                                          i_state       = t-end_state
                                                                                          i_visited     = visited ) ) ) ).
  ENDMETHOD.


  METHOD get_severity_code.
    r_code = SWITCH #( i_severity
                       WHEN 'E' OR 'A' OR 'X' THEN 1
                       WHEN 'W'               THEN 2
                       WHEN 'S'               THEN 3
                       WHEN 'I'               THEN 5 ).
  ENDMETHOD.

ENDCLASS.

