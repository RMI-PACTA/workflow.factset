test_that("Companies in override mapping are unique", {
  testthat::expect_identical(
    pacta_override_mapping[["entity_proper_name"]],
    unique(pacta_override_mapping[["entity_proper_name"]])
  )
})

test_that("Sectors in override mapping are valid", {
  testthat::expect_in(
    pacta_override_mapping[["pacta_sector"]],
    c(
      "Aviation",
      "Coal",
      "Cement",
      "Oil&Gas",
      "Other",
      "Power",
      "Shipping",
      "Steel"
    )
  )
})
