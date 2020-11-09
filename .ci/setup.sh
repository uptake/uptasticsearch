# failure is a natural part of life
set -e

# If language: r,
# install these testing packages we need
if [[ "$TASK" == "rpkg" ]];
then

    # `devscripts` is required for 'checkbashisms' (https://github.com/r-lib/actions/issues/111)
    if [[ $OS_NAME == "linux" ]]; then
        sudo apt-get update
        sudo apt-get install \
            --no-install-recommends \
            -y \
            --allow-downgrades \
                libcurl4-openssl-dev \
                curl \
                devscripts \
                || exit -1
    fi

    Rscript -e "install.packages(c('assertthat', 'covr', 'data.table', 'futile.logger', 'httr', 'jsonlite', 'knitr', 'lintr', 'purrr', 'rmarkdown', 'stringr', 'testthat', 'uuid'), repos = 'https://cran.r-project.org')"
    cp test-data/* r-pkg/inst/testdata/
fi
