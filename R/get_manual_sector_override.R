#' Get the PACTA manual sector override table
#'
#' @param conn database connection
#' @param override_mapping `data.frame`-ish object with same format as
#' `pacta_sector_override_mapping`
#'
#' @return A tibble properly prepared to be saved as the
#'   `factset_manual_pacta_sector_override.rds` output file
#'
#' @export

get_manual_sector_override <- function(
  conn,
  override_mapping = pacta_sector_override_mapping
) {
  # build connection to database ---------------------------------------------

  logger::log_debug("Extracting manual PACTA sector override table.")


  # factset_entity_id -----------------------------------------------
  logger::log_trace("Accessing entity information.")
  sym_entity <- dplyr::tbl(conn, "sym_v1_sym_entity")

  logger::log_trace("Preparing company names.")
  company_names <- override_mapping[["entity_proper_name"]]

  factset_entity_info <- sym_entity %>%
    dplyr::select(
      dplyr::all_of(
        c(
          "factset_entity_id",
          "entity_proper_name"
        )
      )
    ) %>%
    dplyr::filter(.data[["entity_proper_name"]] %in% company_names)

  # merge and collect --------------------------------------------------------

  logger::log_trace("Downloading entity information for override companies.")
  factset_entity_info <- dplyr::collect(factset_entity_info)
  logger::log_trace("Download complete.")

  logger::log_trace("Adding PACTA sector overrides.")
  pacta_sector_override <- dplyr::full_join(
    x = factset_entity_info,
    y = override_mapping,
    by = dplyr::join_by("entity_proper_name"),
    multiple = "all"
  ) %>%
    dplyr::mutate(
      fs_entity_id_md5 = vapply(
        X = .data[["factset_entity_id"]],
        FUN = digest::digest,
        FUN.VALUE = character(1L),
        algo = "md5",
        serialize = FALSE
      )
    ) %>%
    dplyr::mutate(
      keep_row = is.na(.data[["entity_id_md5"]]) |
        (.data[["fs_entity_id_md5"]] == .data[["entity_id_md5"]])
    ) %>%
    dplyr::filter(.data[["keep_row"]]) %>%
    dplyr::select(
      factset_entity_id = "factset_entity_id",
      factset_company_name = "entity_proper_name",
      pacta_sector_override = "pacta_sector"
    )

  incomplete_cases <- dplyr::filter(
    pacta_sector_override,
    is.na(.data[["factset_entity_id"]])
  )

  if (nrow(incomplete_cases) > 0L) {
    # converting to formatter sprintf to deal with strings that break {glue}
    old_formatter <- logger::log_formatter()
    logger::log_formatter(logger::formatter_sprintf)
    logger::log_warn(
      "Company could not be matched by name in FactSet database: %s",
      incomplete_cases[["factset_company_name"]]
    )
    logger::log_formatter(old_formatter)
  }

  multiple_matches <- pacta_sector_override %>%
    dplyr::group_by(.data[["factset_company_name"]]) %>%
    dplyr::filter(dplyr::n() > 1L)

  if (nrow(multiple_matches) > 0L) {
    # converting to formatter sprintf to deal with strings that break {glue}
    old_formatter <- logger::log_formatter()
    logger::log_formatter(logger::formatter_sprintf)
    for (i in seq(1L, nrow(multiple_matches), 1L)) {
      logger::log_warn(
        "Company matched to multiple entity IDs in FactSet database: %s: %s",
        multiple_matches[i, "factset_entity_id"],
        multiple_matches[i, "factset_company_name"]
      )
    }
    logger::log_formatter(old_formatter)
  }

  # return prepared data -----------------------------------------------------
  return(pacta_sector_override)
}
