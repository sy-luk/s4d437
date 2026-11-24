CLASS lhc_Z03_R_TRAVEL DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      keys REQUEST requested_authorizations FOR z03_r_travel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      REQUEST requested_authorizations FOR z03_r_travel RESULT result.
    METHODS cancel_travel FOR MODIFY
      keys FOR ACTION z03_r_travel~cancel_travel.

ENDCLASS.

CLASS lhc_Z03_R_TRAVEL IMPLEMENTATION.

  METHOD get_instance_authorizations.

    result = CORRESPONDING  #( keys ).


    LOOP AT result ASSIGNING FIELD-SYMBOL(<result>).
        DATA(rc) = /lrn/cl_s4d437_model=>authority_check(
                     i_agencyid = <result>-AgencyId
                     i_actvt    = '02'
                   ).

    IF rc <> 0.
    <result>-%action-cancel_travel = if_abap_behv=>auth-unauthorized.
    <result>-%update               = if_abap_behv=>auth-unauthorized.

    ELSE.
        <result>-%action-cancel_travel = if_abap_behv=>auth-allowed.
    <result>-%update               = if_abap_behv=>auth-allowed.
    ENDIF.

    ENDLOOP.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD cancel_travel.

    READ ENTITIES OF z03_r_travel in LOCAL MODE
    ENTITY Travel
    ALL FIELDS WITH
    CORRESPONDING #( keys )
    RESULT DATA(travels).


    LOOP AT travels INTO DATA(travel).
        IF travel-Status <> 'C'.

            MODIFY ENTITIES OF z03_r_travel IN LOCAL MODE
                ENTITY travel
                UPDATE FIELDS ( status )
                WITH VALUE #( ( %tky = travel-%tky
                                status = 'C' ) ).
        ELSE.

            APPEND VALUE #( %tky = travel-%tky ) TO failed-travel.
            APPEND VALUE #( %tky = travel-%tky
                            %msg = NEW /lrn/cm_s4d437(
                                    textid = /lrn/cm_s4d437=>already_canceled ) )
                                    TO reported-travel.
        ENDIF.
    ENDLOOP.


  ENDMETHOD.

ENDCLASS.
