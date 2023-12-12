#' Export files for use in PACTA data preparation
#'
#' @param Destination directory for the output files
#'
#' @param ... Arguments to be passed to the `connect_factset_db()` function (for
#'   specifying database connection parameters)
#'
#' @return NULL
#'
#' @export

export_pacta_files <- function(
  destination = file.path("."),
  data_timestamp = Sys.time(),
  ...
) {

  factset_entity_info_path <- file.path(destination, "factset_entity_info.rds")
  logger::log_info("Fetching entity info data... ")
  entity_info <- get_factset_entity_info(...)
  saveRDS(object = entity_info, file = factset_entity_info_path)

  return(invisible(NULL))
}
