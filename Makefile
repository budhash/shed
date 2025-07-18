# Shed - Collection of useful development tools
# Makefile for common tasks

.PHONY: test help clean lint

# Default target
.DEFAULT_GOAL := help

## Run all tests across all tools
test:
	@echo "Running all tests..."
	@./.common/test-driver

## Show help message
help:
	@echo "Shed Makefile"
	@echo ""
	@echo "Available targets:"
	@awk '/^##/ { \
		help_text = substr($$0, 4); \
		getline; \
		if ($$1 ~ /:/) { \
			target = $$1; \
			gsub(/:/, "", target); \
			printf "  %-15s %s\n", target, help_text \
		} \
	}' $(MAKEFILE_LIST)

## Run linting on all shell scripts (requires shellcheck)
lint:
	@echo "Linting shell scripts..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		echo "Linting framework files..."; \
		shellcheck .common/test-driver .common/test-common .template/tool-template; \
		echo "Linting tools from tools.txt..."; \
		grep -v '^#' tools.txt | grep -v '^[[:space:]]*$$' | cut -d: -f1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$$//' | grep -v '.template' | \
		while read -r tool; do \
			echo "Linting $$tool/$$tool"; \
			shellcheck "$$tool/$$tool"; \
		done; \
		echo "Linting completed"; \
	else \
		echo "shellcheck not found. Install with: brew install shellcheck (macOS) or apt install shellcheck (Ubuntu)"; \
		exit 1; \
	fi

## Clean up temporary files and artifacts
clean:
	@echo "Cleaning up..."
	@find . -name "*.tmp" -type f -delete
	@find . -name ".DS_Store" -type f -delete
	@echo "Cleanup completed"