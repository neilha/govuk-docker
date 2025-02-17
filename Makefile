GOVUK_ROOT_DIR   ?= $(HOME)/govuk
GOVUK_DOCKER_DIR ?= $(GOVUK_ROOT_DIR)/govuk-docker
GOVUK_DOCKER     ?= $(GOVUK_DOCKER_DIR)/exe/govuk-docker
SHELLCHECK       ?= shellcheck

# Best practice to ensure these targets always execute, even if a
# file like 'clone' exists in the current directory.
.PHONY: test

default:
	@echo "Run 'make APP-NAME' to set up an app and its dependencies."
	@echo
	@echo "For example:"
	@echo "    make content-publisher"

test:
	# Run the tests for the govuk-docker CLI
	bundle exec rspec

	# Test that the docker-compose config is valid. This will error if there are errors
	# in the YAML files, or incompatible features are used.
	$(GOVUK_DOCKER) config > /dev/null

	# Validate shell scripts
	$(SHELLCHECK) $(shell ls ${GOVUK_DOCKER_DIR}/bin/*.sh ${GOVUK_DOCKER_DIR}/exe/*)

bundle-%: clone-%
	$(GOVUK_DOCKER) build $*-lite
	$(GOVUK_DOCKER) run $*-lite rbenv install -s || ($(GOVUK_DOCKER) build --no-cache $*-lite; $(GOVUK_DOCKER) run $*-lite rbenv install -s)
	if [ -f "${GOVUK_ROOT_DIR}/$*/Gemfile.lock" ]; then $(GOVUK_DOCKER) run $*-lite sh -c 'gem install --conservative --no-document bundler -v $$(grep -A1 "BUNDLED WITH" Gemfile.lock | tail -1)'; fi
	$(GOVUK_DOCKER) run $*-lite bundle

clone-%:
	@if [ ! -d "${GOVUK_ROOT_DIR}/$*/.git" ]; then \
		echo "$*" && git clone "git@github.com:alphagov/$*.git" "${GOVUK_ROOT_DIR}/$*"; \
	fi

include $(shell ls ${GOVUK_DOCKER_DIR}/projects/*/Makefile)
