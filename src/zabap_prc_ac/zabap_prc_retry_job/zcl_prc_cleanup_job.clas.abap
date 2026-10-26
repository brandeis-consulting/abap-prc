"! <p class="shorttext synchronized">Cleanup job (data retention)</p>
"!
"! Deletes completed data after a retention period (default 28 days):
"! <ul>
"! <li>Processed objects without run have a life cycle of their own: deleted when
"!     FINISHED and last changed before the retention period.</li>
"! <li>Processed objects of a run belong to the run (composition): they are deleted
"!     with the run only. A run is deleted when it ended (finished or aborted), all
"!     its objects are FINISHED and the latest of its job end and of all changes of
"!     its objects lies before the retention period (e.g. a late resume keeps it).</li>
"! <li>Objects with errors or still open are never deleted here.</li>
"! </ul>
"! Application logs are not deleted here: they get an expiry date when created.
CLASS zcl_prc_cleanup_job DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_apj_dt_exec_object.
    INTERFACES if_apj_rt_exec_object.

    CONSTANTS co_default_days TYPE i VALUE 28.

    CONSTANTS: BEGIN OF co_parameter,
                 days         TYPE zif_prc_run=>ty_run_parameter VALUE 'P_DAYS',
                 simulate     TYPE zif_prc_run=>ty_run_parameter VALUE 'P_TEST',
                 process_name TYPE zif_prc_run=>ty_run_parameter VALUE 'S_PROC',
               END OF co_parameter.

    TYPES tt_process_names TYPE RANGE OF zprc_process_name.

    TYPES: BEGIN OF ty_result,
             objects TYPE i,
             runs    TYPE i,
           END OF ty_result.

    "! Deletes (or only counts) the data older than the retention period.
    "!
    "! @parameter i_days          | Retention period in days since the last change
    "! @parameter i_process_names | Only objects of these processes (empty: all); a run
    "!                              qualifies only if all its objects are in the range
    "! @parameter i_simulate      | Count only, delete nothing
    "! @parameter r_result        | Number of objects (incl. those of runs) and runs
    METHODS cleanup IMPORTING i_days          TYPE i DEFAULT co_default_days
                              i_process_names TYPE tt_process_names OPTIONAL
                              i_simulate      TYPE abap_bool DEFAULT abap_false
                    RETURNING VALUE(r_result) TYPE ty_result.

  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES tt_uuid_range TYPE RANGE OF sysuuid_x16.

    METHODS deletable_runs IMPORTING i_threshold     TYPE timestampl
                                     i_process_names TYPE tt_process_names
                           RETURNING VALUE(r_runs)   TYPE tt_uuid_range.
ENDCLASS.



CLASS zcl_prc_cleanup_job IMPLEMENTATION.

  METHOD if_apj_dt_exec_object~get_parameters.
    et_parameter_def = VALUE #(
        ( selname = co_parameter-days         kind = if_apj_dt_exec_object=>parameter
          datatype = 'I' length = 10 param_text = 'Retention period (days)' changeable_ind = abap_true )
        ( selname = co_parameter-simulate     kind = if_apj_dt_exec_object=>parameter
          datatype = 'C' length = 1 param_text = 'Simulate (count only)' checkbox_ind = abap_true changeable_ind = abap_true )
        ( selname = co_parameter-process_name kind = if_apj_dt_exec_object=>select_option
          datatype = 'C' length = 30 param_text = 'Process name' changeable_ind = abap_true ) ).
    et_parameter_val = VALUE #( ( selname = co_parameter-days kind = if_apj_dt_exec_object=>parameter
                                  sign = 'I' option = 'EQ' low = |{ co_default_days }| ) ).
  ENDMETHOD.


  METHOD if_apj_rt_exec_object~execute.
    DATA lv_days     TYPE i VALUE co_default_days.
    DATA lv_simulate TYPE abap_bool.
    DATA lt_names    TYPE tt_process_names.

    LOOP AT it_parameters INTO DATA(ls_parameter).
      CASE ls_parameter-selname.
        WHEN co_parameter-days.
          IF ls_parameter-low IS NOT INITIAL.
            lv_days = ls_parameter-low.
          ENDIF.
        WHEN co_parameter-simulate.
          lv_simulate = xsdbool( ls_parameter-low = abap_true ).
        WHEN co_parameter-process_name.
          APPEND VALUE #( sign = ls_parameter-sign option = ls_parameter-option
                          low  = ls_parameter-low  high   = ls_parameter-high ) TO lt_names.
      ENDCASE.
    ENDLOOP.

    cleanup( i_days = lv_days i_process_names = lt_names i_simulate = lv_simulate ).
  ENDMETHOD.


  METHOD cleanup.
    GET TIME STAMP FIELD DATA(lv_now_short).
    DATA lv_threshold TYPE timestampl.
    lv_threshold = cl_abap_tstmp=>subtractsecs( tstmp = CONV timestampl( lv_now_short )
                                                secs  = i_days * 86400 ).

    " 1. Runs whose objects are all done and old (composition: objects go with the run)
    DATA(lt_runs) = deletable_runs( i_threshold = lv_threshold i_process_names = i_process_names ).
    r_result-runs = lines( lt_runs ).
    IF lt_runs IS NOT INITIAL.
      SELECT COUNT(*) FROM zprc_proc_object WHERE run_uuid IN @lt_runs INTO @DATA(lv_run_objects).
      r_result-objects = lv_run_objects.
      IF i_simulate = abap_false.
        DELETE FROM zprc_proc_msg  WHERE processed_object_uuid IN ( SELECT uuid FROM zprc_proc_object WHERE run_uuid IN @lt_runs ).
        DELETE FROM zprc_proc_step WHERE processed_object_uuid IN ( SELECT uuid FROM zprc_proc_object WHERE run_uuid IN @lt_runs ).
        DELETE FROM zprc_proc_object WHERE run_uuid IN @lt_runs.
        DELETE FROM zprc_run_params  WHERE job_uuid IN @lt_runs.
        DELETE FROM zprc_run         WHERE uuid     IN @lt_runs.
        COMMIT WORK.
      ENDIF.
    ENDIF.

    " 2. Objects without run: life cycle of their own
    SELECT COUNT(*) FROM zprc_proc_object
      WHERE run_uuid        IS INITIAL
        AND state           = @zif_prc_process=>co_finished
        AND last_changed_at < @lv_threshold
        AND process_name    IN @i_process_names
      INTO @DATA(lv_objects).
    r_result-objects += lv_objects.
    IF lv_objects > 0 AND i_simulate = abap_false.
      DELETE FROM zprc_proc_msg WHERE processed_object_uuid IN
        ( SELECT uuid FROM zprc_proc_object WHERE run_uuid IS INITIAL AND state = @zif_prc_process=>co_finished
                                              AND last_changed_at < @lv_threshold AND process_name IN @i_process_names ).
      DELETE FROM zprc_proc_step WHERE processed_object_uuid IN
        ( SELECT uuid FROM zprc_proc_object WHERE run_uuid IS INITIAL AND state = @zif_prc_process=>co_finished
                                              AND last_changed_at < @lv_threshold AND process_name IN @i_process_names ).
      DELETE FROM zprc_proc_object
        WHERE run_uuid        IS INITIAL
          AND state           = @zif_prc_process=>co_finished
          AND last_changed_at < @lv_threshold
          AND process_name    IN @i_process_names.
      COMMIT WORK.
    ENDIF.
  ENDMETHOD.


  METHOD deletable_runs.
    " Ended before the threshold, and no object that is open, failed, changed later
    " or (with a restriction) of another process
    SELECT run~uuid FROM zprc_run AS run
      WHERE run~execution_status IN ( @zif_prc_run=>co_execution_status-finished, @zif_prc_run=>co_execution_status-aborted )
        AND run~job_end          IS NOT INITIAL
        AND run~job_end          < @i_threshold
        AND NOT EXISTS ( SELECT uuid FROM zprc_proc_object
                           WHERE run_uuid = run~uuid
                             AND ( state           <> @zif_prc_process=>co_finished
                                OR last_changed_at >= @i_threshold
                                OR process_name NOT IN @i_process_names ) )
      INTO TABLE @DATA(lt_candidates).

    LOOP AT lt_candidates INTO DATA(ls_candidate).
      " With a restriction, only runs that have objects of the processes
      IF i_process_names IS NOT INITIAL.
        SELECT SINGLE @abap_true FROM zprc_proc_object
          WHERE run_uuid = @ls_candidate-uuid
          INTO @DATA(lv_has_objects).
        IF lv_has_objects = abap_false.
          CONTINUE.
        ENDIF.
        CLEAR lv_has_objects.
      ENDIF.
      APPEND VALUE #( sign = 'I' option = 'EQ' low = ls_candidate-uuid ) TO r_runs.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

