"! <p class="shorttext synchronized">Behavior Implementation for ZR_PRC_MESSAGEEXT</p>
"! Raises the changed event of message groups; called dynamically by the save phase
"! of ZR_PRC_MessageTP (ZBP_PRC_MESSAGE), so the core runs without this package.
"! Keep the signature in sync with that call.
CLASS zbp_r_prc_messageext DEFINITION PUBLIC ABSTRACT FINAL FOR BEHAVIOR OF zr_prc_messagetp.
  PUBLIC SECTION.
    TYPES tt_group_keys TYPE TABLE FOR KEY OF zr_prc_messagetp.

    "! @parameter i_group_keys | Message groups whose changed event is raised
    CLASS-METHODS raise_message IMPORTING i_group_keys TYPE tt_group_keys.
ENDCLASS.

CLASS zbp_r_prc_messageext IMPLEMENTATION.

  METHOD raise_message.
    RAISE ENTITY EVENT ZR_PRC_MessageTP~zz_messageChanged
          FROM VALUE #( FOR group_key IN i_group_keys ( %key = CORRESPONDING #( group_key ) ) ).
  ENDMETHOD.

ENDCLASS.
