.PHONY: build check compile lint mutations package-check test verify

override empty :=
override space := $(empty) $(empty)
override makefile_space := __GPT_DOCS_API_MAKEFILE_SPACE__
override encoded_makefile_list := $(patsubst $(makefile_space)%,%,$(subst $(space),$(makefile_space),$(MAKEFILE_LIST)))
override ROOT := $(subst $(makefile_space),$(space),$(abspath $(dir $(lastword $(encoded_makefile_list)))))

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
