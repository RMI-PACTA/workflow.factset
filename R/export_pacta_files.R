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
  destination = file.path(Sys.getenv("EXPORT_DESTINATION")),
  data_timestamp = Sys.getenv("DATA_TIMESTAMP", Sys.time()),
  ...
) {

  # Prepare output directories

  if (!dir.exists(destination)) {
    logger::log_error(
      "The destination directory {destination} does not exist."
    )
    stop("Destination directory does not exist.")
  }

  if (Sys.getenv("DEPLOY_START_TIME") == "") {
    logger::log_warn(
      "The environment variable DEPLOY_START_TIME is not set. ",
      "Using current system time as start time."
    )
  }

  start_time <- Sys.getenv(
    "DEPLOY_START_TIME",
    format(Sys.time(), format = "%Y%m%dT%H%M%S", tz = "UTC"),
    )

  if (inherits(data_timestamp, "character")) {
    data_timestamp <- lubridate::ymd_hms(
      data_timestamp,
      quiet = TRUE,
      tz = "UTC",
      truncated = 3
    )
  }

  if (inherits(data_timestamp, "POSIXct")) {
    data_timestamp <- format(data_timestamp, format = "%Y%m%dT%H%M%S", tz = "UTC")
  }

  export_dir <- file.path(
    destination,
    paste0(data_timestamp, "_pulled", start_time)
    )

  if (!dir.exists(export_dir)) {
    dir.create(export_dir, recursive = TRUE)
  }

  # Start Extracting Data

  factset_entity_info_path <- file.path(export_dir, "factset_entity_info.rds")
  logger::log_info("Fetching entity info data.")
  entity_info <- get_factset_entity_info(...)
  logger::log_info("Exporting entity info data to {factset_entity_info_path}")
  saveRDS(object = entity_info, file = factset_entity_info_path)

  log_info("Done with data export.")
  return(
    invisible(
      list(
        factset_entity_info_path = factset_entity_info_path
      )
    )
  )
}
