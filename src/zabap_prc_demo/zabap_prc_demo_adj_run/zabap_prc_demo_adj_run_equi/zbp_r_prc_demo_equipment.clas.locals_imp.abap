*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations

CLASS lhc_equipment DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Equipment RESULT result.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE Equipment.

    METHODS copy_with_reference FOR MODIFY
      IMPORTING keys FOR ACTION Equipment~copy_by_reference.

ENDCLASS.

CLASS lhc_equipment IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD earlynumbering_create.

    DATA next_id TYPE n LENGTH 10.

    " Every input instance has to be answered - either in MAPPED or in FAILED.
    " Instances that already carry an identifier (for example the create that
    " draft activation triggers) keep theirs and are echoed back unchanged.
    LOOP AT entities INTO DATA(entity) WHERE Identifier IS NOT INITIAL.
      APPEND VALUE #( %cid       = entity-%cid
                      %is_draft  = entity-%is_draft
                      Identifier = entity-Identifier )
             TO mapped-equipment.
    ENDLOOP.

    DATA(entities_to_number) = entities.
    DELETE entities_to_number WHERE Identifier IS NOT INITIAL.

    IF entities_to_number IS INITIAL.
      RETURN.
    ENDIF.

    " Highest identifier currently in use - active persistence and drafts.
    SELECT SINGLE FROM zprc_demo_equi   FIELDS MAX( id )         INTO @DATA(max_active).
    SELECT SINGLE FROM zprc_demo_equi_d FIELDS MAX( identifier ) INTO @DATA(max_draft).

    DATA(max_used) = COND zprc_demo_equi-id( WHEN max_active > max_draft THEN max_active ELSE max_draft ).

    IF max_used IS INITIAL.
      next_id = 0.
    ELSE.
      next_id = max_used.
    ENDIF.

    LOOP AT entities_to_number INTO entity.
      next_id += 1.
      APPEND VALUE #( %cid       = entity-%cid
                      %is_draft  = entity-%is_draft
                      Identifier = next_id )
             TO mapped-equipment.
    ENDLOOP.

  ENDMETHOD.

  METHOD copy_with_reference.
    DATA copies TYPE TABLE FOR CREATE zr_prc_demo_equipment.

    " Read the reference instances the action was triggered on.
    READ ENTITIES OF zr_prc_demo_equipment IN LOCAL MODE
         ENTITY Equipment
         FIELDS ( EquipmentCategory )
         WITH CORRESPONDING #( keys )
         RESULT DATA(references)
         FAILED failed
         REPORTED reported.

    LOOP AT keys INTO DATA(key).

      DATA(reference) = VALUE #( references[ KEY id
                                             %tky = key-%tky ] OPTIONAL ).
      IF reference IS INITIAL.
        CONTINUE.
      ENDIF.

      " Identifier stays empty on purpose - early numbering assigns it.
      " The copy is created as a draft so the user can review it before saving.
      DATA(lv_new_identifier) = reference-Identifier.
      lv_new_identifier(1) = 'C'. " Prefix the identifier with 'C' to indicate it's a copy.
      APPEND VALUE #( %cid              = key-%cid
                      Identifier        = lv_new_identifier
                      EquipmentCategory = reference-EquipmentCategory )
             TO copies.

    ENDLOOP.

    IF copies IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zr_prc_demo_equipment IN LOCAL MODE
           ENTITY Equipment
           CREATE FIELDS ( Identifier EquipmentCategory )
           WITH copies
           MAPPED DATA(mapped_copies)
           FAILED DATA(failed_copies)
           REPORTED DATA(reported_copies).

    failed   = CORRESPONDING #( DEEP failed_copies ).
    reported = CORRESPONDING #( DEEP reported_copies ).

    " Factory action: the created instances are the implicit result.
    mapped-equipment = mapped_copies-equipment.
  ENDMETHOD.

ENDCLASS.


CLASS lsc_zr_prc_demo_equipment DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.
ENDCLASS.

CLASS lsc_zr_prc_demo_equipment IMPLEMENTATION.

  METHOD save_modified.

    IF create-equipment IS NOT INITIAL.
      RAISE ENTITY EVENT zr_prc_demo_equipment~equipment_created
        FROM VALUE #( FOR created_equipment IN create-equipment
                      ( %key   = created_equipment-%key ) ).
    ENDIF.

    IF delete-equipment IS NOT INITIAL.
      RAISE ENTITY EVENT zr_prc_demo_equipment~equipment_deleted
        FROM VALUE #( FOR deleted_equipment IN delete-equipment
                      ( %key-Identifier = deleted_equipment-Identifier ) ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
