CLASS zcl_prc_demo_create_equi_init DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    CLASS-METHODS initialize.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_prc_demo_create_equi_init IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    initialize( ).
    COMMIT ENTITIES.
    out->write( |Demo process instances created { sy-uzeit }| ).
  ENDMETHOD.

  METHOD initialize.
    SELECT Uuid FROM ZR_PRC_ProcessedObject
      WHERE ProcessName = @zcl_prc_demo_create_equi_proc=>co_process_name
      INTO TABLE @DATA(lt_existing).

    MODIFY ENTITIES OF ZR_PRC_ProcessedObject
           ENTITY ProcessedObject
           DELETE FROM VALUE #( FOR k IN lt_existing
                                ( %key-uuid = k-uuid ) ).

    zcl_prc_processing_api=>get_instance( )->create_processed_objects(
        i_create_processed_objects = VALUE #( FOR i = 1 UNTIL i > 20
                                              ( processName      = zcl_prc_demo_create_equi_proc=>co_process_name
                                                FactoryClassName = zcl_prc_demo_create_equi_proc=>co_class_name
                                                processedObject  = |EQUI{ i ALIGN = RIGHT PAD = '0' WIDTH = 3 }|
                                                mailAddress = 'demo@abap-processing-center.de' ) )
        i_perform_commit           = abap_true
        i_trigger_processing       = zcl_prc_processing_api=>execution_mode-direct_execution ).
  ENDMETHOD.


ENDCLASS.
