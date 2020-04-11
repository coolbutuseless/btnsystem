test_that("has_special_chars works", {

  expect_true (has_special_chars("$me"))
  expect_true (has_special_chars("hello & there.txt"))
  expect_true (has_special_chars("not ; me"))
  expect_true (has_special_chars("redirect > text.txt"))
  expect_true (has_special_chars("cannot | pipe"))
  # expect_true (has_special_chars())

  expect_false(has_special_chars("helo.jpg"))
  expect_false(has_special_chars("./abc.txt"))
  expect_false(has_special_chars("~/crap-one.txt"))
  expect_false(has_special_chars("~/this is/the file.jpg"))
  expect_false(has_special_chars("all*.jpg"))
  expect_false(has_special_chars("some[0-9].png"))
  expect_false(has_special_chars("C:\\hello_there.txt"))
  expect_false(has_special_chars("return\nok.txt"))
  expect_false(has_special_chars("tab\tok.txt"))
  # expect_false(has_special_chars())

})
