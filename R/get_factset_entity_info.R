#' Get the entity info data from the FactSet database and prepare the
#' `factset_entity_info` tibble
#'
#' @param ... Arguments to be passed to the `connect_factset_db()` function (for
#'   specifying database connection parameters)
#'
#' @return A tibble properly prepared to be saved as the
#'   `factset_entity_info.rds` output file
#'
#' @export

get_factset_entity_info <-
  function(...) {
    # build connection to database ---------------------------------------------

    factset_db <- connect_factset_db(...)

    logger::log_debug("Extracting entity info from database.")

    # company_name -------------------------------------------------------------

    logger::log_trace("Accessing entity proper names.")
    factset_entity_id__entity_proper_name <-
      dplyr::tbl(factset_db, "sym_v1_sym_entity") %>%
      dplyr::select("factset_entity_id", "entity_proper_name")


    # country_of_domicile ------------------------------------------------------

    logger::log_trace("Accessing entity country of domicile.")
    factset_entity_id__iso_country <-
      dplyr::tbl(factset_db, "sym_v1_sym_entity") %>%
      dplyr::select("factset_entity_id", "iso_country")


    # sector -------------------------------------------------------------------

    logger::log_trace("Accessing entity sector.")
    factset_entity_id__sector_code <-
      dplyr::tbl(factset_db, "sym_v1_sym_entity_sector") %>%
      dplyr::select("factset_entity_id", "sector_code")

    factset_sector_code__factset_sector_desc <-
      dplyr::tbl(factset_db, "ref_v2_factset_sector_map") %>%
      dplyr::select(.data$factset_sector_code, .data$factset_sector_desc)

    factset_entity_id__factset_sector_desc <-
      factset_entity_id__sector_code %>%
      dplyr::left_join(
        factset_sector_code__factset_sector_desc,
        by = c("sector_code" = "factset_sector_code")
      ) %>%
      dplyr::select("factset_entity_id", "sector_code", "factset_sector_desc")


    # sub-sector/industry ------------------------------------------------------

    logger::log_trace("Accessing entity industry/sector/subsector.")
    factset_entity_id__industry_code <-
      dplyr::tbl(factset_db, "sym_v1_sym_entity_sector") %>%
      dplyr::select("factset_entity_id", "industry_code")

    factset_industry_code_factset_industry_desc <-
      dplyr::tbl(factset_db, "ref_v2_factset_industry_map") %>%
      dplyr::select("factset_industry_code", "factset_industry_desc")

    factset_entity_id__factset_industry_desc <-
      factset_entity_id__industry_code %>%
      dplyr::left_join(
        factset_industry_code_factset_industry_desc,
        by = c("industry_code" = "factset_industry_code")
      ) %>%
      dplyr::select(
        "factset_entity_id",
        "industry_code",
        "factset_industry_desc"
      )


    # credit risk parent -------------------------------------------------------

    logger::log_trace("Accessing entity credit risk parent.")
    ent_v1_ent_entity_affiliates <- dplyr::tbl(
      factset_db,
      "ent_v1_ent_entity_affiliates"
    )
    ref_v2_affiliate_type_map <- dplyr::tbl(
      factset_db,
      "ref_v2_affiliate_type_map"
    )

    ent_entity_affiliates_last_update <-
      dplyr::tbl(factset_db, "fds_fds_file_history") %>%
      dplyr::filter(.data$table_name == "ent_entity_affiliates") %>%
      dplyr::filter(
        .data$begin_time == max(.data$begin_time, na.rm = TRUE)
      ) %>%
      dplyr::pull("begin_time")

    factset_entity_id__credit_parent_id <-
      ent_v1_ent_entity_affiliates %>%
      dplyr::left_join(ref_v2_affiliate_type_map, by = "aff_type_code") %>%
      dplyr::filter(.data$aff_type_desc == "Credit Risk Parent") %>%
      dplyr::select(
        factset_entity_id = "factset_affiliated_entity_id",
        credit_parent_id = "factset_entity_id"
      ) %>%
      dplyr::mutate(
        ent_entity_affiliates_last_update = .env$ent_entity_affiliates_last_update
      )


    # merge and collect --------------------------------------------------------

    logger::log_trace("Merging entity info.")
    entity_info <-
      factset_entity_id__entity_proper_name %>%
      dplyr::left_join(
        factset_entity_id__iso_country,
        by = "factset_entity_id"
      ) %>%
      dplyr::left_join(
        factset_entity_id__factset_sector_desc,
        by = "factset_entity_id"
      ) %>%
      dplyr::left_join(
        factset_entity_id__factset_industry_desc,
        by = "factset_entity_id"
      ) %>%
      dplyr::left_join(
        factset_entity_id__credit_parent_id,
        by = "factset_entity_id"
      )

    logger::log_trace("Downloading merged entity info from database.")
    entity_info <- dplyr::collect(entity_info)
    logger::log_trace("Download complete.")

    logger::log_trace("Disconnecting from database.")
    DBI::dbDisconnect(factset_db)


    # return prepared data -----------------------------------------------------
    return(entity_info)
  }
