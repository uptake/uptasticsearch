.PHONY: build
build:
	cp test-data/* r-pkg/inst/testdata/
	cp NEWS.md r-pkg/
	cp README.md r-pkg/
	R CMD BUILD r-pkg/

.PHONY: coverage
coverage:
	echo "Calculating test coverage..."
	Rscript -e "Sys.setenv(NOT_CRAN = 'true'); coverage <- covr::package_coverage('r-pkg/'); print(coverage); covr::report(coverage, './coverage.html')"
	echo "Done calculating coverage"
	open coverage.html

.PHONY: docs
docs: build
	Rscript -e "roxygen2::roxygenize('r-pkg/')"
	Rscript -e "pkgdown::build_site('r-pkg/')"

.PHONY: install
install: build
	R CMD INSTALL r-pkg/

.PHONY: test
test: build
	R CMD CHECK --as-cran uptasticsearch_*.tar.gz
