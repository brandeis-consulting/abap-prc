"! <p class="shorttext synchronized">ABAP-PRC: Link to the processed object (calc. exit)</p>
"!
"! Calculated element LINK of the processed object views. Deliberately without static
"! dependencies on other ABAP-PRC objects (loader and process are called dynamically):
"! abapGit activates CDS views before classes, so this class is pulled first on its own
"! and must activate without the rest of ABAP-PRC.
CLASS zcl_prc_proc_obj_link DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_sadl_exit_calc_element_read.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_prc_proc_obj_link IMPLEMENTATION.


  METHOD if_sadl_exit_calc_element_read~calculate.
    DATA lr_process TYPE REF TO data.
    DATA lo_process TYPE REF TO object.

    LOOP AT ct_calculated_data ASSIGNING FIELD-SYMBOL(<calculated_data>).
      ASSIGN it_original_data[ sy-tabix ] TO FIELD-SYMBOL(<original_data>).
      ASSIGN COMPONENT 'EXTERNALPROCESSEDOBJECTID' OF STRUCTURE <original_data> TO FIELD-SYMBOL(<processed_object>).
      ASSIGN COMPONENT 'EXTERNALPROCESSEDOBJECTUUID' OF STRUCTURE <original_data> TO FIELD-SYMBOL(<processed_object_uuid>).
      ASSIGN COMPONENT 'FACTORYCLASSNAME' OF STRUCTURE <original_data> TO FIELD-SYMBOL(<factory_class_name>).
      ASSIGN COMPONENT 'LINK' OF STRUCTURE <calculated_data> TO FIELD-SYMBOL(<link>).

      " Via the loader: a process class with a syntax error must not abort the whole list
      TRY.
          CREATE DATA lr_process TYPE REF TO ('ZIF_PRC_PROCESS').
          ASSIGN lr_process->* TO FIELD-SYMBOL(<process>).
          CALL METHOD ('ZCL_PRC_PROCESS_LOADER')=>('GET_PROCESS')
            EXPORTING
              i_class_name = <factory_class_name>
            RECEIVING
              r_process    = <process>.
          lo_process = <process>.
        CATCH cx_root ##CATCH_ALL ##NO_HANDLER.
          CLEAR lo_process.
      ENDTRY.
      IF lo_process IS NOT BOUND.
        CONTINUE.
      ENDIF.

      TRY.
          CALL METHOD lo_process->('ZIF_PRC_PROCESS~GET_URL_FOR_PROCESSED_OBJECT')
            EXPORTING
              i_processed_object      = <processed_object>
              i_processed_object_uuid = <processed_object_uuid>
            RECEIVING
              r_relative_url          = <link>.
        CATCH cx_root ##CATCH_ALL ##NO_HANDLER.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.


  METHOD if_sadl_exit_calc_element_read~get_calculation_info.
    INSERT |FACTORYCLASSNAME| INTO TABLE et_requested_orig_elements.
    INSERT |EXTERNALPROCESSEDOBJECTID| INTO TABLE et_requested_orig_elements.
    INSERT |EXTERNALPROCESSEDOBJECTUUID| INTO TABLE et_requested_orig_elements.
  ENDMETHOD.
ENDCLASS.
