.PHONY: build check compile lint mutations package-check test verify

ifneq ($(strip $(MAKEFILES)),)
$(error MAKEFILES must be empty; repository verification requires this Makefile to be loaded alone)
endif
ifneq ($(origin MAKEFILE_LIST),file)
$(error MAKEFILE_LIST must not be overridden)
endif
override ROOT := $(shell path='$(subst ','"'"',$(MAKEFILE_LIST))'; path=$$(printf '%s' "$$path" | /usr/bin/sed 's/^ //'); [ -f "$$path" ] || exit 1; directory=$$(/usr/bin/dirname -- "$$path"); CDPATH= cd -- "$$directory" && /bin/pwd -P)
ifeq ($(strip $(ROOT)),)
$(error repository Makefile path could not be resolved)
endif

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
