

test_that("run works", {

  res <- run('ls', echo = TRUE)
  expect_named(res, c('status', 'stdout', 'stderr', 'string'))
  expect_equal(res$status, 0)

  expect_error(run('ls', '/tmp/non-existant.jpg'), "No such file")

  res <- run('ls', '/tmp/non-existant.jpg', error_on_status = FALSE)
  expect_true(res$status != 0)
  expect_true(grepl("No such file", res$stderr))
})
