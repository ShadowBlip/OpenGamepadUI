PREFIX ?= addons
EXT_NAME := $(shell grep 'name =' core/Cargo.toml | head -n 1 | cut -d'"' -f2)
LIB_NAME := $(shell grep 'name =' core/Cargo.toml | head -n 1 | cut -d'"' -f2 | sed 's/-/_/g')
ALL_RS := $(shell find ./ -name '*.rs')
ADDON_PATH := ../addons/core
RELEASE_TARGET := $(ADDON_PATH)/bin/lib$(EXT_NAME).linux.template_release.x86_64.so
DEBUG_TARGET := $(ADDON_PATH)/bin/lib$(EXT_NAME).linux.template_debug.x86_64.so

##@ General

# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk commands is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI control characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the awk command:
# http://linuxcommand.org/lc3_adv_awk.php

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)


.PHONY: build
build: $(RELEASE_TARGET) $(DEBUG_TARGET) ## Build release and debug binaries


.PHONY: clean
clean: ## Clean build artifacts
	rm -f $(RELEASE_TARGET) $(DEBUG_TARGET)
	rm -rf target


.PHONY: release
release: $(RELEASE_TARGET) ## Build release binary
$(RELEASE_TARGET): $(ALL_RS)
	cargo build --release
	mkdir -p $(@D)
	cp target/release/lib$(LIB_NAME).so $@


.PHONY: debug
debug: $(DEBUG_TARGET) ## Build binary with debug symbols
$(DEBUG_TARGET): $(ALL_RS)
	cargo build
	mkdir -p $(@D)
	cp target/debug/lib$(LIB_NAME).so $@
