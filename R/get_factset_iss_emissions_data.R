#' Get the ISS emissions data from the FactSet database and prepare the
#' `factset_iss_emissions` tibble
#'
#' @param year A single numeric specifying the year of data to be returned
#' @param min_estimated_trust A single numeric specifying the minimum allowed
#'   "estimated trust" value
#' @param min_reported_trust A single numeric specifying the minimum allowed
#'   "reported trust" value
#' @param ... Arguments to be passed to the `connect_factset_db()` function (for
#'   specifying database connection parameters)
#'
#' @return A tibble properly prepared to be saved as the
#'   `factset_iss_emissions.rds` output file
#'
#' @export

get_factset_iss_emissions_data <-
  function(year, min_estimated_trust = 0.0, min_reported_trust = 0.0, ...) {
    # convert `year` to date ---------------------------------------------------
    year_month_date <- as.Date(paste0(year, "-01-01"), "%Y-%m-%d")


    # connect to the FactSet database ------------------------------------------
    factset_db <- connect_factset_db(...)


    # get the relevant fsym_id to factset_entity_id table ----------------------

    fsym_id__factset_entity_id <-
      tbl(factset_db, "icc_v2_icc_sec_entity_hist") %>%
      # end_date identifies the date the identifier was last associated with fsym_id
      # i.e. if there is no end_date (end_date == NA) then the association is still valid
      filter(.data$end_date >= .env$year_month_date | is.na(.data$end_date)) %>%
      filter(!is.na(.data$fsym_id)) %>%
      filter(!is.na(.data$factset_entity_id)) %>%
      select("fsym_id", "factset_entity_id") %>%
      distinct()


    # get the relevant icc_security_id to factset_entity_id table --------------

    icc_security_id__factset_entity_id <-
      tbl(factset_db, "icc_v2_icc_factset_id_map") %>%
      filter(.data$provider_id_type == "icc_security_id") %>%
      filter(.data$factset_id_type == "fsym_security_id") %>%
      filter(!is.na(.data$factset_id)) %>%
      # do not use a fsym_id that was started in the current year to avoid data
      # based on a partial year
      filter(.data$id_start_date < .env$year_month_date) %>%
      # end_date identifies the date the identifier was last associated with fsym_id
      # i.e. if there is no end_date (end_date == NA) then the association is still valid
      filter(.data$id_end_date >= .env$year_month_date | is.na(.data$id_end_date)) %>%
      select(icc_security_id = "provider_id", fsym_id = "factset_id") %>%
      inner_join(fsym_id__factset_entity_id, by = "fsym_id") %>%
      select("icc_security_id", "factset_entity_id") %>%
      distinct()


    # get the factset_entity_id to icc_total_emissions data --------------------

    factset_entity_id__icc_total_emissions <-
      tbl(factset_db, "icc_v2_icc_carbon_climate_core") %>%
      filter(.data$icc_emissions_fiscal_year == .env$year) %>%
      group_by(.data$icc_security_id, .data$icc_emissions_fiscal_year) %>%
      # icc_archive_date marks the date a data point was submitted, and some times there are updates of
      # previous data submissions, so we need to filter only for the most recent submission
      filter(.data$icc_archive_date == max(.data$icc_archive_date, na.rm = TRUE)) %>%
      ungroup() %>%
      group_by(.data$icc_company_id, .data$icc_emissions_fiscal_year) %>%
      filter(.data$icc_archive_date == max(.data$icc_archive_date, na.rm = TRUE)) %>%
      ungroup() %>%
      filter(
        .data$icc_emissions_estimated_trust > min_estimated_trust |
          .data$icc_emissions_reported_trust > min_reported_trust
      ) %>%
      select("icc_security_id", "icc_total_emissions", "icc_scope_3_emissions") %>%
      inner_join(icc_security_id__factset_entity_id, by = "icc_security_id") %>%
      select("factset_entity_id", "icc_total_emissions", "icc_scope_3_emissions")


    # collect the data, then disconnect ----------------------------------------

    factset_entity_id__icc_total_emissions <-
      factset_entity_id__icc_total_emissions %>%
      dplyr::collect()

    DBI::dbDisconnect(factset_db)


    # return the factset_entity_id to icc_total_emissions data -----------------

    factset_entity_id__icc_total_emissions
  }
