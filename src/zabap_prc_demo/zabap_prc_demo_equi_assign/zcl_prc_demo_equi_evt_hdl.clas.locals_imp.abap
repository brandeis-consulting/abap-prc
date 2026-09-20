CLASS lhe_equipment DEFINITION INHERITING FROM cl_abap_behavior_event_handler.

  PRIVATE SECTION.
    METHODS on_equipment_created FOR ENTITY EVENT
       equipment_created FOR Equipment~equipment_created.

ENDCLASS.

CLASS lhe_equipment IMPLEMENTATION.

  METHOD on_equipment_created.
    cl_abap_tx=>save( ).

    zcl_prc_processing_api=>get_instance( )->create_processed_objects(
        i_create_processed_objects = VALUE #( FOR k IN equipment_created
                                              ( processedObject  = k-Identifier
                                                processName      = zcl_prc_demo_equi_assign_proc=>co_process_name
                                                factoryClassName = zcl_prc_demo_equi_assign_proc=>co_class_name ) )
        i_perform_commit           = abap_false
        i_trigger_processing       = zcl_prc_processing_api=>execution_mode-bgpf_execution    ).
  ENDMETHOD.

ENDCLASS.
