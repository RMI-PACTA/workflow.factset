#' Get the fund data from the FactSet database and prepare the
#' `factset_fund_data` tibble
#'
#' @param data_timestamp A single string specifying the desired date for the
#'   data in the form "2021-12-31"
#' @param ... Arguments to be passed to the `connect_factset_db()` function (for
#'   specifying database connection parameters)
#'
#' @return A tibble properly prepared to be saved as the `factset_fund_data.rds`
#'   output file
#'
#' @export

get_factset_fund_data <-
  function(data_timestamp, ...) {
    # connect to the FactSet database ------------------------------------------
    factset_db <- connect_factset_db(...)


    # get the fund holdings and the holdings' reported market value ------------

    factset_fund_id__holding_fsym_id <-
      tbl(factset_db, "own_v5_own_fund_detail") %>%
      dplyr::filter(.data$report_date == .env$data_timestamp) %>%
      select(
        factset_fund_id = "factset_fund_id",
        holding_fsym_id = "fsym_id",
        holding_reported_mv = "reported_mv"
      )


    # --------------------------------------------------------------------------

    factset_fund_id__generic_id <-
      tbl(factset_db, "own_v5_own_fund_generic") %>%
      dplyr::filter(.data$report_date == .env$data_timestamp) %>%
      select(
        factset_fund_id = "factset_fund_id",
        holding_fsym_id = "generic_id",
        holding_reported_mv = "reported_mv"
      )

    factset_fund_id__holding_fsym_id <-
      dplyr::union_all(
        factset_fund_id__holding_fsym_id,
        factset_fund_id__generic_id
      )


    # get the fund total reported market value ---------------------------------

    factset_fund_id__total_reported_mv <-
      tbl(factset_db, "own_v5_own_ent_fund_filing_hist") %>%
      dplyr::filter(.data$report_date == .env$data_timestamp) %>%
      select("factset_fund_id", "total_reported_mv")


    # symbology containing the ISIN to fsym_id link
    fsym_id__isin <-
      tbl(factset_db, "sym_v1_sym_isin")


    # merge and collect the data, then disconnect ------------------------------

    fund_data <-
      factset_fund_id__total_reported_mv %>%
      filter(.data$total_reported_mv != 0 | !is.na(.data$total_reported_mv)) %>%
      left_join(factset_fund_id__holding_fsym_id, by = "factset_fund_id") %>%
      left_join(fsym_id__isin, by = c(`holding_fsym_id` = "fsym_id")) %>%
      select(
        factset_fund_id = "factset_fund_id",
        fund_reported_mv = "total_reported_mv",
        holding_isin = "isin",
        holding_reported_mv = "holding_reported_mv"
      ) %>%
      dplyr::collect()

    DBI::dbDisconnect(factset_db)


    # return the fund data -----------------------------------------------------

    fund_data
  }
