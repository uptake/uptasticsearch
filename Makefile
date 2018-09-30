

.PHONY: r-pkg

docs_r:
	cp LICENSE r-pkg/
	cp NEWS.md r-pkg/
	cp README.md r-pkg/
	Rscript -e "devtools::document('r-pkg/')"
	Rscript -e "pkgdown::build_site('r-pkg/')"

install_r:
	cp LICENSE r-pkg/
	cp NEWS.md r-pkg/
	cp README.md r-pkg/
	R CMD INSTALL r-pkg/

coverage_r:
	echo "Calculating test coverage..."
	Rscript -e "Sys.setenv(NOT_CRAN = 'true'); coverage <- covr::package_coverage('r-pkg/'); print(coverage); covr::report(coverage, './coverage.html')"
	echo "Done calculating coverage"
	open coverage.html

test_r:
	Rscript -e "devtools::test('r-pkg')"

install_py:
	cp LICENSE py-pkg/
	cp NEWS.md py-pkg/
	cp README.md py-pkg/
	pip install py-pkg/
