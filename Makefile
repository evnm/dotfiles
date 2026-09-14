UNAME := $(shell uname)

ifeq ($(UNAME), Darwin)
OS_BASH_EXCLUDE := .config/bash/linux.sh
else
OS_BASH_EXCLUDE := .config/bash/macos.sh
endif

help: ## Show this help message
	@perl -nle'print $& if m{^[a-zA-Z_-]+:.*?## .*$$}' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

install: ## Install dotfiles as symlinks in the current user's home directory
	@git ls-files -z -- ':!Makefile' ':!README.md' ':!LICENSE' ':!$(OS_BASH_EXCLUDE)' \
	| while IFS= read -r -d '' file; do \
		src="$(CURDIR)/$$file"; \
		dest="$(HOME)/$$file"; \
		mkdir -p "$$(dirname "$$dest")"; \
		ln -sf "$$src" "$$dest"; \
		echo "  $$dest -> $$src"; \
	done

.PHONY: help install
