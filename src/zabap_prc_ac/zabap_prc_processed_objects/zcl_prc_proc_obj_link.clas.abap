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
    LOOP AT ct_calculated_data ASSIGNING FIELD-SYMBOL(<calculated_data>).
      ASSIGN it_original_data[ sy-tabix ] TO FIELD-SYMBOL(<original_Data>).
      ASSIGN COMPONENT 'EXTERNALPROCESSEDOBJECTID' OF STRUCTURE <original_data> TO FIELD-SYMBOL(<processed_object>).
      ASSIGN COMPONENT 'EXTERNALPROCESSEDOBJECTUUID' OF STRUCTURE <original_data> TO FIELD-SYMBOL(<processed_object_uuid>).
      ASSIGN COMPONENT 'FACTORYCLASSNAME' OF STRUCTURE <original_data> TO FIELD-SYMBOL(<factory_class_name>).
      ASSIGN COMPONENT 'LINK' OF STRUCTURE <calculated_data> TO FIELD-SYMBOL(<link>).

      " Via the loader: a process class with a syntax error must not abort the whole list
      DATA(lo_factory) = zcl_prc_process_loader=>get_process( <factory_class_name> ).
      IF lo_factory IS NOT BOUND.
        CONTINUE.
      ENDIF.
      TRY.
          <link> = lo_factory->get_url_for_processed_object( i_processed_object      = <processed_object>
                                                             i_processed_object_uuid = <processed_object_uuid> ).
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
