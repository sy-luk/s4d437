@AbapCatalog.viewEnhancementCategory: [#PROJECTION_LIST]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Extension Include for Travel Items'
@Metadata.ignorePropagatedAnnotations: true
@AbapCatalog.extensibility: { extensible: true,
                              allowNewDatasources: false,
                              dataSources: [ 'Item' ],
                              elementSuffix: 'Z03'
                              }
                              
define view entity Z03_E_TravelItem as select from z03_tritem as Item
{
    key item_uuid as ItemUuid
//    agency_id as AgencyId,
//    travel_id as TravelId,
//    carrier_id as CarrierId,
//    connection_id as ConnectionId,
//    flight_date as FlightDate,
//    booking_id as BookingId,
//    passenger_first_name as PassengerFirstName,
//    passenger_last_name as PassengerLastName,
//    changed_at as ChangedAt,
//    changed_by as ChangedBy,
//    loc_changed_at as LocChangedAt
}
