#' Get the factset financial data from the FactSet database and prepare the
#' `factset_financial_data` tibble
#'
#' @param data_timestamp A single string specifying the desired date for the
#'   data in the form "2021-12-31"
#' @param ... Arguments to be passed to the `connect_factset_db()` function (for
#'   specifying database connection parameters)
#'
#' @return A tibble properly prepared to be saved as the
#'   `factset_financial_data.rds` output file
#'
#' @export

get_factset_financial_data <-
  function(data_timestamp, ...) {
    # build connection to database ---------------------------------------------

    factset_db <- connect_factset_db(...)


    # fsym_id__factset_entity_id -----------------------------------------------

    fsym_id__factset_entity_id <-
      tbl(factset_db, "own_v5_own_sec_entity") %>%
      select("fsym_id", "factset_entity_id")


    # isin ---------------------------------------------------------------------

    fsym_id__isin <- tbl(factset_db, "sym_v1_sym_isin")


    # adj_price ----------------------------------------------------------------

    fsym_id__adj_price <-
      tbl(factset_db, "own_v5_own_sec_prices") %>%
      dplyr::filter(.data$price_date == .env$data_timestamp) %>%
      select("fsym_id", "adj_price")


    # adj_shares_outstanding ---------------------------------------------------

    fsym_id__adj_shares_outstanding <-
      tbl(factset_db, "own_v5_own_sec_prices") %>%
      dplyr::filter(.data$price_date == .env$data_timestamp) %>%
      select("fsym_id", "adj_shares_outstanding")


    # issue_type ---------------------------------------------------------------

    fsym_id__issue_type <-
      tbl(factset_db, "own_v5_own_sec_coverage") %>%
      select("fsym_id", "issue_type")


    # one_adr_eq ---------------------------------------------------------------

    fsym_id__one_adr_eq <-
      tbl(factset_db, "own_v5_own_sec_adr_ord_ratio") %>%
      select("fsym_id" = "adr_fsym_id", "one_adr_eq")


    # merge and collect --------------------------------------------------------

    fin_data <-
      fsym_id__isin %>%
      left_join(fsym_id__factset_entity_id, by = "fsym_id") %>%
      left_join(fsym_id__adj_price, by = "fsym_id") %>%
      left_join(fsym_id__adj_shares_outstanding, by = "fsym_id") %>%
      left_join(fsym_id__issue_type, by = "fsym_id") %>%
      left_join(fsym_id__one_adr_eq, by = "fsym_id") %>%
      dplyr::collect()

    DBI::dbDisconnect(factset_db)


    # return prepared data -----------------------------------------------------

    fin_data
  }
