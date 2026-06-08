.PHONY: test compile check verify

PYTHON ?= python3

test:
	PYTHONPATH=api $(PYTHON) -m unittest discover -s api/tests

compile:
	$(PYTHON) -m compileall -q api/app.py api/chalicelib api/tests

check:
	scripts/check-baseline.sh

verify: test compile check
