
# failure is a natural part of life
set -e

# Every build needs Java to build and run Elasticsearch.
# As of this writing, the R + Ubuntu images only have Java8
# available to them
export JAVA_APT_PKG="oracle-java8-set-default"

# If language: r,
# install these testing packages we need
if [[ "$TASK" == "rpkg" ]];
then
  Rscript -e "install.packages(c('devtools', 'knitr', 'testthat', 'rmarkdown'), repos = 'http://cran.rstudio.com')"
  cp test_data/* r-pkg/inst/testdata/
fi

# If language: python,
# install these testing packages we need
if [[ "$TASK" == "pypkg" ]];
then
  Rscript -e "install.packages(c('devtools', 'knitr', 'testthat', 'rmarkdown'), repos = 'http://cran.rstudio.com')"
  cp test_data/* r-pkg/inst/testdata/
  export JAVA_APT_PKG="oracle-java9-set-default"
fi

# Install java
sudo -e \
apt-get \
    -yq \
    --no-install-suggests \
    --no-install-recommends \
    install \
        ${JAVA_APT_PKG}
