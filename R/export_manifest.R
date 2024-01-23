#' Export manifest file with metadata
#'
#' @param manifest_path Path to the manifest file
#' @param filelist List of files to include in the manifest
#' @param data_timestamp Timestamp of the data
#' @param start_time Timestamp of the start of the export
#' @param export_dir Directory to which data was exported
#'
#' @return (invisible) JSON string with metadata manifest.
#'
#' @export
export_manifest <- function(
  manifest_path,
  filelist,
  data_timestamp,
  start_time,
  export_dir
) {
  logger::log_debug("Collecting metadata.")
  metadata <- list(
    files = get_info_for_files(filelist),
    data_timestamp = data_timestamp,
    start_time = start_time,
    export_dir = export_dir,
    envvars = list(
      DATA_TIMESTAMP = Sys.getenv("DATA_TIMESTAMP"),
      DEPLOY_START_TIME = Sys.getenv("DEPLOY_START_TIME"),
      EXPORT_DESTINATION = Sys.getenv("EXPORT_DESTINATION"),
      HOSTNAME = Sys.getenv("HOSTNAME"),
      LOG_LEVEL = Sys.getenv("LOG_LEVEL"),
      MACHINE_CORES = Sys.getenv("MACHINE_CORES"),
      PGDATABASE = Sys.getenv("PGDATABASE"),
      PGHOST = Sys.getenv("PGHOST"),
      PGPORT = Sys.getenv("PGPORT"),
      PGUSER = Sys.getenv("PGUSER"),
      UPDATE_DB = Sys.getenv("UPDATE_DB"),
      WORKINGSPACEPATH = Sys.getenv("WORKINGSPACEPATH")
    ),
    session = list(
      info = list(
        R.version = sessionInfo()[["R.version"]],
        platform = sessionInfo()[["platform"]],
        running = sessionInfo()[["running"]],
        locale = sessionInfo()[["locale"]],
        loaded_namespaces = as.list(
          vapply(
            X = loadedNamespaces(),
            FUN = function(x) {
              as.character(packageVersion(x))
            },
            FUN.VALUE = character(1L),
            USE.NAMES = TRUE
          )
        )
      )
    ),
    metadata_creation_time_date = format.POSIXct(
      x = Sys.time(),
      format = "%F %R",
      tz = "UTC",
      usetz = TRUE
    )
  )

  # Create the manifest file
  metadata_string <- jsonlite::toJSON(
    metadata,
    pretty = TRUE,
    auto_unbox = TRUE
  )
  logger::log_debug("Writing metadata to file: ", manifest_path)
  writeLines(metadata_string, manifest_path)

  # Return the metadata string
  return(invisible(metadata_string))
}

get_info_for_files <- function(file_paths) {
  output <- list()
  for (f in file_paths) {
    logger::log_trace("Getting info for file: ", f)
    if (!file.exists(f)) {
      logger::log_error("File does not exist: ", f)
      stop("File does not exist: ", f)
    }
    output[[basename(f)]] <- list(
      file_name = basename(f),
      file_extension = tools::file_ext(f),
      file_path = f,
      file_size = file.info(f)[["size"]],
      file_last_modified = format(
        as.POSIXlt(file.info(f)[["mtime"]], tz = "UTC")
        , "%Y-%m-%dT%H:%M:%S+00:00"
      ),
      file_md5 = digest::digest(f, algo = "md5", file = TRUE)
    )
  }
  return(output)
}
