#' Export files for use in PACTA data preparation
#'
#' @param Destination directory for the output files
#'
#' @param destination path to directory where exported files will be saved
#' @param data_timestamp filter data as-of this timestamp
#'
#' @return vector of paths to exported files
#'
#' @export

export_pacta_files <- function(
  conn = connect_factset_db(),
  destination = file.path(Sys.getenv("EXPORT_DESTINATION")),
  data_timestamp = Sys.getenv("DATA_TIMESTAMP", Sys.time()),
  create_tar = TRUE,
  terminate_connection = (
    # Terminate connection if it was created by this function.
    deparse(substitute(conn)) == formals(export_pacta_files)[["conn"]]
  )
) {

  # Prepare output directories

  if (!dir.exists(destination)) {
    logger::log_error(
      "The destination directory ",
      destination,
      " does not exist."
    )
    stop("Destination directory does not exist.")
  }

  if (Sys.getenv("DEPLOY_START_TIME") == "") {
    logger::log_warn(
      "The environment variable DEPLOY_START_TIME is not set. ",
      "Using current system time as start time."
    )
  }

  start_time_chr <- Sys.getenv(
    "DEPLOY_START_TIME",
    format(Sys.time(), format = "%Y%m%dT%H%M%SZ", tz = "UTC"),
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
    data_timestamp_chr <- format(
      data_timestamp,
      format = "%Y%m%dT%H%M%SZ",
      tz = "UTC"
    )
  } else {
    logger::log_error(
      "The data_timestamp argument must be a POSIXct object ",
      "or a character string coercible to POSIXct format",
      " (using lubridate::ymd_hms(truncated = 3))."
    )
    stop("Invalid data_timestamp argument.")
  }

  export_dir <- file.path(
    destination,
    paste0(
      "factset-pacta", "_",
      "timestamp-", data_timestamp_chr, "_",
      "pulled-", start_time_chr
    )
  )

  if (!dir.exists(export_dir)) {
    dir.create(export_dir, recursive = TRUE)
  }

  # Export metadata
  metadata_path <- file.path(export_dir, "metadata.json")
  logger::log_info("Exporting metadata to ", metadata_path)
  logger::log_debug("Collecting metadata.")
  metadata <- Sys.getenv(
    c(
      "DATA_TIMESTAMP",
      "DEPLOY_START_TIME",
      "EXPORT_DESTINATION",
      "HOSTNAME",
      "LOG_LEVEL",
      "MACHINE_CORES",
      "PGDATABASE",
      "PGHOST",
      "PGUSER"
    )
  )
  metadata_json <- character()
  for (i in seq_along(metadata)) {
    metadata_json[[i]] <- paste0(
      '  "',
      names(metadata)[i],
      '": "',
      metadata[[i]],
      '"'
    )
  }
  metadata_string <- paste0(
    "{\n",
    paste(metadata_json, collapse = ",\n"),
    "\n}"
  )
  logger::log_debug("Writing metadata to file: ", metadata_path)
  writeLines(metadata_string, metadata_path)

  # Start Extracting Data

  financial_data_path <- file.path(
    export_dir,
    "factset_financial_data.rds"
  )
  logger::log_info("Fetching financial data.")
  financial_data <- get_financial_data(
    conn = conn,
    data_timestamp = data_timestamp
  )
  logger::log_info("Exporting financial data to ", financial_data_path)
  saveRDS(object = financial_data, file = financial_data_path)

  entity_info_path <- file.path(export_dir, "factset_entity_info.rds")
  logger::log_info("Fetching entity info data.")
  entity_info <- get_entity_info(conn = conn)
  logger::log_info("Exporting entity info data to ", entity_info_path)
  saveRDS(object = entity_info, file = entity_info_path)

  entity_financing_data_path <- file.path(
    export_dir,
    "factset_entity_financing_data.rds"
  )
  logger::log_info("Fetching entity financing data.")
  entity_financing_data <- get_entity_financing_data(
    conn = conn,
    data_timestamp = data_timestamp
  )
  logger::log_info(
    "Exporting entity financing data to ", entity_financing_data_path
  )
  saveRDS(
    object = entity_financing_data,
    file = entity_financing_data_path
  )

  fund_data_path <- file.path(export_dir, "factset_fund_data.rds")
  logger::log_info("Fetching fund data.")
  fund_data <- get_fund_data(
    conn = conn,
    data_timestamp = data_timestamp
  )
  logger::log_info("Exporting fund data to ", fund_data_path)
  saveRDS(object = fund_data, file = fund_data_path)

  isin_to_fund_table_path <- file.path(
    export_dir,
    "factset_isin_to_fund_table.rds"
  )
  logger::log_info("Fetching ISIN to fund table.")
  isin_to_fund_table <- get_isin_to_fund_table(conn = conn)
  logger::log_info(
    "Exporting ISIN to fund table to ", isin_to_fund_table_path
  )
  saveRDS(object = isin_to_fund_table, file = isin_to_fund_table_path)

  iss_emissions_path <- file.path(
    export_dir,
    "factset_iss_emissions.rds"
  )
  logger::log_info("Fetching ISS emissions data.")
  iss_emissions <- get_iss_emissions_data(
    conn = conn,
    reporting_year = lubridate::year(data_timestamp)
  )
  logger::log_info(
    "Exporting ISS emissions data to ", iss_emissions_path
  )
  saveRDS(object = iss_emissions, file = iss_emissions_path)


  logger::log_info("Done with data export.")

  # Terminate connection if needed
  if (terminate_connection) {
    logger::log_info("Terminating database connection.")
    DBI::dbDisconnect(conn)
  }

  # Create tar file if requested
  if (create_tar) {
    logger::log_debug("Creating tar file.")
    tar_file_path <- file.path(
      export_dir,
      paste0(basename(export_dir), ".tar.gz")
    )
    system2(
      command = "tar",
      args = c(
        "--create",
        "--exclude-backups",
        "--exclude-vcs",
        "--gzip",
        "--verbose",
        "-C", dirname(export_dir),
        paste0("--file=", tar_file_path),
        basename(export_dir)
      )
    )
    logger::log_info("Tar file created at ", tar_file_path)
  }

  return(
    invisible(
      c(
        financial_data_path = financial_data_path,
        entity_info_path = entity_info_path,
        entity_financing_data_path = entity_financing_data_path,
        fund_data_path = fund_data_path,
        isin_to_fund_table_path = isin_to_fund_table_path,
        iss_emissions_path = iss_emissions_path
      )
    )
  )
}
