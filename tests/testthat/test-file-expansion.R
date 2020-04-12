test_that("has_file_expansion works", {

  expect_true(has_file_expansion("*"))
  expect_true(has_file_expansion("?"))
  expect_true(has_file_expansion("["))


  expect_false(has_file_expansion("hello"))
  expect_false(has_file_expansion("a.txt"))
  expect_false(has_file_expansion("~/thing.txt"))
  expect_false(has_file_expansion("../../crap"))
  expect_false(has_file_expansion("hello_this-is+jpg"))
})
