#' Get the isin_to_fund_table data from the FactSet database and prepare the
#' `factset_isin_to_fund_table` tibble
#'
#' @param ... Arguments to be passed to the `connect_factset_db()` function (for
#'   specifying database connection parameters)
#'
#' @return A tibble properly prepared to be saved as the
#'   `factset_isin_to_fund_table.rds` output file
#'
#' @export

get_factset_isin_to_fund_table <-
  function(...) {
    # connect to the FactSet database ------------------------------------------
    factset_db <- connect_factset_db(...)


    # get the ISIN to fsym_id table --------------------------------------------

    isin__fsym_id <-
      tbl(factset_db, "sym_v1_sym_isin") %>%
      select("isin", "fsym_id")


    # get the fsym_id to fund_id table -----------------------------------------

    fsym_id__factset_fund_id <-
      tbl(factset_db, "own_v5_own_ent_fund_identifiers") %>%
      dplyr::filter(.data$identifier_type == "FSYM_ID") %>%
      select(fsym_id = "fund_identifier", "factset_fund_id")


    # merge and collect the data, then disconnect ------------------------------

    isin__factset_fund_id <-
      fsym_id__factset_fund_id %>%
      inner_join(isin__fsym_id, by = "fsym_id") %>%
      select("isin", "fsym_id", "factset_fund_id") %>%
      dplyr::collect()

    DBI::dbDisconnect(factset_db)


    # return the ISIN to fund_id table -----------------------------------------

    isin__factset_fund_id
  }
