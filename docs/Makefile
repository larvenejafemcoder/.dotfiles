.PHONY: serve build spellcheck clean

# Configuration
DOCS_PORT ?= 8000
PYTHON ?= python3

# Serve docs locally using Python HTTP server
serve:
	@echo "Serving docs at http://localhost:$(DOCS_PORT)"
	@cd .. && $(PYTHON) -m http.server $(DOCS_PORT) --directory docs

# Build static site (requires mkdocs)
build:
	@if ! command -v mkdocs &>/dev/null; then \
		echo "Installing mkdocs..."; \
		pip install mkdocs mkdocs-material; \
	fi
	@cd .. && mkdocs build

# Spellcheck (requires aspell)
spellcheck:
	@for f in *.md; do \
		echo "=== $$f ==="; \
		aspell --lang=en_US --mode=markdown list < "$$f" | sort -u; \
	done

# Clean build artifacts
clean:
	@rm -rf ../site/
	@echo "Cleaned build artifacts"

# Check for broken internal links
check-links:
	@for f in *.md; do \
		grep -oP '\]\([^)]+\.md[^)]*\)' "$$f" | sed 's/](/\//' | tr -d ')' | while read link; do \
			target="$$(echo "$$link" | sed 's|.*/||')"; \
			if [ ! -f "$$target" ] && [ ! -f "../docs/$$target" ]; then \
				echo "BROKEN: $$f -> $$target"; \
			fi; \
		done; \
	done
	@echo "Link check complete"

# Count documentation statistics
stats:
	@echo "Documentation statistics:"
	@echo "  Files: $$(ls *.md | wc -l)"
	@echo "  Lines: $$(wc -l *.md | tail -1 | awk '{print $$1}')"
	@echo "  Words: $$(wc -w *.md | tail -1 | awk '{print $$1}')"
