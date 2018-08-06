help: ## Show this help message
	@perl -nle'print $& if m{^[a-zA-Z_-]+:.*?## .*$$}' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

install: ## Install dotfiles in the current user's home directory
	rsync --exclude ".git/" \
		--exclude ".DS_Store" \
		--exclude "Makefile" \
		--exclude "README.md" \
		--exclude "LICENSE" \
		-avh --no-perms . ~;

.PHONY: help install
