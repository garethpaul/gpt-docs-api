.PHONY: test compile verify

test:
	PYTHONPATH=api python -m unittest discover -s api/tests

compile:
	python -m compileall -q api/app.py api/chalicelib api/tests

verify: test compile
