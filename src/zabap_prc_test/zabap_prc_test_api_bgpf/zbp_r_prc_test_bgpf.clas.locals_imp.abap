CLASS lhc_testbgpf DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR TestBgpf RESULT result.
ENDCLASS.


CLASS lhc_testbgpf IMPLEMENTATION.

  METHOD get_global_authorizations.
    " Testobjekt: alles erlaubt
    result = VALUE #( %create = if_abap_behv=>auth-allowed
                      %update = if_abap_behv=>auth-allowed
                      %delete = if_abap_behv=>auth-allowed ).
  ENDMETHOD.

ENDCLASS.


"! Saver: vergibt im Late-Numbering-Exit die finale ID und ruft
"! anschliessend die Processing API im bgPF-Modus fuer die neuen Instanzen.
CLASS lsc_zr_prc_test_bgpf DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS adjust_numbers REDEFINITION.
ENDCLASS.


CLASS lsc_zr_prc_test_bgpf IMPLEMENTATION.

  METHOD adjust_numbers.
    CHECK mapped-testbgpf IS NOT INITIAL.

    " 1) Finale ID vergeben (fuer den Test reicht MAX + 1)
    SELECT MAX( id ) FROM zprc_test_bgpf INTO @DATA(lv_max_id).
    DATA(lv_next_id) = CONV int8( lv_max_id ).

    LOOP AT mapped-testbgpf ASSIGNING FIELD-SYMBOL(<ls_mapped>).
      lv_next_id += 1.
      <ls_mapped>-ID = lv_next_id.
    ENDLOOP.

    " 2) Processing Center im bgPF-Modus aufrufen - das ist der eigentliche Testgegenstand.
    "    Kein Commit: in der Save-Sequenz verboten.
    zcl_prc_processing_api=>get_instance( )->create_processed_objects(
        i_create_processed_objects = VALUE #( FOR ls_new IN mapped-testbgpf
                                              ( processName      = zcl_prc_test_bgpf_proc=>co_process_name
                                                factoryClassName = zcl_prc_test_bgpf_proc=>co_class_name
                                                processedObject  = ls_new-ID ) )
        i_perform_commit           = abap_false
        i_trigger_processing       = zcl_prc_processing_api=>execution_mode-bgpf_execution ).
  ENDMETHOD.

ENDCLASS.
