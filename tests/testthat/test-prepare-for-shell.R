

test_that("prepare_for_shell works", {

  if (!grepl("w64", sessionInfo()$platform)) {
    # Windows expects a different type of quoting.
    args <- c('hello', "hello there", "hello there.*")
    expect_equal(
      prepare_for_shell(args),
      c("'hello'", "'hello there'", "hello\\ there.*")
    )

  }
})
