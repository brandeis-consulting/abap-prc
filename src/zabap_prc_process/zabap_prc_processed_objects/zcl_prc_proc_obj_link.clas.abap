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
    DATA lo_factory TYPE REF TO zif_prc_process.

    LOOP AT ct_calculated_data ASSIGNING FIELD-SYMBOL(<calculated_data>).
      ASSIGN it_original_data[ sy-tabix ] TO FIELD-SYMBOL(<original_Data>).
      ASSIGN COMPONENT 'EXTERNALPROCESSEDOBJECTID' OF STRUCTURE <original_data> TO FIELD-SYMBOL(<processed_object>).
      ASSIGN COMPONENT 'EXTERNALPROCESSEDOBJECTUUID' OF STRUCTURE <original_data> TO FIELD-SYMBOL(<processed_object_uuid>).
      ASSIGN COMPONENT 'FACTORYCLASSNAME' OF STRUCTURE <original_data> TO FIELD-SYMBOL(<factory_class_name>).
      ASSIGN COMPONENT 'LINK' OF STRUCTURE <calculated_data> TO FIELD-SYMBOL(<link>).

      TRY.
          CREATE OBJECT lo_factory TYPE (<factory_class_name>).
          <link> = lo_factory->get_url_for_processed_object( iv_processed_object = <processed_object>
                                                             iv_processed_object_uuid = <processed_object_uuid> ).
        CATCH cx_root.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.


  METHOD if_sadl_exit_calc_element_read~get_calculation_info.
    INSERT |FACTORYCLASSNAME| INTO TABLE et_requested_orig_elements.
    INSERT |EXTERNALPROCESSEDOBJECTID| INTO TABLE et_requested_orig_elements.
    INSERT |EXTERNALPROCESSEDOBJECTUUID| INTO TABLE et_requested_orig_elements.
  ENDMETHOD.
ENDCLASS.
