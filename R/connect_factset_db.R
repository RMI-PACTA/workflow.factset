# Connection function

connect_factset_db <-
  function(
      dbname = "delta",
      host = "data-eval-db.postgres.database.azure.com",
      port = 5432L,
      options = "-c search_path=fds",
      username = Sys.getenv("R_DATABASE_USER"),
      password = Sys.getenv("R_DATABASE_PASSWORD"),
      keyring_service_name = "2dii_factset_database") {

    if (username == "") {
      logger::log_error("No database username could be found. Please set the username as an environment variable")
    }

    if (password == "") {
      # if password not defined in .env, look in systems keyring
      if (requireNamespace("keyring", quietly = TRUE)) {
        if (!username %in% keyring::key_list(service = keyring_service_name)$username) {
          keyring::key_set(
            service = keyring_service_name,
            username = username,
            prompt = "Enter password for the FactSet database (it will be stored in your system's keyring): "
          )
        }
        password <- keyring::key_get(
          service = keyring_service_name,
          username = username
        )
      } else if (interactive() && requireNamespace("rstudioapi", quietly = TRUE)) {
        password <- rstudioapi::askForPassword(
          prompt = "Please enter the FactSet database password:"
        )
      } else {
        logger::log_error(
          "No database password could be found. Please set the password
          as an environment variable"
        )
      }
    }

    logger::log_trace(
      "Connecting to database {dbname} on {host}:{port} as {username}"
    )
    conn <-
      DBI::dbConnect(
        drv = RPostgres::Postgres(),
        dbname = dbname,
        host = host,
        port = port,
        user = username,
        password = password,
        options = options
      )

    reg_conn_finalizer(conn, DBI::dbDisconnect, parent.frame())
  }

# connection finalizer to ensure connection is closed --------------------------
# adapted from: https://shrektan.com/post/2019/07/26/create-a-database-connection-that-can-be-disconnected-automatically/

reg_conn_finalizer <- function(conn, close_fun, envir) {
  is_parent_global <- identical(.GlobalEnv, envir)

  if (isTRUE(is_parent_global)) {
    env_finalizer <- new.env(parent = emptyenv())
    env_finalizer$conn <- conn
    attr(conn, "env_finalizer") <- env_finalizer

    reg.finalizer(env_finalizer, function(e) {
      if (DBI::dbIsValid(e$conn)) {
        logger::log_warn("Warning: A database connection was closed automatically because the connection object was removed or the R session was closed.")
        try(close_fun(e$conn))
      }
    }, onexit = TRUE)
  } else {
    withr::defer(
      {
        if (DBI::dbIsValid(conn)) {
          dbname <- DBI::dbGetInfo(conn)$dbname
          host <- DBI::dbGetInfo(conn)$host

          logger::log_warn(
            "The database connection to {dbname} on {host} was
        closed automatically because the calling environment was closed."
          )
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
