#' Get the factset insustry map bridge
#'
#' @param conn database connection
#'
#' @return A tibble properly prepared to be saved as the
#'   `factset_industry_map_bridge.rds` output file
#'
#' @export

get_industry_map_bridge <- function(conn) {
  logger::log_debug("Extracting Industry Map bridge.")

  logger::log_trace("Accessing industry map.")
  factset_industry_map <- dbplyr::tbl(conn, "ref_v2_factset_industry_map")

  logger::log_trace("Downloading industry map from database.")
  factset_industry_map <- dplyr::collect(factset_industry_map)
  logger::log_trace("Download complete.")

  logger::log_trace("Adding PACTA Asset types to issue code bridge.")
  pacta_industry_map_bridge <- factset_industry_map %>%
    dplyr::mutate(
      pacta_sector = dplyr::case_when(
        factset_industry_desc == "Motor Vehicles" ~ "Automotive",
        factset_industry_desc == "Air Freight/Couriers" ~ "Aviation", #nolint: nonportable_path_linter
        factset_industry_desc == "Airlines" ~ "Aviation",
        factset_industry_desc == "Construction Materials" ~ "Cement",
        factset_industry_desc == "Coal" ~ "Coal",
        factset_industry_desc == "Trucking" ~ "HDV",
        factset_industry_desc == "Trucks/Construction/Farm Machinery" ~ "HDV", #nolint: nonportable_path_linter
        factset_industry_desc == "Gas Distributors" ~ "Oil&Gas",
        factset_industry_desc == "Integrated Oil" ~ "Oil&Gas",
        factset_industry_desc == "Oil & Gas Pipelines" ~ "Oil&Gas",
        factset_industry_desc == "Oil & Gas Production" ~ "Oil&Gas",
        factset_industry_desc == "Alternative Power Generation" ~ "Power",
        factset_industry_desc == "Electric Utilities" ~ "Power",
        factset_industry_desc == "Marine Shipping" ~ "Shipping",
        factset_industry_desc == "Steel" ~ "Steel",
        TRUE ~ "Other"
      )
    )

  # return prepared data -----------------------------------------------------
  return(pacta_industry_map_bridge)
}
