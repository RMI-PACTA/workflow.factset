#' Get the entity info data from the FactSet database and prepare the
#' `factset_entity_info` tibble
#'
#' @param conn database connection
#'
#' @return A tibble properly prepared to be saved as the
#'   `factset_entity_info.rds` output file
#'
#' @export

get_entity_ids <- function(conn, colname = "factset_entity_id") {

  logger::log_debug("Extracting all values of ", colname, " from database")

  logger::log_trace("Identifying tables with column: ", colname, ".")
  table_has_entity_id_col <- vapply(
    X = DBI::dbListTables(conn),
    FUN = function(x) {
      any(DBI::dbListFields(conn, x) == colname)
    },
    FUN.VALUE = logical(1L),
    USE.NAMES = TRUE
  )
  tables_to_extract <- names(table_has_entity_id_col)[table_has_entity_id_col]
  logger::log_trace("Tables with column: ", colname, ": ",
    paste(tables_to_extract, collapse = ", ")
  )

  for (table_name in tables_to_extract) {
    logger::log_trace(
      "Adding values of ", colname,
      " from table: ", table_name,
      " to results."
    )
    this_result <- dplyr::select(
      .data = dplyr::tbl(conn, table_name),
      dplyr::all_of(colname)
    )
    if (table_name == tables_to_extract[[1L]]) {
      results <- this_result
    } else {
      results <- dplyr::union(results, this_result)
    }
  }

  logger::log_debug("Removing duplicates from results and downloading.")
  local_results <- dplyr::collect(
    dplyr::distinct(
      results
    )
  )

  return(local_results)
}
