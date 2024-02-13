#' Get the entity info data from the FactSet database and prepare the
#' `factset_entity_info` tibble
#'
#' @param conn database connection
#'
#' @return A tibble properly prepared to be saved as the
#'   `factset_entity_info.rds` output file
#'
#' @export

get_entity_info <-
  function(conn) {
    # build connection to database ---------------------------------------------

    logger::log_debug("Extracting entity info from database.")

    # company_name -------------------------------------------------------------

    logger::log_trace("Accessing entity proper names.")
    entity_proper_name <-
      dplyr::tbl(conn, "sym_v1_sym_entity") %>%
      dplyr::select("factset_entity_id", "entity_proper_name")


    # country_of_domicile ------------------------------------------------------

    logger::log_trace("Accessing entity country of domicile.")
    iso_country <-
      dplyr::tbl(conn, "sym_v1_sym_entity") %>%
      dplyr::select("factset_entity_id", "iso_country")


    # sector -------------------------------------------------------------------

    logger::log_trace("Accessing entity sector.")
    sector_code <-
      dplyr::tbl(conn, "sym_v1_sym_entity_sector") %>%
      dplyr::select("factset_entity_id", "sector_code")

    logger::log_trace("Accessing sector descriptions.")
    sector_code__sector_desc <-
      dplyr::tbl(conn, "ref_v2_factset_sector_map") %>%
      dplyr::select(.data$factset_sector_code, .data$factset_sector_desc)

    logger::log_trace("Merging sector codes and sector descriptions.")
    factset_sector_desc <-
      sector_code %>%
      dplyr::left_join(
        sector_code__sector_desc,
        by = c(sector_code = "factset_sector_code")
      ) %>%
      dplyr::select("factset_entity_id", "sector_code", "factset_sector_desc")


    # sub-sector/industry ------------------------------------------------------

    logger::log_trace("Accessing entity industry codes.")
    industry_code <-
      dplyr::tbl(conn, "sym_v1_sym_entity_sector") %>%
      dplyr::select("factset_entity_id", "industry_code")

    logger::log_trace("Accessing industry descriptions")
    industry_code__industry_desc <-
      dplyr::tbl(conn, "ref_v2_factset_industry_map") %>%
      dplyr::select("factset_industry_code", "factset_industry_desc")

    logger::log_trace("Merging industry codes and industry descriptions.")
    factset_industry_desc <-
      industry_code %>%
      dplyr::left_join(
        industry_code__industry_desc,
        by = c(industry_code = "factset_industry_code")
      ) %>%
      dplyr::select(
        "factset_entity_id",
        "industry_code",
        "factset_industry_desc"
      )


    # credit risk parent -------------------------------------------------------

    logger::log_trace("Accessing entity affiliates.")
    ent_v1_ent_entity_affiliates <- dplyr::tbl(
      conn,
      "ent_v1_ent_entity_affiliates"
    )

    logger::log_trace("Accessing affiliate type map.")
    ref_v2_affiliate_type_map <- dplyr::tbl(
      conn,
      "ref_v2_affiliate_type_map"
    )

    logger::log_trace("Determining last update time for entity affiliates.")
    affiliates_last_update <-
      dplyr::tbl(conn, "fds_fds_file_history") %>%
      dplyr::filter(.data$table_name == "ent_entity_affiliates") %>%
      dplyr::filter(
        .data$begin_time == max(.data$begin_time, na.rm = TRUE)
      ) %>%
      # pull also handles `collect`ing the data
      dplyr::pull("begin_time")

    logger::log_trace("Determining credit risk parent via entity affiliates.")
    credit_parent_id <-
      ent_v1_ent_entity_affiliates %>%
      dplyr::left_join(ref_v2_affiliate_type_map, by = "aff_type_code") %>%
      dplyr::filter(.data$aff_type_desc == "Credit Risk Parent") %>%
      dplyr::select(
        factset_entity_id = "factset_affiliated_entity_id",
        credit_parent_id = "factset_entity_id"
      ) %>%
      dplyr::mutate(
        ent_entity_affiliates_last_update = affiliates_last_update
      )


    # merge and collect --------------------------------------------------------

    logger::log_trace("Merging entity info.")
    entity_info <-
      entity_proper_name %>%
      dplyr::left_join(
        iso_country,
        by = "factset_entity_id"
      ) %>%
      dplyr::left_join(
        factset_sector_desc,
        by = "factset_entity_id"
      ) %>%
      dplyr::left_join(
        factset_industry_desc,
        by = "factset_entity_id"
      ) %>%
      dplyr::left_join(
        credit_parent_id,
        by = "factset_entity_id"
      )

    logger::log_trace("Downloading merged entity info from database.")
    entity_info <- dplyr::collect(entity_info)
    logger::log_trace("Download complete.")

    # return prepared data -----------------------------------------------------
    return(entity_info)
  }
