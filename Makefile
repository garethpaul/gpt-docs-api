.PHONY: build check compile lint test verify

lint: check

test:
	PYTHONPATH=api python -m unittest discover -s api/tests

build: compile

compile:
	python -m compileall -q api/app.py api/chalicelib api/tests

check:
	scripts/check-baseline.sh

verify: test compile check
