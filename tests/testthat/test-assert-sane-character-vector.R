test_that("assert_sane_character_vector works", {

  expect_error(assert_sane_character_vector(list()))
  expect_error(assert_sane_character_vector(1))
  expect_error(assert_sane_character_vector(1:3))
  expect_error(assert_sane_character_vector(list('a', 'b')))

  expect_true(assert_sane_character_vector(c()))
  expect_true(assert_sane_character_vector('a'))
  expect_true(assert_sane_character_vector(letters))
  expect_true(assert_sane_character_vector(as.character(1:10)))
})
