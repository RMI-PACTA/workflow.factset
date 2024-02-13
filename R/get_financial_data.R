#' Get the factset financial data from the FactSet database and prepare the
#' `factset_financial_data` tibble
#'
#' @param conn databse connection
#' @param data_timestamp A single string specifying the desired date for the
#'   data in the form "2021-12-31"
#'
#' @return A tibble properly prepared to be saved as the
#'   `factset_financial_data.rds` output file
#'
#' @export

get_financial_data <- function(
  conn,
  data_timestamp
) {
  # build connection to database ---------------------------------------------

  logger::log_debug("Extracting financial info from database.")
  logger::log_info("using data timestamp: ", data_timestamp)


  # factset_entity_id -----------------------------------------------

  logger::log_trace("Accessing entity id.")
  factset_entity_id <- dplyr::tbl(conn, "own_v5_own_sec_entity") %>%
    dplyr::select("fsym_id", "factset_entity_id")


  # isin ---------------------------------------------------------------------

  logger::log_trace("Accessing ISINs.")
  isin <- dplyr::tbl(conn, "sym_v1_sym_isin")


  # adj_price ----------------------------------------------------------------

  logger::log_trace(
    "Accessing share prices. ",
    "Filtering to date: ", data_timestamp
  )
  adj_price <- dplyr::tbl(conn, "own_v5_own_sec_prices") %>%
    dplyr::filter(.data[["price_date"]] == .env[["data_timestamp"]]) %>%
    dplyr::select("fsym_id", "adj_price")


  # adj_shares_outstanding ---------------------------------------------------

  logger::log_trace(
    "Accessing shares outstanding. ",
    "Filtering to date: ", data_timestamp
  )
  adj_shares_outstanding <- dplyr::tbl(conn, "own_v5_own_sec_prices") %>%
    dplyr::filter(.data[["price_date"]] == .env[["data_timestamp"]]) %>%
    dplyr::select("fsym_id", "adj_shares_outstanding")


  # issue_type ---------------------------------------------------------------

  logger::log_trace("Accessing issue type.")
  issue_type <- dplyr::tbl(conn, "own_v5_own_sec_coverage") %>%
    dplyr::select("fsym_id", "issue_type")


  # one_adr_eq ---------------------------------------------------------------

  logger::log_trace("Accessing ADR equivilents.")
  one_adr_eq <- dplyr::tbl(conn, "own_v5_own_sec_adr_ord_ratio") %>%
    dplyr::select(fsym_id = "adr_fsym_id", "one_adr_eq")


  # merge and collect --------------------------------------------------------

  logger::log_trace("Merging financial info.")
  fin_data <- isin %>%
    dplyr::left_join(factset_entity_id, by = "fsym_id") %>%
    dplyr::left_join(adj_price, by = "fsym_id") %>%
    dplyr::left_join(adj_shares_outstanding, by = "fsym_id") %>%
    dplyr::left_join(issue_type, by = "fsym_id") %>%
    dplyr::left_join(one_adr_eq, by = "fsym_id")

  logger::log_trace("Downloading merged financial info from database.")
  fin_data <- dplyr::collect(fin_data)
  logger::log_trace("Download complete.")

  # return prepared data -----------------------------------------------------
  return(fin_data)
}
