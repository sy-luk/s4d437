CLASS zcl_03_eml DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun .

    CONSTANTS c_agency_id TYPE /dmo/agency_id VALUE '070003'.
    CONSTANTS c_travel_id TYPE /dmo/travel_id VALUE '00004148'.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_03_EML IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    READ ENTITIES OF z03_r_travel
        ENTITY z03_r_travel
        ALL FIELDS WITH
        VALUE #( ( TravelId = c_travel_id
                   AgencyId = c_agency_id )  )

        RESULT DATA(travels)
        FAILED DATA(failed).

        IF failed IS NOT INITIAL .
            out->write( 'Error retriving the travel' ).
        ENDIF.

        MODIFY ENTITIES OF z03_r_travel
        ENTITY z03_r_travel
        UPDATE FIELDS ( Description )
        WITH VALUE #(
                    (   TravelId = c_travel_id
                        AgencyId = c_agency_id
                        Description = 'New description etag' )
                    )
        FAILED failed.

            IF failed is INITIAL.
            COMMIT ENTITIES.
            out->write( 'description updated' ).
            ELSE.
            ROLLBACK ENTITIES.
            out->write( 'Error update description' ).
            ENDIF.

  ENDMETHOD.
ENDCLASS.

