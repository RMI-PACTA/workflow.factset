#' Get the fund data from the FactSet database and prepare the
#' `factset_fund_data` tibble
#'
#' @param conn databse connection
#' @param data_timestamp A single string specifying the desired date for the
#'   data in the form "2021-12-31"
#'
#' @return A tibble properly prepared to be saved as the `factset_fund_data.rds`
#'   output file
#'
#' @export

get_fund_data <- function(conn, data_timestamp) {
  # get the fund holdings and the holdings' reported market value ------------

  logger::log_debug("Extracting financial info from database.")
  logger::log_info("using data timestamp: ", data_timestamp)

  logger::log_trace(
    "Accessing historical fund holdings - security level. ",
    "Filtering to date: ", data_timestamp
  )
  fund_security <-
    dplyr::tbl(conn, "own_v5_own_fund_detail") %>%
    dplyr::filter(.data[["report_date"]] == .env[["data_timestamp"]]) %>%
    dplyr::select(
      factset_fund_id = "factset_fund_id",
      holding_fsym_id = "fsym_id",
      holding_reported_mv = "reported_mv"
    )

  logger::log_trace(
    "Accessing historical fund holdings - non-securities. ",
    "Filtering to date: ", data_timestamp
  )
  fund_nonsecurity <-
    dplyr::tbl(conn, "own_v5_own_fund_generic") %>%
    dplyr::filter(.data[["report_date"]] == .env[["data_timestamp"]]) %>%
    dplyr::select(
      factset_fund_id = "factset_fund_id",
      holding_fsym_id = "generic_id",
      holding_reported_mv = "reported_mv"
    )

  logger::log_trace(
    "Combining historical fund holdings - security and non-security."
  )
  fund_holding <-
    dplyr::union_all(
      fund_security,
      fund_nonsecurity
    )


  # get the fund total reported market value ---------------------------------

  logger::log_trace(
    "Accessing historical fund filings.",
    "Filtering to date: ", data_timestamp
  )
  fund_mv <-
    dplyr::tbl(conn, "own_v5_own_ent_fund_filing_hist") %>%
    dplyr::filter(.data[["report_date"]] == .env[["data_timestamp"]]) %>%
    dplyr::select("factset_fund_id", "total_reported_mv")


  logger::log_trace("Accessing current ISIN mappings.")
  # symbology containing the ISIN to fsym_id link
  fsym_id__isin <-
    dplyr::tbl(conn, "sym_v1_sym_isin")


  # merge and collect the data, then disconnect ------------------------------

  logger::log_trace("Merging the data.")
  fund_data <-
    fund_mv %>%
    dplyr::filter(
      .data[["total_reported_mv"]] != 0L | !is.na(.data[["total_reported_mv"]])
    ) %>%
    dplyr::left_join(fund_holding, by = "factset_fund_id") %>%
    dplyr::left_join(fsym_id__isin, by = c(holding_fsym_id = "fsym_id")) %>%
    dplyr::select(
      factset_fund_id = "factset_fund_id",
      fund_reported_mv = "total_reported_mv",
      holding_isin = "isin",
      holding_reported_mv = "holding_reported_mv"
    )

  logger::log_trace("Downloading fund data.")
  fund_data <- dplyr::collect(fund_data)

  # return the fund data -----------------------------------------------------

  return(fund_data)
}
