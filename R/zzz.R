.onLoad <- function(lib, pkg) {
  # Work around bug in code checking in R 4.2.2 for use of packages
  # Suppresses NOTE in R CMD CHECK
  # See https://stackoverflow.com/a/75384338
  dbplyr::is.sql(FALSE)
}
