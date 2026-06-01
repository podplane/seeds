# Podplane <https://podplane.dev>
# Copyright The Podplane Authors
# SPDX-License-Identifier: Apache-2.0

SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

SNAPSHOTS := recommended.netsy minimal.netsy
JSON_FILES := $(shell find . -path './.git' -prune -o -path './dist' -prune -o -name '*.json' -type f -print 2>/dev/null | sort)
SHELL_FILES := $(shell find scripts -name '*.sh' -type f 2>/dev/null | sort)
VERSION ?= dev
COMPONENTS_VERSION ?= dev

.DEFAULT_GOAL := help

.PHONY: help setup fmt check validate manifests precommit ci clean

help: ## Show available targets
	@echo "Podplane Seeds"
	@echo ""
	@echo "Usage: make <target>"
	@awk 'BEGIN {FS = ":.*?## "} /^##@/ {printf "\n\033[1m%s\033[0m\n", substr($$0, 5)} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Verify required tools and install git hooks when available
	@command -v jq >/dev/null 2>&1 || { echo "jq is required but not installed"; exit 1; }
	@command -v shasum >/dev/null 2>&1 || { echo "shasum is required but not installed"; exit 1; }
	@if [ -n "$(SHELL_FILES)" ]; then \
		command -v shellcheck >/dev/null 2>&1 || { echo "shellcheck is required but not installed"; exit 1; }; \
	fi
	@if [ -d .git ]; then \
		mkdir -p .git/hooks; \
		printf '%s\n' '#!/usr/bin/env bash' 'set -eo pipefail' 'echo "Running pre-commit checks..."' 'make precommit' 'echo "Pre-commit checks passed."' > .git/hooks/pre-commit; \
		chmod +x .git/hooks/pre-commit; \
		echo "Installed .git/hooks/pre-commit"; \
	else \
		echo "Skipping git hook install (.git not found)."; \
	fi

fmt: ## Format committed JSON files
	@command -v jq >/dev/null 2>&1 || { echo "jq is required but not installed"; exit 1; }
	@for file in $(JSON_FILES); do \
		tmp="$$(mktemp)"; \
		jq . "$$file" > "$$tmp"; \
		mv "$$tmp" "$$file"; \
	done

check: ## Check JSON formatting and shell scripts
	@command -v jq >/dev/null 2>&1 || { echo "jq is required but not installed"; exit 1; }
	@for file in $(JSON_FILES); do \
		tmp="$$(mktemp)"; \
		jq . "$$file" > "$$tmp"; \
		if ! diff -u "$$file" "$$tmp"; then \
			rm -f "$$tmp"; \
			echo "$$file needs formatting (run 'make fmt')"; \
			exit 1; \
		fi; \
		rm -f "$$tmp"; \
	done
	@if [ -n "$(SHELL_FILES)" ]; then \
		command -v shellcheck >/dev/null 2>&1 || { echo "shellcheck is required but not installed"; exit 1; }; \
		shellcheck $(SHELL_FILES); \
	fi

validate: ## Validate expected snapshot files
	@scripts/validate.sh $(SNAPSHOTS)

manifests: ## Generate release seeds manifest under dist/release
	@test "$(VERSION)" != "dev" || { echo "VERSION is required, e.g. VERSION=1.2.3-1 make manifests"; exit 1; }
	@scripts/manifest.sh --version "$(VERSION)" $(if $(REPO),--repo "$(REPO)",)

precommit: ## Run local pre-commit checks
	@$(MAKE) check

ci: check validate ## Run CI checks

clean: ## Remove generated files
	rm -rf dist
