#/bin/bash

set -e

# Get test coverage HTML
echo "Calculating test coverage..."
Rscript -e "Sys.setenv(NOT_CRAN = 'true'); coverage <- covr::package_coverage(); print(coverage); covr::report(coverage, './coverage.html')"
echo "Done calculating coverage"
open coverage.html
