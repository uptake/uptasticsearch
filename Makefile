.PHONY: build_r coverage_r docs_r install_r test_r build_py docs_py install_py test_py gh_pages

#####
# R #
#####

build_r:
	cp test-data/* r-pkg/inst/testdata/
	cp NEWS.md r-pkg/
	cp README.md r-pkg/
	R CMD BUILD r-pkg/

coverage_r: build_r
	echo "Calculating test coverage..."
	Rscript -e "Sys.setenv(NOT_CRAN = 'true'); coverage <- covr::package_coverage('r-pkg/'); print(coverage); covr::report(coverage, './coverage.html')"
	echo "Done calculating coverage"
	open coverage.html

docs_r: build_r
	Rscript -e "roxygen2::roxygenize('r-pkg/')"
	Rscript -e "pkgdown::build_site('r-pkg/')"

install_r: build_r
	R CMD INSTALL r-pkg/

test_r: build_r
	R CMD CHECK --as-cran uptasticsearch_*.tar.gz

##########
# Python #
##########

build_py:
	cp LICENSE py-pkg/
	cp NEWS.md py-pkg/
	cp README.md py-pkg/

docs_py:
	# Create sphinx rst files for every package and subpackage
	cd py-pkg && \
	sphinx-apidoc -f -F -e -o docs uptasticsearch && \
	cd docs && \
	make html

install_py:
	pip install py-pkg/

test_py:
	pytest py-pkg/

###########
# General #
###########

gh_pages: docs_r
	cp -R r-pkg/docs/* docs/
