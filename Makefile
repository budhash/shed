# Shed - Collection of useful development tools
# Makefile for common tasks

.PHONY: test help clean lint update-templates

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

## Update all tool templates using zap-sh
update-templates:
	@echo "Updating templates for all tools..."
	@echo "Updating framework files..."
	@curl -sL https://raw.githubusercontent.com/budhash/zap-sh/main/zap-sh | \
		bash -s -- update -y -f .template/tool-template || { \
			echo "Failed to update .template/tool-template"; \
			exit 1; \
		}
	@echo "Updating tools from tools.txt..."
	@grep -v '^#' tools.txt | grep -v '^[[:space:]]*$$' | cut -d: -f1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$$//' | \
	while read -r tool; do \
		if [ -f "$$tool/$$tool" ]; then \
			echo "Updating $$tool/$$tool"; \
			curl -sL https://raw.githubusercontent.com/budhash/zap-sh/main/zap-sh | \
				bash -s -- update -y -f "$$tool/$$tool" || { \
					echo "Failed to update $$tool/$$tool"; \
					exit 1; \
				}; \
		else \
			echo "Skipping $$tool/$$tool (file not found)"; \
		fi; \
	done
	@echo "Template updates completed"

## Clean up temporary files and artifacts
clean:
	@echo "Cleaning up..."
	@find . -name "*.tmp" -type f -delete
	@find . -name ".DS_Store" -type f -delete
	@echo "Cleanup completed"