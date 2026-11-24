@EndUserText.label: 'Flight Travel (Projection)'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true

define root view entity Z03_C_TRAVEL
  provider contract transactional_query
  as projection on Z03_R_TRAVEL
  {
    key AgencyId,
    key TravelId,
        @Search.defaultSearchElement: true
        @Search.fuzzinessThreshold: 0.8
        Description,
        @Search.defaultSearchElement: true
        CustomerId,
        BeginDate,
        EndDate,
        Status,
        ChangedAt,
        ChangedBy
  }
