# failure is a natural part of life
set -e

# If language: r,
# install these testing packages we need
if [[ "$TASK" == "rpkg" ]];
then

    export R_LIBS=${HOME}/Rlib
    export R_LINUX_VERSION="4.0.3-1.1804.0"
    export R_APT_REPO="bionic-cran40/"

    # installing precompiled R for Ubuntu
    # https://cran.r-project.org/bin/linux/ubuntu/#installation
    # adding steps from https://stackoverflow.com/a/56378217/3986677 to get latest version
    #
    # `devscripts` is required for 'checkbashisms' (https://github.com/r-lib/actions/issues/111)
    if [[ $OS_NAME == "linux" ]]; then
        sudo apt-key adv \
            --keyserver keyserver.ubuntu.com \
            --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
        sudo add-apt-repository \
            "deb https://cloud.r-project.org/bin/linux/ubuntu ${R_APT_REPO}"
        sudo apt-get update
        sudo apt-get install \
            --no-install-recommends \
            -y \
            --allow-downgrades \
                devscripts \
                r-base-dev=${R_LINUX_VERSION} \
                texinfo \
                texlive-latex-recommended \
                texlive-fonts-recommended \
                texlive-fonts-extra \
                qpdf \
                || exit -1
    fi

  Rscript -e "install.packages(c('assertthat', 'covr', 'data.table', 'futile.logger', 'httr', 'jsonlite', 'knitr', 'lintr', 'purrr', 'rmarkdown', 'stringr', 'testthat', 'uuid'), repos = 'http://cran.rstudio.com')"
  cp test-data/* r-pkg/inst/testdata/
fi
