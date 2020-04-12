

test_that("prepare_for_shell works", {
  args <- c('hello', "hello there", "hello there.*")

  expected_output    <- shQuote(args)
  expected_output[3] <- "hello\\ there.*"

  expect_equal(
    prepare_for_shell(args),
    expected_output
  )
})
