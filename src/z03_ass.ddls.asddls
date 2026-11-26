@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Assostiation'
@Metadata.ignorePropagatedAnnotations: true
define view entity Z03_ASS 
as select from z03_travel as Travel
association [0..1 ]to /DMO/I_Customer as Customer on 
Customer.CustomerID = Travel.customer_id


{
    key Travel.agency_id as AgencyId,
    key Travel.travel_id as TravelId,
    Travel.description as Description,
    Travel.customer_id as CustomerId,
    Travel.begin_date as BeginDate,
    Travel.end_date as EndDate,
    Travel.status as Status,
    Travel.changed_at as ChangedAt,
    Travel.changed_by as ChangedBy,
    Travel.loc_changed_at as LocChangedAt,
    Customer
}

where Customer.CustomerID = '000055'
