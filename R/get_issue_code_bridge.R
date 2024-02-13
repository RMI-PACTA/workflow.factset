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

  # return prepared data -----------------------------------------------------
  return(factset_issue_code_bridge)
}
