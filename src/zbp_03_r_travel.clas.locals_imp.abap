CLASS lsc_z03_r_travel DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

   METHODS save_modified REDEFINITION.

   PRIVATE SECTION.
   METHODS map_message IMPORTING i_msg TYPE symsg RETURNING VALUE(r_msg) TYPE REF TO if_abap_behv_message.


ENDCLASS.

CLASS lsc_z03_r_travel IMPLEMENTATION.


  METHOD save_modified.
  DATA(model) = NEW /lrn/cl_s4d437_tritem(
                          i_table_name = 'Z00_TRITEM' ).

  LOOP AT delete-travelitem ASSIGNING FIELD-SYMBOL(<item_d>).
  model->delete_item( i_uuid = <item_d>-itemuuid ).
  DATA(msg_d) = model->delete_item( i_uuid = <item_d>-itemuuid ).
  IF msg_d IS NOT INITIAL. APPEND VALUE #( %tky-itemuuid = <item_d>-itemuuid %msg = map_message( msg_d ) ) TO reported-travelitem.
  ENDIF.

  ENDLOOP.

  LOOP AT create-travelitem ASSIGNING FIELD-SYMBOL(<item_c>).
  DATA(msg_c) = model->create_item( i_item = CORRESPONDING #( <item_c> MAPPING FROM ENTITY ) )
  .IF msg_c IS NOT INITIAL. APPEND VALUE #( %tky-itemuuid = <item_c>-itemuuid %msg = map_message( msg_c ) )
  TO reported-travelitem.
  ENDIF.

  ENDLOOP.


*    IF msg_c IS NOT INITIAL.
*      APPEND VALUE #( %tky-itemuuid = <item_c>-itemuuid
*                      %msg = map_message( msg_c ) )
*          TO reported-item.
*    ENDIF.

 LOOP AT update-travelitem ASSIGNING FIELD-SYMBOL(<item_u>).
  DATA(msg_u) = model->update_item( i_item = CORRESPONDING #( <item_u> MAPPING FROM ENTITY ) i_itemx = CORRESPONDING #( <item_u> MAPPING FROM ENTITY USING CONTROL ) ).
  IF msg_u IS NOT INITIAL. APPEND VALUE #( %tky-itemuuid = <item_u>-itemuuid %msg = map_message( msg_u ) ) TO reported-travelitem.
  ENDIF.
  ENDLOOP.

*    IF msg_u IS NOT INITIAL.
*      APPEND VALUE #( %tky-itemuuid = <item_u>-itemuuid
*                      %msg = map_message( msg_u ) )
*          TO reported-item.
*    ENDIF.

*    IF update-travel IS NOT INITIAL.
*      RAISE ENTITY EVENT Z00_R_Travel~TravelCreated
*          FROM VALUE #( FOR <new_travel> IN update-travel
*                            ( AgencyId = <new_travel>-AgencyId
*                              TravelId = <new_travel>-TravelId
*                              origin = 'Update 00' )
*                          ).
*    ENDIF.

    IF create-travel IS NOT INITIAL.
*      RAISE ENTITY EVENT Z03_R_Travel~TravelCreated
*      FROM CORRESPONDING #( create-travel ).
    DATA event_in TYPE TABLE FOR EVENT Z03_R_Travel~TravelCreated.
    LOOP AT create-travel ASSIGNING FIELD-SYMBOL(<new_travel>).
     APPEND VALUE #( AgencyId = <new_travel>-AgencyId TravelId = <new_travel>-TravelId origin = 'Z03_R_TRAVEL' ) TO event_in.
    ENDLOOP.
      RAISE ENTITY EVENT Z03_R_Travel~TravelCreated FROM event_in.

    ENDIF.


*    IF lcl_event_buffer=>travel IS NOT INITIAL.
*      RAISE ENTITY EVENT Z03_R_Travel~TravelCreated
*          FROM VALUE #( ( AgencyId = lcl_event_buffer=>travel-AgencyId
*                          TravelId = lcl_event_buffer=>travel-TravelId
*                          origin = 'Cancel Travel 00' )
*                       ).
*    ENDIF.



  ENDMETHOD.

  METHOD map_message.
    DATA severity TYPE if_abap_behv_message=>t_severity.
    CASE i_msg-msgty. WHEN 'S'. severity = if_abap_behv_message=>severity-success.
     WHEN 'I'. severity = if_abap_behv_message=>severity-information.
     WHEN 'W'. severity = if_abap_behv_message=>severity-warning.
     WHEN 'E'. severity = if_abap_behv_message=>severity-error.
     WHEN OTHERS. severity = if_abap_behv_message=>severity-none.
    ENDCASE.

    r_msg = new_message( id = i_msg-msgid number = i_msg-msgno severity = severity v1 = i_msg-msgv1 v2 = i_msg-msgv2 v3 = i_msg-msgv3 v4 = i_msg-msgv4 ).
  ENDMETHOD.

ENDCLASS.

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
    METHODS get_instance_features FOR INSTANCE FEATURES
      keys REQUEST requested_features FOR travel RESULT result.

    METHODS determineduration FOR DETERMINE ON SAVE
      keys FOR travel~determineduration.
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

  CONSTANTS c_area TYPE string VALUE `DESC`.
  READ ENTITIES OF Z03_R_Travel IN LOCAL MODE ENTITY
     Travel FIELDS ( Description )
     WITH CORRESPONDING #( keys )
      RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).

     APPEND VALUE #( %tky = <travel>-%tky %state_area = c_area ) TO reported-travel.
     IF <travel>-Description IS INITIAL.

      APPEND VALUE #( %tky = <travel>-%tky %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty )
         %element-Description = if_abap_behv=>mk-on
         %state_area = c_area )
        TO reported-travel.
     ENDIF.

     ENDLOOP.

  ENDMETHOD.

  METHOD validateCustomer.
    CONSTANTS c_area TYPE string VALUE `CUST`.
    READ ENTITIES OF Z03_R_Travel IN LOCAL MODE ENTITY Travel
    FIELDS ( CustomerId ) WITH CORRESPONDING #( keys )
    RESULT DATA(travels).
    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
    APPEND VALUE #( %tky = <travel>-%tky %state_area = c_area ) TO reported-travel.
     IF <travel>-CustomerId IS INITIAL.
      APPEND VALUE #( %tky = <travel>-%tky ) TO failed-travel.
      APPEND VALUE #( %tky = <travel>-%tky %msg = NEW /lrn/cm_s4d437( /lrn/cm_s4d437=>field_empty )
             %element-CustomerId = if_abap_behv=>mk-on
             %state_area = c_area ) TO reported-travel.

      SELECT SINGLE FROM /dmo/i_customer FIELDS CustomerID
      WHERE CustomerID = @<travel>-CustomerId INTO @DATA(dummy).
       IF sy-subrc <> 0.
        APPEND VALUE #( %tky = <travel>-%tky ) TO failed-travel.
       APPEND VALUE #( %tky = <travel>-%tky %msg = NEW /lrn/cm_s4d437( textid = /lrn/cm_s4d437=>customer_not_exist customerid = <travel>-CustomerId )
                %element-CustomerId = if_abap_behv=>mk-on
                %state_area = c_area ) TO reported-travel.

       ENDIF.
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

  METHOD get_instance_features.


  ENDMETHOD.

  METHOD determineDuration.

   READ ENTITIES OF Z03_R_Travel IN LOCAL MODE ENTITY Travel FIELDS ( BeginDate EndDate ) WITH CORRESPONDING #( keys )
    RESULT DATA(travels).
    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
    <travel>-Duration = <travel>-EndDate - <travel>-BeginDate.
    ENDLOOP.
   MODIFY ENTITIES OF Z03_R_Travel IN LOCAL MODE ENTITY Travel UPDATE FIELDS ( Duration ) WITH CORRESPONDING #( travels ).


  ENDMETHOD.

ENDCLASS.
