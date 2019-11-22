library(lintr)

args <- commandArgs(
  trailingOnly = TRUE
)
SOURCE_DIR <- args[[1L]]

excluded_files <- list.files(
  paste(SOURCE_DIR, "uptasticsearch.Rcheck", sep = "/"),
  pattern = rex::rex(".", one_of("Rr"), end),
  all.files = TRUE,
  recursive = TRUE,
  full.names = TRUE
)

LINTERS_TO_USE <- list(
  "assignment" = lintr::assignment_linter,
  "closed_curly" = lintr::closed_curly_linter,
  "equals_na" = lintr::equals_na_linter,
  "function_left" = lintr::function_left_parentheses_linter,
  "commas" = lintr::commas_linter,
  "concatenation" = lintr::unneeded_concatenation_linter,
  "implicit_integers" = lintr::implicit_integer_linter,
  "infix_spaces" = lintr::infix_spaces_linter,
  "long_lines" = lintr::line_length_linter(length = 120L),
  "tabs" = lintr::no_tab_linter,
  "open_curly" = lintr::open_curly_linter,
  "paren_brace_linter" = lintr::paren_brace_linter,
  "semicolon" = lintr::semicolon_terminator_linter,
  "seq" = lintr::seq_linter,
  "single_quotes" = lintr::single_quotes_linter,
  "spaces_inside" = lintr::spaces_inside_linter,
  "spaces_left_parens" = lintr::spaces_left_parentheses_linter,
  "todo_comments" = lintr::todo_comment_linter,
  "trailing_blank" = lintr::trailing_blank_lines_linter,
  "trailing_white" = lintr::trailing_whitespace_linter,
  "true_false" = lintr::T_and_F_symbol_linter
)

results <- lintr::lint_dir(
  path = SOURCE_DIR,
  linters = LINTERS_TO_USE,
  cache = FALSE,
  exclusions = excluded_files
)

results_df <- as.data.frame(results)

cat(sprintf(
  "Found %i linting errors in project\n",
  length(results)
))

issues_count <- length(results)
issues_found <- issues_count > 0L

if (issues_found) {
  print(addmargins(table(results_df[c("filename", "linter")])))
  cat("\n")

  print(results)
}

message(paste(issues_count, "issue(s) found.", sep = " "))
quit(save = "no", status = if (issues_found) 1L else 0L)
