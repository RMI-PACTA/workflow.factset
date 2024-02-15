#' Export files for use in PACTA data preparation
#'
#' @param Destination directory for the output files
#'
#' @param conn DBI connection object.
#' @param destination path to directory where exported files will be saved
#' @param data_timestamp filter data as-of this timestamp
#' @param iss_reporting_year Reporting year for ISS emissions data
#' @param create_tar Flag to create .tar.gz file of exported files
#' @param wait_for_update Wait for `wait_file` to exist before exporting.
#' Useful when run in conjunction with factset data loader
#' @param wait_file Path to file that indicates that the database update is
#' complete.
#' @param terminate_connection Flag to terminate connection, rather than let
#' finalizer close db connection. Allows for early termination of connection
#' before exporting tar file or metadata.
#'
#' @return vector of paths to exported files
#'
#' @export

export_pacta_files <- function(
  conn = connect_factset_db(),
  destination = file.path(Sys.getenv("EXPORT_DESTINATION")),
  data_timestamp = Sys.getenv("DATA_TIMESTAMP", Sys.time()),
  iss_reporting_year = Sys.getenv("ISS_REPORTING_YEAR", ""),
  create_tar = TRUE,
  wait_for_update = as.logical(Sys.getenv("UPDATE_DB", FALSE)),
  wait_file = file.path(Sys.getenv("WORKINGSPACEPATH"), "done_loader"),
  terminate_connection = (
    # Terminate connection if it was created by this function.
    deparse(substitute(conn)) == formals(export_pacta_files)[["conn"]]
  )
) {

  if (wait_for_update) {
    logger::log_info("Waiting for database update to finish.")
    while (!file.exists(wait_file)) {
      logger::log_debug("Waiting: file not found: ", wait_file)
      Sys.sleep(30L)
    }
    logger::log_info("Database update finished.")
  }

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
    format(Sys.time(), format = "%Y%m%dT%H%M%SZ", tz = "UTC")
  )

  if (inherits(data_timestamp, "character")) {
    data_timestamp <- lubridate::ymd_hms(
      data_timestamp,
      quiet = TRUE,
      tz = "UTC",
      truncated = 3L
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

  if (inherits(iss_reporting_year, "character")) {
    if (nzchar(iss_reporting_year)) {
      iss_reporting_year <- as.integer(iss_reporting_year)
    } else {
      logger::log_warn(
        "The environment variable ISS_REPORTING_YEAR is not set. ",
        "Using data_timestamp - 1 as ISS reporting year."
      )
      iss_reporting_year <- lubridate::year(data_timestamp) - 1L
    }
  }

  unique_pull_string <- paste0(
    "timestamp-", data_timestamp_chr, "_",
    "pulled-", start_time_chr
  )
  export_dir <- file.path(
    destination,
    paste0(
      "factset-pacta", "_",
      unique_pull_string
    )
  )

  if (!dir.exists(export_dir)) {
    dir.create(export_dir, recursive = TRUE)
  }

  # Start Extracting Data

  financial_data_path <- file.path(
    export_dir,
    paste0(unique_pull_string, "_factset_financial_data.rds")
  )
  logger::log_info("Fetching financial data.")
  financial_data <- get_financial_data(
    conn = conn,
    data_timestamp = data_timestamp
  )
  logger::log_info("Exporting financial data to ", financial_data_path)
  saveRDS(object = financial_data, file = financial_data_path)

  entity_info_path <- file.path(
    export_dir,
    paste0(unique_pull_string, "_factset_entity_info.rds")
  )
  logger::log_info("Fetching entity info data.")
  entity_info <- get_entity_info(conn = conn)
  logger::log_info("Exporting entity info data to ", entity_info_path)
  saveRDS(object = entity_info, file = entity_info_path)

  entity_financing_data_path <- file.path(
    export_dir,
    paste0(unique_pull_string, "_factset_entity_financing_data.rds")
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

  fund_data_path <- file.path(
    export_dir,
    paste0(unique_pull_string, "_factset_fund_data.rds")
  )
  logger::log_info("Fetching fund data.")
  fund_data <- get_fund_data(
    conn = conn,
    data_timestamp = data_timestamp
  )
  logger::log_info("Exporting fund data to ", fund_data_path)
  saveRDS(object = fund_data, file = fund_data_path)

  isin_to_fund_table_path <- file.path(
    export_dir,
    paste0(unique_pull_string, "_factset_isin_to_fund_table.rds")
  )
  logger::log_info("Fetching ISIN to fund table.")
  isin_to_fund_table <- get_isin_to_fund_table(conn = conn)
  logger::log_info(
    "Exporting ISIN to fund table to ", isin_to_fund_table_path
  )
  saveRDS(object = isin_to_fund_table, file = isin_to_fund_table_path)

  iss_emissions_path <- file.path(
    export_dir,
    paste0(unique_pull_string, "_factset_iss_emissions.rds")
  )
  logger::log_info("Fetching ISS emissions data.")
  iss_emissions <- get_iss_emissions_data(
    conn = conn,
    reporting_year = iss_reporting_year
  )
  logger::log_info(
    "Exporting ISS emissions data to ", iss_emissions_path
  )
  saveRDS(object = iss_emissions, file = iss_emissions_path)

  sector_override_path <- file.path(
    export_dir,
    paste0(unique_pull_string, "_factset_manual_sector_override.rds")
  )
  sector_override_csv_path <- file.path(
    export_dir,
    paste0(unique_pull_string, "_factset_manual_sector_override.csv")
  )
  logger::log_info("Fetching manual sector override table.")
  manual_sector_override <- get_manual_sector_override(conn = conn)
  logger::log_info(
    "Exporting Industry Map bridge to ", sector_override_path
  )
  saveRDS(object = manual_sector_override, file = sector_override_path)
  write.csv(
    x = manual_sector_override,
    file = sector_override_csv_path,
    na = "",
    row.names = FALSE
  )

  issue_code_bridge_path <- file.path(
    export_dir,
    paste0(unique_pull_string, "_factset_issue_code_bridge.rds")
  )
  logger::log_info("Fetching Issue Code bridge.")
  issue_code_bridge <- get_issue_code_bridge(conn = conn)
  logger::log_info("Exporting Issue Code bridge to ", issue_code_bridge_path)
  saveRDS(object = issue_code_bridge, file = issue_code_bridge_path)

  # Note that this writes to CSV, not RDS.
  entity_ids_path <- file.path(
    export_dir,
    paste0(unique_pull_string, "_factset_entity_ids.csv")
  )
  logger::log_info("Fetching Factset entity IDs.")
  entity_ids <- get_entity_ids(
    conn = conn
  )
  logger::log_info(
    "Exporting FactSet Entity IDs to ", entity_ids_path
  )
  write.csv(
    x = entity_ids,
    file = entity_ids_path,
    na = "",
    row.names = FALSE
  )

  logger::log_info("Done with data export.")

  # Terminate connection if needed
  if (terminate_connection) {
    logger::log_info("Terminating database connection.")
    DBI::dbDisconnect(conn)
  }

  filepaths <- c(
    entity_financing_data_path = entity_financing_data_path,
    entity_ids_path = entity_ids_path,
    entity_info_path = entity_info_path,
    financial_data_path = financial_data_path,
    fund_data_path = fund_data_path,
    isin_to_fund_table_path = isin_to_fund_table_path,
    iss_emissions_path = iss_emissions_path,
    issue_code_bridge_path = issue_code_bridge_path,
    sector_override_path = sector_override_path,
    sector_override_csv_path = sector_override_csv_path
  )

  manifest_path <- file.path(
    export_dir,
    paste0(unique_pull_string, "-factset-export-manifest.json")
  )
  logger::log_info("Writing \"manifest.json\" file to ", manifest_path)
  export_manifest(
    manifest_path = manifest_path,
    filelist = filepaths,
    data_timestamp = data_timestamp_chr,
    start_time = start_time_chr,
    export_dir = export_dir
  )

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
      filepaths
    )
  )
}
