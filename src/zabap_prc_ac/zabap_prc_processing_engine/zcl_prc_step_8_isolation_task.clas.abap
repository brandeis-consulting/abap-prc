"! <p class="shorttext synchronized">ABAP-PRC: Step running in a session of its own</p>
"!
"! Created by the isolation layer and executed by CL_ABAP_PARALLEL in a new
"! session. The instance is serialized, so it carries data only: the state
"! goes in, the state after the step comes out. The layers inside (7-Lock to
"! 1-Core) and the message handler are created in the new session.
"!
"! Before anything can abort the session, it registers itself under the marker
"! of the step, so the isolation layer can find its short dump.
"!
"! Global instead of local, because the instance is re-created in the new session.
CLASS zcl_prc_step_8_isolation_task DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_abap_parallel.

    "! @parameter i_state  | State before the step.
    "! @parameter i_marker | Marker of the step, to find a short dump of this session.
    METHODS constructor IMPORTING i_state  TYPE zif_prc_processing_engine=>ty_state
                                  i_marker TYPE sysuuid_x16.

    "! @parameter r_state | State after the step, as written in the new session.
    METHODS get_result RETURNING VALUE(r_state) TYPE zif_prc_processing_engine=>ty_state.

  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA m_state  TYPE zif_prc_processing_engine=>ty_state.
    DATA m_marker TYPE sysuuid_x16.
    DATA m_result TYPE zif_prc_processing_engine=>ty_state.
ENDCLASS.



CLASS zcl_prc_step_8_isolation_task IMPLEMENTATION.

  METHOD constructor.
    m_state  = i_state.
    m_marker = i_marker.
    m_result = i_state.
  ENDMETHOD.


  METHOD get_result.
    r_state = m_result.
  ENDMETHOD.


  METHOD if_abap_parallel~do.
    DATA(dump_finder) = zcl_prc_step_factory=>create_dump_finder( ).
    IF dump_finder IS BOUND.
      dump_finder->register_session( m_marker ).
    ENDIF.

    DATA(message_handler) = zcl_prc_message_handler=>create_message_handler( ).
    TRY.
        m_result = zcl_prc_step_factory=>create_isolated_step( )->execute( i_state           = m_state
                                                                          i_message_handler = message_handler ).
      CATCH zcx_prc_unit_of_work_failed.
        " The layers inside write every failure themselves and never raise
        m_result = m_state.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.

