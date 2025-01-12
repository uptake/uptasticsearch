
library(lintr)

args <- commandArgs(
    trailingOnly = TRUE
)
SOURCE_DIR <- args[[1L]]

FILES_TO_LINT <- list.files(
    path = SOURCE_DIR
    , pattern = "\\.r$"
    , all.files = TRUE
    , ignore.case = TRUE
    , full.names = TRUE
    , recursive = TRUE
    , include.dirs = FALSE
)

# text to use for pipe operators from packages like 'magrittr'
pipe_text <- paste0(
    "For consistency and the sake of being explicit, this project's code "
    , "does not use the pipe operator."
)

# text to use for functions that should only be called interactively
interactive_text <- paste0(
    "Functions like '?', 'help', and 'install.packages()' should only be used "
    , "interactively, not in package code."
)

LINTERS_TO_USE <- list(
    # "absolute_path"          = lintr::absolute_path_linter()
    "assignment"           = lintr::assignment_linter()
    # , "closed_curly"         = lintr::closed_curly_linter()
    , "commas"               = lintr::commas_linter()
    , "equals_na"            = lintr::equals_na_linter()
    , "function_left"        = lintr::function_left_parentheses_linter()
    , "infix_spaces"         = lintr::infix_spaces_linter()
    , "no_tabs"              = lintr::no_tab_linter()
    # , "non_portable_path"    = lintr::nonportable_path_linter()
    # , "open_curly"           = lintr::open_curly_linter()
    , "semicolon"            = lintr::semicolon_terminator_linter()
    , "seq"                  = lintr::seq_linter()
    , "spaces_inside"        = lintr::spaces_inside_linter()
    , "spaces_left_parens"   = lintr::spaces_left_parentheses_linter()
    , "todo_comments"        = lintr::todo_comment_linter(c("todo", "fixme", "to-do"))
    , "trailing_blank"       = lintr::trailing_blank_lines_linter()
    , "trailing_white"       = lintr::trailing_whitespace_linter()
    , "true_false"           = lintr::T_and_F_symbol_linter()
    , "undesirable_function" = lintr::undesirable_function_linter(
        fun = c(
            "cbind" = paste0(
                "cbind is an unsafe way to build up a data frame. merge() or direct "
                , "column assignment is preferred."
            )
            , "help" = interactive_text
            , "ifelse" = "The use of ifelse() is dangerous because it will silently allow mixing types."
            , "install.packages" = interactive_text
            , "rbind" = "data.table::rbindlist() is faster and safer than rbind(), and is preferred in this project."
            , "require" = paste0(
                "library() is preferred to require() because it will raise an error immediately "
                , "if a package is missing."
            )
        )
    )
    , "undesirable_operator" = lintr::undesirable_operator_linter(
        op = c(
            "%>%" = pipe_text
            , "%.%" = pipe_text
            , "%..%" = pipe_text
            , "?" = interactive_text
            , "??" = interactive_text
        )
    )
    , "unneeded_concatenation" = lintr::unneeded_concatenation_linter()
)

cat(sprintf("Found %i R files to lint\n", length(FILES_TO_LINT)))

results <- NULL

for (r_file in FILES_TO_LINT) {

    this_result <- lintr::lint(
        filename = r_file
        , linters = LINTERS_TO_USE
        , cache = FALSE
    )

    print(
        sprintf(
            "Found %i linting errors in %s"
            , length(this_result)
            , r_file
        )
        , quote = FALSE
    )

    results <- c(results, this_result)

}

issues_found <- length(results)

if (issues_found > 0L) {
    print(results)
}

print("Done linting R code")

quit(save = "no", status = issues_found)
