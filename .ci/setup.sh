
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
  Rscript -e "install.packages(c('data.table', 'devtools', 'futile.logger', 'knitr', 'testthat', 'rmarkdown', 'uuid', 'lintr'), repos = 'http://cran.rstudio.com')"
  cp test-data/* r-pkg/inst/testdata/
fi

# If language: python,
# install these testing packages we need
if [[ "$TASK" == "pypkg" ]];
then
  export JAVA_APT_PKG="oracle-java9-set-default"
fi

# Install java
sudo -E \
  apt-get \
      -yq \
      --no-install-suggests \
      --no-install-recommends \
      install \
          ${JAVA_APT_PKG}
