#' Get the ISS emissions data from the FactSet database and prepare the
#' `factset_iss_emissions` tibble
#'
#' @param conn databse connection
#' @param reporting_year A single numeric specifying the year of data to be returned
#' @param min_estimated_trust A single numeric specifying the minimum allowed
#'   "estimated trust" value
#' @param min_reported_trust A single numeric specifying the minimum allowed
#'   "reported trust" value
#'
#' @return A tibble properly prepared to be saved as the
#'   `factset_iss_emissions.rds` output file
#'
#' @export

get_iss_emissions_data <- function(
  conn,
  reporting_year,
  min_estimated_trust = 0.0,
  min_reported_trust = 0.0
) {
  # convert `year` to date ---------------------------------------------------
  sql_filter_date <- as.Date(paste0(reporting_year, "-01-01"), "%Y-%m-%d")

  logger::log_trace("Accessing ICC identifiers.")
  # get the relevant fsym_id to factset_entity_id table ----------------------
  fsym_id__factset_entity_id <- dplyr::tbl(
    conn,
    "icc_v2_icc_sec_entity_hist"
  ) %>%
    # end_date identifies the date the identifier was last associated with
    # fsym_id i.e. if there is no end_date (end_date == NA) then the
    # association is still valid
    dplyr::filter(
      .data[["end_date"]] >= sql_filter_date | is.na(.data[["end_date"]])
    ) %>%
    dplyr::filter(!is.na(.data[["fsym_id"]])) %>%
    dplyr::filter(!is.na(.data[["factset_entity_id"]])) %>%
    dplyr::select("fsym_id", "factset_entity_id") %>%
    dplyr::distinct()


  # get the relevant icc_security_id to factset_entity_id table --------------

  logger::log_trace("Accessing ICC security info.")
  icc_security_id <- dplyr::tbl(conn, "icc_v2_icc_factset_id_map") %>%
    dplyr::filter(.data[["provider_id_type"]] == "icc_security_id") %>%
    dplyr::filter(.data[["factset_id_type"]] == "fsym_security_id") %>%
    dplyr::filter(!is.na(.data[["factset_id"]])) %>%
    # do not use a fsym_id that was started in the current year to avoid data
    # based on a partial year
    dplyr::filter(.data[["id_start_date"]] < sql_filter_date) %>%
    # end_date identifies the date the identifier was last associated with
    # fsym_id i.e. if there is no end_date (end_date == NA) then the
    # association is still valid
    dplyr::filter(
      .data[["id_end_date"]] >= sql_filter_date | is.na(.data[["id_end_date"]])
    ) %>%
    dplyr::select(icc_security_id = "provider_id", fsym_id = "factset_id") %>%
    dplyr::inner_join(fsym_id__factset_entity_id, by = "fsym_id") %>%
    dplyr::select("icc_security_id", "factset_entity_id") %>%
    dplyr::distinct()


  # get the factset_entity_id to icc_total_emissions data --------------------

  logger::log_trace("Accessing ICC emissions data.")
  icc_total_emissions <- dplyr::tbl(conn, "icc_v2_icc_carbon_climate_core") %>%
    dplyr::filter(
      .data[["icc_emissions_fiscal_year"]] == .env[["reporting_year"]]
    ) %>%
    dplyr::group_by(
      .data[["icc_security_id"]],
      .data[["icc_emissions_fiscal_year"]]
    ) %>%
    # icc_archive_date marks the date a data point was submitted, and some
    # times there are updates of previous data submissions, so we need to
    # dplyr::filter only for the most recent submission
    dplyr::filter(
      .data[["icc_archive_date"]] == max(
        .data[["icc_archive_date"]],
        na.rm = TRUE
      )
    ) %>%
    dplyr::ungroup() %>%
    dplyr::group_by(
      .data[["icc_company_id"]],
      .data[["icc_emissions_fiscal_year"]]
    ) %>%
    dplyr::filter(
      .data[["icc_archive_date"]] == max(
        .data[["icc_archive_date"]],
        na.rm = TRUE
      )
    ) %>%
    dplyr::ungroup() %>%
    dplyr::filter(
      .data[["icc_emissions_estimated_trust"]] > min_estimated_trust |
        .data[["icc_emissions_reported_trust"]] > min_reported_trust
    ) %>%
    dplyr::select(
      "icc_security_id",
      "icc_total_emissions",
      "icc_scope_3_emissions"
    ) %>%
    dplyr::inner_join(icc_security_id, by = "icc_security_id") %>%
    dplyr::select(
      "factset_entity_id",
      "icc_total_emissions",
      "icc_scope_3_emissions"
    )

  # collect the data, then disconnect ----------------------------------------

  logger::log_trace("Downloading emissions data.")
  icc_total_emissions <- icc_total_emissions %>%
    dplyr::collect()

  # return the factset_entity_id to icc_total_emissions data -----------------

  return(icc_total_emissions)
}
