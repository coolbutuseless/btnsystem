test_that("has_spaces works", {

  expect_true(has_spaces("this one "))
  expect_true(has_spaces("one "))
  expect_true(has_spaces(" one.txt"))

  expect_false(has_spaces("hello"))
  expect_false(has_spaces("hello\ncrap"))
  expect_false(has_spaces("hello\tcrap"))
  expect_false(has_spaces("../hello"))
  expect_false(has_spaces("~/hello"))
})
