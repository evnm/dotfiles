UNAME := $(shell uname)

ifeq ($(UNAME), Darwin)
OS_BASH_EXCLUDE := .config/bash/linux.sh
else
OS_BASH_EXCLUDE := .config/bash/macos.sh
endif

help: ## Show this help message
	@perl -nle'print $& if m{^[a-zA-Z_-]+:.*?## .*$$}' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

install: install-symlinks claude-settings ## Install dotfiles in the current user's home directory

install-symlinks: ## Symlink tracked dotfiles into the current user's home directory
	@git ls-files -z -- ':!Makefile' ':!README.md' ':!LICENSE' ':!$(OS_BASH_EXCLUDE)' \
		':!scripts' ':!.claude/settings.base.json' \
	| while IFS= read -r -d '' file; do \
		src="$(CURDIR)/$$file"; \
		dest="$(HOME)/$$file"; \
		mkdir -p "$$(dirname "$$dest")"; \
		ln -sf "$$src" "$$dest"; \
		echo "  $$dest -> $$src"; \
	done

# ~/.claude/settings.json isn't symlinked, because Claude Code writes its own
# state into it. Instead the keys in .claude/settings.base.json are merged
# in, and the merge stops if any of those keys were changed locally.
claude-settings: ## Merge .claude/settings.base.json into ~/.claude/settings.json (FORCE=1 to overwrite local changes)
	@scripts/claude-settings.sh $(if $(FORCE),force,apply)

claude-settings-pull: ## Copy local changes to tracked Claude settings back into .claude/settings.base.json
	@scripts/claude-settings.sh pull

.PHONY: help install install-symlinks claude-settings claude-settings-pull
