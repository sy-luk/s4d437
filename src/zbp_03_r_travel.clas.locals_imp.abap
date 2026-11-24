CLASS lhc_Z03_R_TRAVEL DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      keys REQUEST requested_authorizations FOR z03_r_travel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      REQUEST requested_authorizations FOR z03_r_travel RESULT result.
    METHODS cancel_travel FOR MODIFY
      keys FOR ACTION z03_r_travel~cancel_travel.
    METHODS validatedescription FOR VALIDATE ON SAVE
      keys FOR travel~validatedescription.
    METHODS validatecustomer FOR VALIDATE ON SAVE
      keys FOR travel~validatecustomer.
    METHODS determinestatus FOR DETERMINE ON MODIFY
      keys FOR travel~determinestatus.
    METHODS earlynumbering_create FOR NUMBERING
      entities FOR CREATE travel.

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

  METHOD validateDescription.

  READ ENTITIES OF Z03_R_Travel IN LOCAL MODE ENTITY
     Travel FIELDS ( Description )
     WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

      LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).


     IF <travel>-Description IS INITIAL.
     APPEND VALUE #( %tky = <travel>-%tky )
        TO failed-travel.
     APPEND VALUE #( %tky = <travel>-%tky %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty ) %element-Description = if_abap_behv=>mk-on )
        TO reported-travel.
     ENDIF.

     ENDLOOP.

  ENDMETHOD.

  METHOD validateCustomer.
    READ ENTITIES OF Z03_R_Travel IN LOCAL MODE ENTITY Travel
    FIELDS ( CustomerId ) WITH CORRESPONDING #( keys )
    RESULT DATA(travels). LOOP AT travels
     ASSIGNING FIELD-SYMBOL(<travel>).
     IF <travel>-CustomerId IS INITIAL.
      APPEND VALUE #( %tky = <travel>-%tky ) TO failed-travel.
      APPEND VALUE #( %tky = <travel>-%tky %msg = NEW /lrn/cm_s4d437(
                    /lrn/cm_s4d437=>field_empty )
                    %element-CustomerId = if_abap_behv=>mk-on )
      TO reported-travel.

      SELECT SINGLE FROM /dmo/i_customer FIELDS CustomerID
      WHERE CustomerID = @<travel>-CustomerId INTO @DATA(dummy).
       IF sy-subrc <> 0. APPEND VALUE #( %tky = <travel>-%tky )
       TO failed-travel. APPEND VALUE #( %tky = <travel>-%tky %msg = NEW /lrn/cm_s4d437( textid = /lrn/cm_s4d437=>customer_not_exist customerid = <travel>-CustomerId ) %element-CustomerId = if_abap_behv=>mk-on )
       TO reported-travel. ENDIF.
      ENDIF.
      ENDLOOP.

  ENDMETHOD.

  METHOD earlynumbering_create.
    DATA(agencyid) = /lrn/cl_s4d437_model=>get_agency_by_user( ).
    mapped-travel = CORRESPONDING #( entities ).

    LOOP AT mapped-travel ASSIGNING FIELD-SYMBOL(<mapping>).
    <mapping>-AgencyId = agencyid.
    <mapping>-TravelId = /lrn/cl_s4d437_model=>get_next_travelid( ).
    ENDLOOP.
  ENDMETHOD.

  METHOD determineStatus.
    READ ENTITIES OF Z03_R_Travel IN LOCAL MODE ENTITY Travel
    FIELDS ( Status ) WITH CORRESPONDING #( keys )
    RESULT DATA(travels).

    DELETE travels WHERE Status IS NOT INITIAL.
    CHECK travels IS NOT INITIAL.
     MODIFY ENTITIES OF Z03_R_Travel IN LOCAL MODE ENTITY Travel
     UPDATE FIELDS ( Status ) WITH VALUE #( FOR key IN travels ( %tky = key-%tky Status = 'N' ) )
     REPORTED DATA(update_reported). reported = CORRESPONDING #( DEEP update_reported ).
  ENDMETHOD.

ENDCLASS.
