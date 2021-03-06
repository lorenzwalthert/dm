test_that("check_key() checks primary key properly?", {
  map(
    .x = data_check_key_src,
    ~ expect_dm_error(
      check_key(.x, c1, c2),
      class = "not_unique_key"
    )
  )

  map(
    .x = data_check_key_src,
    ~ expect_silent(
      check_key(.x, c1, c3)
    )
  )

  map(
    .x = data_check_key_src,
    ~ expect_silent(
      check_key(.x, c2, c3)
    )
  )

  test_tbl <- tibble(nn = 1:5, n = 6:10)
  expect_silent(
    check_key(test_tbl, !!!c("n1" = sym("n"), "n2" = sym("nn")))
  )

  expect_silent(
    check_key(test_tbl, !!!c(sym("n"), sym("nn")))
  )

  expect_silent(
    check_key(test_tbl, everything())
  )

  expect_dm_error(
    check_key(test_tbl),
    "not_unique_key"
  )

  # if {tidyselect} selects nothing
  expect_dm_error(
    check_key(data, starts_with("d")),
    "not_unique_key"
  )
})
