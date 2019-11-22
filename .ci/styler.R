args <- commandArgs(
  trailingOnly = TRUE
)
SOURCE_DIR <- args[[1L]]

excluded_files <- withr::with_dir(SOURCE_DIR
                                  , dir(path = "./uptasticsearch.Rcheck"
                                        , rex::rex(".", one_of("Rr"), end)
                                        , ignore.case = TRUE
                                        , recursive = TRUE
                                        , full.names = TRUE
                                        , all.files = TRUE))

guide <- styler::tidyverse_style()

fix_implicit_integer <- function(pd_flat) {
  op <- pd_flat$token %in% "NUM_CONST"
  pd_flat$text[op] <- lapply(
    pd_flat$text[op],
    function(x) {
      gsub("^(\\d+)$", "\\1L", x)
    }
  )
  pd_flat
}

fix_trailing_whitespace_in_comment <- function(pd_flat) {
  comments <- pd_flat$token == "COMMENT"
  pd_flat$text[comments] <- lapply(
    pd_flat$text[comments],
    function(x) sub("\\s+$", "", x)
  )
  pd_flat
}

fix_space_between_paren_and_brace <- function(pd_flat) {
  brace_after <- pd_flat$token == "')'" & pd_flat$token_after == "'{'"
  if (!any(brace_after)) {
    return(pd_flat)
  }
  pd_flat$spaces[brace_after] <- pmax(pd_flat$spaces[brace_after], 1L)
  pd_flat
}

uptasticsearch_guide <- function() {
  styler::create_style_guide(
    token = list(
      fix_quotes = guide$token$fix_quotes,
      fix_implicit_integer = fix_implicit_integer,
      fix_trailing_whitespace_in_comment = fix_trailing_whitespace_in_comment
    ),
    space = list(
      style_space_around_math_token = guide$space$style_space_around_math_token,
      fix_space_between_paren_and_brace = fix_space_between_paren_and_brace,
      style_space_around_tilde = guide$space$style_space_around_tilde,
      add_space_before_brace = styler:::add_space_before_brace,
      set_space_after_comma = styler:::set_space_after_comma,
      set_space_around_op = function(...) styler:::set_space_around_op(strict = FALSE, ...),
      add_space_after_for_if_while = guide$space$add_space_after_for_if_while
    ),
    use_raw_indention = TRUE
  )
}

styler::style_dir(SOURCE_DIR, style = uptasticsearch_guide, exclude_files = excluded_files)
