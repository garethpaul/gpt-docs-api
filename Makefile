.PHONY: build check compile lint mutations package-check test verify

override ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

lint: check

test:
	@cd "$(ROOT)" && PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=api python -m unittest discover -s api/tests

build: compile

compile:
	@cd "$(ROOT)" && python "$(ROOT)/scripts/check-python-syntax.py" api/app.py api/chalicelib api/tests

mutations:
	@cd "$(ROOT)" && PYTHONDONTWRITEBYTECODE=1 python "$(ROOT)/scripts/test-extension-auth-mutations.py"

check:
	@"$(ROOT)/scripts/check-baseline.sh"

package-check:
	@"$(ROOT)/scripts/verify-chalice-package.sh"

verify: test compile check
