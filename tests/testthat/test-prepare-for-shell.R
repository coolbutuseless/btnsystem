

test_that("prepare_for_shell works", {
  args <- c('hello', "hello there", "hello there.*")
  expect_equal(
    prepare_for_shell(args),
    c("'hello'", "'hello there'", "hello\\ there.*")
  )
})
