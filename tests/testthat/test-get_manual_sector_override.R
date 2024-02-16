test_that("Test that override mapping maps filters to defined companies", {
  tempdb <- withr::local_file("tempdb.sqlite")
  conn <- DBI::dbConnect(RSQLite::SQLite(), tempdb)

  sym_entity <- tibble::tribble(
    ~factset_entity_id, ~entity_proper_name,
    "FOO001-E", "FooBar, Inc.",
    "BAR001-E", "BarFoo, Inc.",
    "FOO002-E", "TestTest",
    "BAR002-E", "Some Company"
  )
  DBI::dbWriteTable(conn, "sym_v1_sym_entity", sym_entity)

  mapping <- tibble::tribble(
    ~entity_proper_name, ~pacta_sector, ~entity_id_md5,
    "FooBar, Inc.", "Aviation", NA,
    "TestTest", "Coal", NA
  )

  results <- get_manual_sector_override(
    conn = conn,
    override_mapping = mapping
  )
  DBI::dbDisconnect(conn)

  testthat::expect_identical(
    dplyr::arrange(results, factset_entity_id),
    tibble::tribble(
      ~factset_entity_id, ~factset_company_name, ~pacta_sector_override,
      "FOO001-E", "FooBar, Inc.", "Aviation",
      "FOO002-E", "TestTest", "Coal"
    )
  )
})
