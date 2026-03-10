.PHONY: help test compile checkdoc ci clean

.DEFAULT_GOAL := help

# Package information
PACKAGE := gowin-cst-mode.el
VERSION := $(shell perl -ne 'if (/^;;\s*Version:\s*(\S+)/) {print $$1; last}' $(PACKAGE))

# Emacs command
EMACS ?= emacs
BATCH := $(EMACS) --batch

help:
	@echo "gowin-cst-mode v$(VERSION) - Makefile targets"
	@echo ""
	@echo "  make test          Run ERT unit tests"
	@echo "  make compile       Byte-compile the package"
	@echo "  make checkdoc      Check documentation strings"
	@echo "  make ci            Run all checks (compile + checkdoc + test)"
	@echo "  make clean         Remove generated files"

test:
	@if [ -f tests/gowin-cst-mode-tests.el ]; then \
		$(BATCH) -l ert -l $(PACKAGE) \
		         -l tests/gowin-cst-mode-tests.el \
		         -f ert-run-tests-batch-and-exit; \
	else \
		echo "No tests found."; \
	fi

compile:
	@$(BATCH) -f batch-byte-compile $(PACKAGE)

checkdoc:
	@$(BATCH) --eval "(checkdoc-file \"$(PACKAGE)\")"

ci: clean compile checkdoc test

clean:
	@rm -f *.elc
