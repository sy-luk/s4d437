CLASS lhc_travelitem DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS ZZValidateClass FOR VALIDATE ON SAVE
      keys FOR TravelItem~ZZValidateClass.

ENDCLASS.

CLASS lhc_travelitem IMPLEMENTATION.

  METHOD ZZValidateClass.

*
 CONSTANTS c_area TYPE string VALUE `CLASS`.

    READ ENTITIES OF Z03_r_travel IN LOCAL MODE
      ENTITY TravelItem
      FIELDS ( agencyid travelid ZZClassZ03 )
      WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    LOOP AT items ASSIGNING FIELD-SYMBOL(<item>).

      APPEND VALUE #( %tky = <item>-%tky
                      %state_area = c_area
                     )
          TO reported-travelitem.

      IF <item>-ZZClassZ03 IS INITIAL.

        APPEND VALUE #(  %tky = <item>-%tky )
            TO failed-travelitem.

        APPEND VALUE #( %tky = <item>-%tky
                        %msg = NEW /lrn/cm_s4d437(
                                     /lrn/cm_s4d437=>field_empty
                                   )
                        %element-ZZCLassZ03 = if_abap_behv=>mk-on
                        %state_area = c_area
                        %path-travel = CORRESPONDING #( <item> )
                       )
            TO reported-travelitem.
      ELSE.

        SELECT SINGLE
          FROM /lrn/437_i_classstdvh WITH PRIVILEGED ACCESS
        FIELDS classid
         WHERE classid = @<item>-ZZClassZ03
          INTO @DATA(dummy).

        IF sy-subrc <> 0.

          APPEND VALUE #(  %tky = <item>-%tky )
              TO failed-travelitem.

          APPEND VALUE #( %tky = <item>-%tky
                          %msg = NEW /lrn/cm_s4d437(
                                       textid   = /lrn/cm_s4d437=>class_not_exist
                                       classid  = <item>-ZZClassZ03
                                     )
                          %element-ZZCLassZ03 = if_abap_behv=>mk-on
                          %state_area = c_area
                        %path-travel = CORRESPONDING #( <item> )
                         )
          TO reported-travelitem.

        ENDIF.
      ENDIF.
    ENDLOOP.



*
  ENDMETHOD.

ENDCLASS.

CLASS lsc_Z03_R_TRAVEL DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_Z03_R_TRAVEL IMPLEMENTATION.

  METHOD save_modified.

  LOOP AT update-travelitem ASSIGNING FIELD-SYMBOL(<item>) WHERE %control-ZZClassZ03 = if_abap_behv=>mk-on.
  UPDATE z03_tritem SET zzclassz03 = @<item>-ZZClassZ03 WHERE item_uuid = @<item>-ItemUuid.
  ENDLOOP.


  LOOP AT create-travelitem ASSIGNING <item> WHERE %control-ZZClassZ03 = if_abap_behv=>mk-on.
  UPDATE z03_tritem SET zzclassz03 = @<item>-ZZClassZ03 WHERE item_uuid = @<item>-ItemUuid.
  ENDLOOP.
 ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
