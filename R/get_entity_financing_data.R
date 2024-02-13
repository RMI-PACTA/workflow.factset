#' Get the entity financing data from the FactSet database and prepare the
#' `factset_entity_financing_data` tibble
#'
#' @param conn databse connection
#' @param data_timestamp A single string specifying the desired date for the
#'   data in the form "2021-12-31"
#'
#' @return A tibble properly prepared to be saved as the
#'   `factset_entity_financing_data.rds` output file
#'
#' @export

get_entity_financing_data <- function(
  conn,
  data_timestamp
) {
  # get fsym_id to fundamentals fsym_company_id --------------------------------

  logger::log_debug("Extracting entity financing info from database.")
  logger::log_debug("using data timestamp: ", data_timestamp)

  logger::log_trace("Accessing security map - FactSet Fundamentals.")
  ff_fsym_company_id <- dplyr::tbl(conn, "ff_v3_ff_sec_map")

  logger::log_trace("Accessing security map - FactSet Ownership.")
  own_fsym_company_id <- dplyr::tbl(conn, "own_v5_own_sec_map")

  logger::log_trace("UNIONing security maps.")
  fsym_company_id <- dplyr::union_all(
    ff_fsym_company_id,
    own_fsym_company_id
  )


  # get fsym_id to factset_entity_id -------------------------------------------

  logger::log_trace("Accessing security to entity map - FactSet Fundamentals.")
  ff_sec_entity <- dplyr::tbl(conn, "ff_v3_ff_sec_entity")

  logger::log_trace("Accessing security to entity map - FactSet Ownership.")
  own_sec_entity <- dplyr::tbl(conn, "own_v5_own_sec_entity")

  logger::log_trace("UNIONing security to entity maps.")
  sec_entity <- dplyr::union_all(
    ff_sec_entity,
    own_sec_entity
  )


  # get market value data ------------------------------------------------------

  logger::log_trace("Accessing market value data.")
  ff_mkt_val <- dplyr::tbl(conn, "ff_v3_ff_basic_der_af") %>%
    dplyr::select("fsym_id", "date", "currency", "ff_mkt_val")


  # get debt outstanding data --------------------------------------------------

  logger::log_trace("Accessing balance sheet data.")
  ff_debt <- dplyr::tbl(conn, "ff_v3_ff_basic_af") %>%
    dplyr::select("fsym_id", "date", "currency", "ff_debt")


  # merge and collect the data, then disconnect --------------------------------

  data_timestamp_year <- lubridate::year(data_timestamp)
  logger::log_trace("Merging entity financing data.")
  entity_financing_data <- ff_mkt_val %>%
    dplyr::full_join(
      ff_debt,
      by = c("fsym_id", "date", "currency")
    ) %>%
    dplyr::left_join(fsym_company_id, by = "fsym_id") %>%
    dplyr::inner_join(sec_entity, by = c(fsym_company_id = "fsym_id")) %>%
    dplyr::filter(!(is.na(.data$ff_mkt_val) & is.na(.data$ff_debt))) %>%
    dplyr::group_by(.data$fsym_id, .data$currency) %>%
    dplyr::filter(.data$date <= .env$data_timestamp) %>%
    dplyr::filter(
      lubridate::year(.data$date) == data_timestamp_year
    ) %>%
    dplyr::filter(.data$date == max(.data$date)) %>%
    dplyr::ungroup()

  logger::log_trace("Downloading entity financing data.")
  entity_financing_data <- entity_financing_data %>%
    dplyr::collect() %>%
    dplyr::mutate(
      # convert units from millions to units
      ff_mkt_val = .data$ff_mkt_val * 1e6L,
      ff_debt = .data$ff_debt * 1e6L
    ) %>%
    dplyr::distinct()

  # return the entity financing data -------------------------------------------

  entity_financing_data
}
