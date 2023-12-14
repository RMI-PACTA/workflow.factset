#' Get the entity financing data from the FactSet database and prepare the
#' `factset_entity_financing_data` tibble
#'
#' @param data_timestamp A single string specifying the desired date for the
#'   data in the form "2021-12-31"
#' @param ... Arguments to be passed to the `connect_factset_db()` function (for
#'   specifying database connection parameters)
#'
#' @return A tibble properly prepared to be saved as the
#'   `factset_entity_financing_data.rds` output file
#'
#' @export

get_factset_entity_financing_data <- function(data_timestamp, ...) {
  # connect to the FactSet database --------------------------------------------

  factset_db <- connect_factset_db(...)

  year <- lubridate::year(data_timestamp)


  # get fsym_id to fundamentals fsym_company_id --------------------------------

  ff_fsym_id__fsym_company_id <- tbl(factset_db, "ff_v3_ff_sec_map")

  own_fsym_id__fsym_company_id <- tbl(factset_db, "own_v5_own_sec_map")

  fsym_id__fsym_company_id <- dplyr::union_all(
    ff_fsym_id__fsym_company_id,
    own_fsym_id__fsym_company_id
  )


  # get fsym_id to factset_entity_id -------------------------------------------

  ff_sec_entity <- tbl(factset_db, "ff_v3_ff_sec_entity")

  own_sec_entity <- tbl(factset_db, "own_v5_own_sec_entity")

  sec_entity <- dplyr::union_all(
    ff_sec_entity,
    own_sec_entity
  )


  # get market value data ------------------------------------------------------

  fsym_id__ff_mkt_val <- tbl(factset_db, "ff_v3_ff_basic_der_af") %>%
    select("fsym_id", "date", "currency", "ff_mkt_val")


  # get debt outstanding data --------------------------------------------------

  fsym_id__ff_debt <- tbl(factset_db, "ff_v3_ff_basic_af") %>%
    select("fsym_id", "date", "currency", "ff_debt")


  # merge and collect the data, then disconnect --------------------------------

  entity_financing_data <- fsym_id__ff_mkt_val %>%
    dplyr::full_join(fsym_id__ff_debt, by = c("fsym_id", "date", "currency")) %>%
    left_join(fsym_id__fsym_company_id, by = "fsym_id") %>%
    inner_join(sec_entity, by = c("fsym_company_id" = "fsym_id")) %>%
    filter(!(is.na(.data$ff_mkt_val) & is.na(.data$ff_debt))) %>%
    group_by(.data$fsym_id, .data$currency) %>%
    filter(.data$date <= .env$data_timestamp) %>%
    filter(lubridate::year(.data$date) == .env$year) %>%
    filter(.data$date == max(.data$date)) %>%
    ungroup() %>%
    collect() %>%
    mutate(
      # convert units from millions to units
      ff_mkt_val = .data$ff_mkt_val * 1e6,
      ff_debt = .data$ff_debt * 1e6
    ) %>%
    distinct()

  DBI::dbDisconnect(factset_db)


  # return the entity financing data -------------------------------------------

  entity_financing_data
}
