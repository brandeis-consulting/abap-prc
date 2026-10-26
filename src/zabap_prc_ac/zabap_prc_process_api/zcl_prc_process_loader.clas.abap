"! <p class="shorttext synchronized">Loads process classes without short dumps</p>
"!
"! Every place outside the step session that needs an instance of a process class
"! (main session of the engine, DB writer, apps, precheck on create) gets it here.
"!
"! A syntax error in the process class - or in a transition handler local to it - is
"! the runtime error SYNTAX_ERROR on CREATE OBJECT, which cannot be caught and would
"! abort the whole session: a processing run with the objects of all processes, or
"! the list of an app. RTTI reports the same error as the catchable exception
"! CX_SY_RTTI_SYNTAX_ERROR, so the class is described first and only created if
"! that works. The result is buffered per session and class.
"!
"! A transition handler in a global class of its own is not covered: RTTI on the
"! process class does not know it. Load it only where the step session already did.
CLASS zcl_prc_process_loader DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    "! Returns a new instance of the process class.
    "!
    "! @parameter i_class_name | Process class (factory class name of the processed object).
    "! @parameter e_error      | ZPRC_PROCESS_MESSAGE/021 with the reason; initial if loaded.
    "! @parameter r_process    | New instance; unbound if the class cannot be loaded.
    CLASS-METHODS get_process
      IMPORTING i_class_name     TYPE csequence
      EXPORTING e_error          TYPE symsg
      RETURNING VALUE(r_process) TYPE REF TO zif_prc_process.

  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES: BEGIN OF ty_check,
             class_name TYPE string,
             error      TYPE symsg,
           END OF ty_check.

    "! Checked classes of this session: initial ERROR = loadable
    CLASS-DATA gt_checked TYPE HASHED TABLE OF ty_check WITH UNIQUE KEY class_name.

    CLASS-METHODS check
      IMPORTING i_class_name   TYPE string
      RETURNING VALUE(r_error) TYPE symsg.

    CLASS-METHODS error_message
      IMPORTING i_class_name   TYPE string
                i_reason       TYPE string
      RETURNING VALUE(r_error) TYPE symsg.
ENDCLASS.



CLASS zcl_prc_process_loader IMPLEMENTATION.

  METHOD get_process.
    CLEAR: e_error, r_process.
    DATA(lv_class_name) = to_upper( condense( CONV string( i_class_name ) ) ).

    READ TABLE gt_checked WITH TABLE KEY class_name = lv_class_name INTO DATA(ls_check).
    IF sy-subrc <> 0.
      ls_check = VALUE #( class_name = lv_class_name
                          error      = check( lv_class_name ) ).
      INSERT ls_check INTO TABLE gt_checked.
    ENDIF.

    IF ls_check-error IS NOT INITIAL.
      e_error = ls_check-error.
      RETURN.
    ENDIF.

    TRY.
        CREATE OBJECT r_process TYPE (lv_class_name).
      CATCH cx_sy_create_object_error INTO DATA(lx_create).
        " E.g. abstract or not instantiable from here
        e_error = error_message( i_class_name = lv_class_name
                                 i_reason     = lx_create->get_text( ) ).
        CLEAR r_process.
    ENDTRY.
  ENDMETHOD.


  METHOD check.
    DATA lo_descr TYPE REF TO cl_abap_typedescr.

    IF i_class_name IS INITIAL.
      r_error = error_message( i_class_name = i_class_name
                               i_reason     = `No class name` ).
      RETURN.
    ENDIF.

    TRY.
        cl_abap_typedescr=>describe_by_name( EXPORTING  p_name         = i_class_name
                                             RECEIVING  p_descr_ref    = lo_descr
                                             EXCEPTIONS type_not_found = 1
                                                        OTHERS         = 2 ).
        IF sy-subrc <> 0 OR lo_descr IS NOT BOUND OR lo_descr->kind <> cl_abap_typedescr=>kind_class.
          r_error = error_message( i_class_name = i_class_name
                                   i_reason     = `Class does not exist` ).
          RETURN.
        ENDIF.

        DATA(lt_interfaces) = CAST cl_abap_classdescr( lo_descr )->interfaces.
        IF NOT line_exists( lt_interfaces[ name = 'ZIF_PRC_PROCESS' ] ).
          r_error = error_message( i_class_name = i_class_name
                                   i_reason     = `ZIF_PRC_PROCESS is not implemented` ).
        ENDIF.

      CATCH cx_sy_rtti_syntax_error INTO DATA(lx_syntax).
        " The class pool has a syntax error (also in a local transition handler)
        r_error = error_message( i_class_name = i_class_name
                                 i_reason     = lx_syntax->get_text( ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD error_message.
    " Reason up to 150 characters, spread over the variables 2 to 4
    DATA lv_reason TYPE c LENGTH 150.
    lv_reason = i_reason.
    r_error = VALUE #( msgty = 'E'
                       msgid = 'ZPRC_PROCESS_MESSAGE'
                       msgno = '021'
                       msgv1 = i_class_name
                       msgv2 = lv_reason+0(50)
                       msgv3 = lv_reason+50(50)
                       msgv4 = lv_reason+100(50) ).
  ENDMETHOD.

ENDCLASS.

