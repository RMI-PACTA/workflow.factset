#' Get the isin_to_fund_table data from the FactSet database and prepare the
#' `factset_isin_to_fund_table` tibble
#'
#' @param conn database connection
#'
#' @return A tibble properly prepared to be saved as the
#'   `factset_isin_to_fund_table.rds` output file
#'
#' @export

get_isin_to_fund_table <- function(conn) {
  # get the ISIN to fsym_id table --------------------------------------------

  logger::info("Getting ISIN to fsym_id mapping")
  isin <-
    dplyr::tbl(conn, "sym_v1_sym_isin") %>%
    dplyr::select("isin", "fsym_id")


  # get the fsym_id to fund_id table -----------------------------------------

  logger::info("Getting fsym_id to fund id mapping")
  fund_id <-
    dplyr::tbl(conn, "own_v5_own_ent_fund_identifiers") %>%
    dplyr::filter(.data$identifier_type == "FSYM_ID") %>%
    dplyr::select(fsym_id = "fund_identifier", "factset_fund_id")


  # merge and collect the data ------------------------------

  logger::info("Merging ISIN to fsym_id and fsym_id to fund_id")
  isin__factset_fund_id <-
    fund_id %>%
    dplyr::inner_join(isin, by = "fsym_id") %>%
    dplyr::select("isin", "fsym_id", "factset_fund_id") %>%
    dplyr::collect()

  # return the ISIN to fund_id table -----------------------------------------
  return(isin__factset_fund_id)
}
