
# failure is a natural part of life
set -e

# If language: r,
# install these testing packages we need
if [[ "$TASK" == "rpkg" ]];
then
  Rscript -e "install.packages(c('assertthat', 'covr', 'data.table', 'futile.logger', 'httr', 'jsonlite', 'knitr', 'lintr', 'purrr', 'rmarkdown', 'stringr', 'testthat', 'uuid'), repos = 'http://cran.rstudio.com')"
  cp test-data/* r-pkg/inst/testdata/
fi
