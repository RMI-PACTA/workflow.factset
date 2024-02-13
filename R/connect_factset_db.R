#' Export files for use in PACTA data preparation
#'
#' @param dbname name of the database to connect to
#' @param host hostname of the server to connect to
#' @param port port number of the server to connect to
#' @param options additional options to pass to the database connection.
#' Typically used to define schema search path.
#' @param username username to use for the database connection
#' @param password password to use for the database connection
#'
#' @return a database connection object
#'
#' @export


connect_factset_db <- function(
  dbname = Sys.getenv("PGDATABASE"),
  host = Sys.getenv("PGHOST"),
  port = Sys.getenv("PGPORT", 5432L),
  db_options = "-c search_path=fds",
  username = Sys.getenv("PGUSER"),
  password = Sys.getenv("PGPASSWORD")
) {

  if (username == "") {
    logger::log_error(
      "No database username could be found. ",
      "Please set the username as an environment variable"
    )
  }

  if (password == "") {
    logger::log_error(
      "No database password could be found. ",
      "Please set the password as an environment variable"
    )
  }

  logger::log_trace(
    "Connecting to database ",
    dbname,
    " on ",
    host,
    ":",
    port,
    " as ",
    username,
    ""
  )
  conn <-
    DBI::dbConnect(
      drv = RPostgres::Postgres(),
      dbname = dbname,
      host = host,
      port = port,
      user = username,
      password = password,
      options = db_options
    )

  reg_conn_finalizer(conn, DBI::dbDisconnect, parent.frame())
}

# connection finalizer to ensure connection is closed --------------------------
# adapted from: https://shrektan.com/post/2019/07/26/create-a-database-connection-that-can-be-disconnected-automatically/ #nolint

reg_conn_finalizer <- function(
  conn,
  close_fun,
  envir
) {
  is_parent_global <- identical(.GlobalEnv, envir)

  if (isTRUE(is_parent_global)) {
    env_finalizer <- new.env(parent = emptyenv())
    env_finalizer$conn <- conn
    attr(conn, "env_finalizer") <- env_finalizer

    reg.finalizer(env_finalizer, function(e) {
      if (DBI::dbIsValid(e$conn)) {
        warn_db_autoclose(e$conn)
        try(close_fun(e$conn))
      }
    },
    onexit = TRUE
    )
  } else {
    withr::defer(
      {
        if (DBI::dbIsValid(conn)) {
          warn_db_autoclose(conn)
          try(close_fun(conn))
        }
      },
      envir = envir,
      priority = "last"
    )
  }

  logger::log_trace("Database connection registered for finalization")
  return(conn)
}

warn_db_autoclose <- function(conn) {
  dbname <- DBI::dbGetInfo(conn)$dbname
  host <- DBI::dbGetInfo(conn)$host
  logger::log_warn(
    "The database connection to ",
    dbname,
    " on ",
    host,
    " was closed automatically ",
    "because the calling environment was closed."
  )
}
