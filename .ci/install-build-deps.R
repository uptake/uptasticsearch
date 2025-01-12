install.packages(  # nolint: undesirable_function
    pkgs = c(
        "assertthat"
        , "data.table"
        , "futile.logger"
        , "httr"
        , "knitr"
        , "purrr"
        , "rmarkdown"
        , "stringr"
        , "uuid"
    )
    , repos = "https://cran.r-project.org"
    , Ncpus = 2
)
