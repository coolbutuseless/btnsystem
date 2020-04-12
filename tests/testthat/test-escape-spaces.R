test_that("escape-spaces works", {

  orig <- c('hello-there_\ttest\nthing')
  expect_identical(orig, escape_spaces(orig))


  orig <- c('hello there')
  expect_equal(escape_spaces(orig), "hello\\ there")
})
