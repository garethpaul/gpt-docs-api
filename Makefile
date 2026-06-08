.PHONY: test compile check verify

test:
	PYTHONPATH=api python -m unittest discover -s api/tests

compile:
	python -m compileall -q api/app.py api/chalicelib api/tests

check:
	scripts/check-baseline.sh

verify: test compile check
