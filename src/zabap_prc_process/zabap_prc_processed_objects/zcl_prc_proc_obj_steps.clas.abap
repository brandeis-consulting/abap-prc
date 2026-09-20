CLASS zcl_prc_proc_obj_steps DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_sadl_exit_calc_element_read.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_PRC_PROC_OBJ_STEPS IMPLEMENTATION.


  METHOD if_sadl_exit_calc_element_read~calculate.
    DATA lo_factory TYPE REF TO zif_prc_process.

    LOOP AT ct_calculated_data ASSIGNING FIELD-SYMBOL(<calculated_data>).
      ASSIGN COMPONENT 'STEPTOTAL' OF STRUCTURE <calculated_data> TO FIELD-SYMBOL(<step_total>).
      ASSIGN COMPONENT 'FACTORYCLASSNAME' OF STRUCTURE it_original_data[ sy-index ] TO FIELD-SYMBOL(<factory_class_name>).
      CREATE OBJECT lo_factory TYPE (<factory_class_name>).
      <step_total> = lines( lo_factory->get_transitions( ) )  .
    ENDLOOP.
  ENDMETHOD.


  METHOD if_sadl_exit_calc_element_read~get_calculation_info.
    INSERT |FACTORYCLASSNAME| INTO TABLE et_requested_orig_elements.
  ENDMETHOD.
ENDCLASS.
