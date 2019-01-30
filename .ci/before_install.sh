
# failure is a natural part of life
set -e

# If language: r,
# install these testing packages we need
if [ -z "$TRAVIS_R_VERSION" ];
then
  Rscript -e "install.packages(c('devtools', 'knitr', 'testthat', 'rmarkdown'), repos = 'http://cran.rstudio.com')"
fi
