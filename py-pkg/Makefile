
install:
	# Install uptasticsearch Python package
	cd py-pkg && \
	python setup.py install && \
	cd ..
	
docs:
	# Create sphinx rst files for every package and subpackage
	cd py-pkg && \
	sphinx-apidoc -f -e -o docs uptasticsearch && \
	cd docs && \
	make html

integration-tests:
	test_success=0 ;\
	docker-compose build --no-cache ;\
	docker-compose run uptasticsearch bash -c "sleep 15; cd dummy_data; sh load_dummy_data.sh; cd ..; pytest" || test_success=1 ;\
	docker-compose down ;\
	exit $$test_success
