context("colwise mutate/summarise")

test_that("funs found in current environment", {
  f <- function(x) 1
  df <- data.frame(x = c(2:10, 1000))

  out <- summarise_all(df, funs(f, mean, median))
  expect_equal(out, data.frame(f = 1, mean = 105.4, median = 6.5))

  out <- summarise_all(df, list(f = f, mean = mean, median = median))
  expect_equal(out, data.frame(f = 1, mean = 105.4, median = 6.5))
  # TODO: expect_error(summarise_all(df, list(f, mean, median)))
})

test_that("can use character vectors", {
  df <- data.frame(x = 1:3)

  expect_equal(summarise_all(df, "mean"), summarise_all(df, funs(mean)))
  expect_equal(mutate_all(df, list(mean = "mean")), mutate_all(df, funs(mean = mean)))

  expect_equal(summarise_all(df, "mean"), summarise_all(df, list(mean)))
  expect_equal(mutate_all(df, list(mean = "mean")), mutate_all(df, list(mean = mean)))
})

test_that("can use bare functions", {
  df <- data.frame(x = 1:3)

  expect_equal(summarise_all(df, mean), summarise_all(df, funs(mean)))
  expect_equal(mutate_all(df, mean), mutate_all(df, funs(mean)))

  expect_equal(summarise_all(df, mean), summarise_all(df, list(mean)))
  expect_equal(mutate_all(df, mean), mutate_all(df, list(mean)))
})

test_that("default names are smallest unique set", {
  df <- data.frame(x = 1:3, y = 1:3)

  expect_named(summarise_at(df, vars(x:y), funs(mean)), c("x", "y"))
  expect_named(summarise_at(df, vars(x), funs(mean, sd)), c("mean", "sd"))
  expect_named(summarise_at(df, vars(x:y), funs(mean, sd)), c("x_mean", "y_mean", "x_sd", "y_sd"))
  expect_named(summarise_at(df, vars(x:y), funs(base::mean, stats::sd)), c("x_base::mean", "y_base::mean", "x_stats::sd", "y_stats::sd"))
  expect_named(summarise_at(df, vars(x = x), funs(mean, sd)), c("x_mean", "x_sd"))

  expect_named(summarise_at(df, vars(x:y), list(mean)), c("x", "y"))
  expect_named(summarise_at(df, vars(x), list(mean = mean, sd = sd)), c("mean", "sd"))
  expect_named(summarise_at(df, vars(x:y), list(mean = mean, sd = sd)), c("x_mean", "y_mean", "x_sd", "y_sd"))
})

test_that("named arguments force complete named", {
  df <- data.frame(x = 1:3, y = 1:3)
  expect_named(summarise_at(df, vars(x:y), funs(mean = mean)), c("x_mean", "y_mean"))
  expect_named(summarise_at(df, vars(x = x), funs(mean = mean, sd = sd)), c("x_mean", "x_sd"))

  expect_named(summarise_at(df, vars(x:y), list(mean = mean)), c("x_mean", "y_mean"))
  expect_named(summarise_at(df, vars(x = x), list(mean = mean, sd = sd)), c("x_mean", "x_sd"))
})

expect_classes <- function(tbl, expected) {
  classes <- unname(map_chr(tbl, class))
  classes <- paste0(substring(classes, 0, 1), collapse = "")
  expect_equal(classes, expected)
}

test_that("can select colwise", {
  columns <- iris %>% mutate_at(NULL, as.character)
  expect_classes(columns, "nnnnf")

  columns <- iris %>% mutate_at(vars(starts_with("Petal")), as.character)
  expect_classes(columns, "nnccf")

  numeric <- iris %>% mutate_at(c(1, 3), as.character)
  expect_classes(numeric, "cncnf")

  character <- iris %>% mutate_at("Species", as.character)
  expect_classes(character, "nnnnc")
})

test_that("can probe colwise", {
  predicate <- iris %>% mutate_if(is.factor, as.character)
  expect_classes(predicate, "nnnnc")

  logical <- iris %>% mutate_if(c(TRUE, FALSE, TRUE, TRUE, FALSE), as.character)
  expect_classes(logical, "cnccf")
})

test_that("non syntactic colnames work", {
  df <- data_frame(`x 1` = 1:3)
  expect_identical(summarise_at(df, "x 1", sum)[[1]], 6L)
  expect_identical(summarise_if(df, is.numeric, sum)[[1]], 6L)
  expect_identical(summarise_all(df, sum)[[1]], 6L)
  expect_identical(mutate_all(df, `*`, 2)[[1]], (1:3) * 2)
})

test_that("empty selection does not select everything (#2009, #1989)", {
  expect_equal(
    tibble::remove_rownames(mtcars),
    tibble::remove_rownames(mutate_if(mtcars, is.factor, as.character))
  )
})

test_that("error is thrown with improper additional arguments", {
  # error messages by base R, not checked
  expect_error(mutate_all(mtcars, round, 0, 0))
  expect_error(mutate_all(mtcars, mean, na.rm = TRUE, na.rm = TRUE))
})

test_that("predicate can be quoted", {
  expected <- mutate_if(mtcars, is_integerish, mean)
  expect_identical(mutate_if(mtcars, "is_integerish", mean), expected)
  expect_identical(mutate_if(mtcars, ~ is_integerish(.x), mean), expected)
})

test_that("transmute verbs do not retain original variables", {
  expect_named(transmute_all(data_frame(x = 1:3, y = 1:3), funs(mean, sd)), c("x_mean", "y_mean", "x_sd", "y_sd"))
  expect_named(transmute_if(data_frame(x = 1:3, y = 1:3), is_integer, funs(mean, sd)), c("x_mean", "y_mean", "x_sd", "y_sd"))
  expect_named(transmute_at(data_frame(x = 1:3, y = 1:3), vars(x:y), funs(mean, sd)), c("x_mean", "y_mean", "x_sd", "y_sd"))

  expect_named(transmute_all(data_frame(x = 1:3, y = 1:3), list(mean = mean, sd = sd)), c("x_mean", "y_mean", "x_sd", "y_sd"))
  expect_named(transmute_if(data_frame(x = 1:3, y = 1:3), is_integer, list(mean = mean, sd = sd)), c("x_mean", "y_mean", "x_sd", "y_sd"))
  expect_named(transmute_at(data_frame(x = 1:3, y = 1:3), vars(x:y), list(mean = mean, sd = sd)), c("x_mean", "y_mean", "x_sd", "y_sd"))
})

test_that("can rename with vars() (#2594)", {
  expect_equal(mutate_at(tibble(x = 1:3), vars(y = x), mean), tibble(x = 1:3, y = c(2, 2, 2)))
})

test_that("selection works with grouped data frames (#2624)", {
  gdf <- group_by(iris, Species)
  expect_identical(mutate_if(gdf, is.factor, as.character), gdf)
})

test_that("at selection works even if not all ops are named (#2634)", {
  df <- tibble(x = 1, y = 2)
  expect_identical(mutate_at(df, vars(z = x, y), funs(. + 1)), tibble(x = 1, y = 3, z = 2))
  expect_identical(mutate_at(df, vars(z = x, y), list(~. + 1)), tibble(x = 1, y = 3, z = 2))
})

test_that("can use a purrr-style lambda", {
  expect_identical(summarise_at(mtcars, vars(1:2), ~ mean(.x)), summarise(mtcars, mpg = mean(mpg), cyl = mean(cyl)))
})

test_that("mutate_at and transmute_at refuses to mutate a grouping variable (#3351, #3480)", {
  tbl <- data_frame(gr1 = rep(1:2, 4), gr2 = rep(1:2, each = 4), x = 1:8) %>%
    group_by(gr1)

  expect_error(
    mutate_at(tbl, vars(gr1), sqrt),
    "Column `gr1` can't be modified because it's a grouping variable",
    fixed = TRUE
  )

  expect_error(
    transmute_at(tbl, vars(gr1), sqrt),
    "Column `gr1` can't be modified because it's a grouping variable",
    fixed = TRUE
  )
})

test_that("mutate and transmute variants does not mutate grouping variable (#3351, #3480)", {
  tbl <- data_frame(gr1 = rep(1:2, 4), gr2 = rep(1:2, each = 4), x = 1:8) %>%
    group_by(gr1)
  res <- mutate(tbl, gr2 = sqrt(gr2), x = sqrt(x))

  expect_message(expect_identical(mutate_all(tbl, sqrt), res), "ignored")
  expect_message(expect_identical(transmute_all(tbl, sqrt), res), "ignored")

  expect_message(expect_identical(mutate_if(tbl, is.integer, sqrt), res), "ignored")
  expect_message(expect_identical(transmute_if(tbl, is.integer, sqrt), res), "ignored")

  expect_identical(transmute_at(tbl, vars(-group_cols()), sqrt), res)
  expect_identical(mutate_at(tbl, vars(-group_cols()), sqrt), res)
})

test_that("summarise_at refuses to treat grouping variables (#3351, #3480)", {
  tbl <- data_frame(gr1 = rep(1:2, 4), gr2 = rep(1:2, each = 4), x = 1:8) %>%
    group_by(gr1)

  expect_error(
    summarise_at(tbl, vars(gr1), mean)
  )
})

test_that("summarise variants does not summarise grouping variable (#3351, #3480)", {
  tbl <- data_frame(gr1 = rep(1:2, 4), gr2 = rep(1:2, each = 4), x = 1:8) %>%
    group_by(gr1)
  res <- summarise(tbl, gr2 = mean(gr2), x = mean(x))

  expect_identical(summarise_all(tbl, mean), res)
  expect_identical(summarise_if(tbl, is.integer, mean), res)
})

test_that("summarise_at removes grouping variables (#3613)", {
  d <- tibble( x = 1:2, y = 3:4, g = 1:2) %>% group_by(g)
  res <- d %>%
    group_by(g) %>%
    summarise_at(-1, mean)

  expect_equal(names(res), c("g", "y"))
})

# Deprecated ---------------------------------------------------------

test_that("_each() and _all() families agree", {
  scoped_lifecycle_silence()
  df <- data.frame(x = 1:3, y = 1:3)

  expect_equal(summarise_each(df, funs(mean)), summarise_all(df, mean))
  expect_equal(summarise_each(df, funs(mean), x), summarise_at(df, vars(x), mean))
  expect_equal(summarise_each(df, funs(mean = mean), x), summarise_at(df, vars(x), funs(mean = mean)))
  expect_equal(summarise_each(df, funs(mean = mean), x:y), summarise_at(df, vars(x:y), funs(mean = mean)))
  expect_equal(summarise_each(df, funs(mean), x:y), summarise_at(df, vars(x:y), mean))
  expect_equal(summarise_each(df, funs(mean), z = y), summarise_at(df, vars(z = y), mean))

  expect_equal(summarise_each(df, list(mean)), summarise_all(df, mean))
  expect_equal(summarise_each(df, list(mean), x), summarise_at(df, vars(x), mean))
  expect_equal(summarise_each(df, list(mean = mean), x), summarise_at(df, vars(x), list(mean = mean)))
  expect_equal(summarise_each(df, list(mean = mean), x:y), summarise_at(df, vars(x:y), list(mean = mean)))
  expect_equal(summarise_each(df, list(mean), x:y), summarise_at(df, vars(x:y), mean))
  expect_equal(summarise_each(df, list(mean), z = y), summarise_at(df, vars(z = y), mean))

  expect_equal(mutate_each(df, funs(mean)), mutate_all(df, mean))
  expect_equal(mutate_each(df, funs(mean), x), mutate_at(df, vars(x), mean))
  expect_equal(mutate_each(df, funs(mean = mean), x), mutate_at(df, vars(x), funs(mean = mean)))
  expect_equal(mutate_each(df, funs(mean = mean), x:y), mutate_at(df, vars(x:y), funs(mean = mean)))
  expect_equal(mutate_each(df, funs(mean), x:y), mutate_at(df, vars(x:y), mean))
  expect_equal(mutate_each(df, funs(mean), z = y), mutate_at(df, vars(z = y), mean))

  expect_equal(mutate_each(df, list(mean)), mutate_all(df, mean))
  expect_equal(mutate_each(df, list(mean), x), mutate_at(df, vars(x), mean))
  expect_equal(mutate_each(df, list(mean = mean), x), mutate_at(df, vars(x), list(mean = mean)))
  expect_equal(mutate_each(df, list(mean = mean), x:y), mutate_at(df, vars(x:y), list(mean = mean)))
  expect_equal(mutate_each(df, list(mean), x:y), mutate_at(df, vars(x:y), mean))
  expect_equal(mutate_each(df, list(mean), z = y), mutate_at(df, vars(z = y), mean))
})

test_that("group_by_(at,all) handle utf-8 names (#3829)", {
  skip_if(getRversion() <= "3.4.0")
  withr::with_locale( c(LC_CTYPE = "C"), {
    name <- "\u4e2d"
    tbl <- tibble(a = 1) %>%
      setNames(name)

    res <- group_by_all(tbl) %>% groups()
    expect_equal(res[[1]], sym(name))

    res <- group_by_at(tbl, name) %>% groups()
    expect_equal(res[[1]], sym(name))
  })
})

test_that("*_(all,at) handle utf-8 names (#2967)", {
  skip_if(getRversion() <= "3.4.0")
  withr::with_locale( c(LC_CTYPE = "C"), {
    name <- "\u4e2d"
    tbl <- tibble(a = 1) %>%
      setNames(name)

    res <- tbl %>%
      mutate_all(funs(as.character)) %>%
      names()
    expect_equal(res, name)

    res <- tbl %>%
      mutate_at(name, funs(as.character)) %>%
      names()
    expect_equal(res, name)

    res <- tbl %>%
      summarise_all(funs(as.character)) %>%
      names()
    expect_equal(res, name)

    res <- tbl %>%
      summarise_at(name, funs(as.character)) %>%
      names()
    expect_equal(res, name)

    res <- tbl %>%
      mutate_all(list(as.character)) %>%
      names()
    expect_equal(res, name)

    res <- tbl %>%
      mutate_at(name, list(as.character)) %>%
      names()
    expect_equal(res, name)

    res <- tbl %>%
      summarise_all(list(as.character)) %>%
      names()
    expect_equal(res, name)

    res <- tbl %>%
      summarise_at(name, list(as.character)) %>%
      names()
    expect_equal(res, name)

    res <- select_at(tbl, name) %>% names()
    expect_equal(res, name)
  })
})
