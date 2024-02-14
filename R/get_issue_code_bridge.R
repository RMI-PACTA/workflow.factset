#' Get the factset issue code bridge
#'
#' @param conn database connection
#'
#' @return A tibble properly prepared to be saved as the
#'   `factset_issue_code_bridge.rds` output file
#'
#' @export

get_issue_code_bridge <- function(conn) {
  # build connection to database ---------------------------------------------

  logger::log_debug("Extracting Issue Code bridge.")


  # factset_entity_id -----------------------------------------------

  logger::log_trace("Accessing issue type map.")
  issue_type_map <- dplyr::tbl(conn, "ref_v2_issue_type_map")

  logger::log_trace("Accessing asset class map.")
  asset_class_map <- dplyr::tbl(conn, "ref_v2_asset_class_map")

  # merge and collect --------------------------------------------------------

  logger::log_trace("Merging issue type and asset class maps.")
  factset_issue_code_bridge <- issue_type_map %>%
    dplyr::left_join(asset_class_map, by = "asset_class_code") %>%
    dplyr::select(
      "issue_type_code",
      "issue_type_desc",
      "asset_class_code",
      "asset_class_desc"
    )

  logger::log_trace("Downloading merged financial info from database.")
  factset_issue_code_bridge <- dplyr::collect(factset_issue_code_bridge)
  logger::log_trace("Download complete.")

  logger::log_trace("Adding PACTA Asset types to issue code bridge.")
  pacta_issue_code_bridge <- factset_issue_code_bridge %>%
    dplyr::mutate(
      asset_type = dplyr::case_when(
        issue_type_desc == "Bond" ~ "Corporate Bond",
        issue_type_desc == "Convertible Bond" ~ "Corporate Bond",
        issue_type_desc == "Debenture" ~ "Corporate Bond",
        issue_type_desc == "Medium Term Note" ~ "Corporate Bond",
        issue_type_desc == "Note" ~ "Corporate Bond",
        issue_type_desc == "Closed-End Mutual Fund" ~ "Fund",
        issue_type_desc == "Exchange Traded Fund" ~ "Fund",
        issue_type_desc == "Open-End Mutual Fund" ~ "Fund",
        issue_type_desc == "ADR/GDR" ~ "Listed Equity", #nolint: nonportable_path_linter
        issue_type_desc == "Convertible Preferred" ~ "Listed Equity",
        issue_type_desc == "Dual Listing" ~ "Listed Equity",
        issue_type_desc == "Equity" ~ "Listed Equity",
        issue_type_desc == "Equity (Pre-IPO)" ~ "Listed Equity",
        issue_type_desc == "Preferred" ~ "Listed Equity",
        TRUE ~ "Other"
      )
    )

  # return prepared data -----------------------------------------------------
  return(pacta_issue_code_bridge)
}
