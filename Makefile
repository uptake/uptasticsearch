.PHONY: build
build:
	cp test-data/* r-pkg/inst/testdata/
	R CMD BUILD r-pkg/

.PHONY: coverage
coverage:
	echo "Calculating test coverage..."
	Rscript -e "Sys.setenv(NOT_CRAN = 'true'); coverage <- covr::package_coverage('r-pkg/'); print(coverage); covr::report(coverage, './coverage.html')"
	echo "Done calculating coverage"
	open coverage.html

.PHONY: install
install: build
	R CMD INSTALL r-pkg/

.PHONY: test
test: build
	R CMD CHECK --as-cran uptasticsearch_*.tar.gz
