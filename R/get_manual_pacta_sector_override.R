#' Get the PACTA manual sector override table
#'
#' @param conn database connection
#'
#' @return A tibble properly prepared to be saved as the
#'   `factset_manual_pacta_sector_override.rds` output file
#'
#' @export

get_manual_sector_override <- function(conn) {
  # build connection to database ---------------------------------------------

  logger::log_debug("Extracting manual PACTA sector override table.")


  # factset_entity_id -----------------------------------------------
  logger::log_trace("Accessing entity information.")
  sym_entity <- dplyr::tbl(conn, "sym_v1_sym_entity")

  logger::log_trace("Preparing company names.")
  company_names <- pacta_override_mapping[["entity_proper_name"]]

  factset_entity_info <- sym_entity %>%
    dplyr::select(
      dplyr::all_of(
        "factset_entity_id",
        "entity_proper_name"
      )
    ) %>%
    dplyr::filter(.data[["entity_proper_name"]] %in% company_names)

  # merge and collect --------------------------------------------------------

  logger::log_trace("Downloading entity information for override companies.")
  factset_entity_info <- dplyr::collect(factset_entity_info)
  logger::log_trace("Download complete.")

  logger::log_trace("Adding PACTA sector overrides.")
  pacta_sector_override <- dplyr::inner_join(
    x = factset_entity_info,
    y = pacta_override_mapping,
    by = dplyr::join_by("entity_proper_name")
  )

  # return prepared data -----------------------------------------------------
  return(pacta_sector_override)
}

pacta_override_mapping <- tibble::tribble(
  ~entity_proper_name, ~pacta_sector,
  "St. Marys Cement Inc. (Canada)", "Cement",
  "Volkswagen Group of America Finance LLC", "Other",
  "City of Dallas (Texas)", "Other",
  "Toyota Motor Credit Corp.", "Other",
  "CNOOC Finance (2012) Ltd.", "Oil&Gas",
  "American Airlines 2016-3 Pass Through Trust", "Aviation"
)
