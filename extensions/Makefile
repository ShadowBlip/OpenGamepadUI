PREFIX ?= addons
EXT_NAME := $(shell grep 'name =' core/Cargo.toml | head -n 1 | cut -d'"' -f2)
LIB_NAME := $(shell grep 'name =' core/Cargo.toml | head -n 1 | cut -d'"' -f2)
ALL_RS := $(shell find ./ -name '*.rs')
ADDON_PATH := ../addons/core
RELEASE_TARGET_LINUX := $(ADDON_PATH)/bin/lib$(EXT_NAME).linux.template_release.x86_64.so
DEBUG_TARGET_LINUX := $(ADDON_PATH)/bin/lib$(EXT_NAME).linux.template_debug.x86_64.so
RELEASE_TARGET_MAC_ARM := $(ADDON_PATH)/bin/lib$(EXT_NAME).macos.template_release.arm64.dylib
DEBUG_TARGET_MAC_ARM := $(ADDON_PATH)/bin/lib$(EXT_NAME).macos.template_debug.arm64.dylib
RELEASE_TARGET_MAC_X86 := $(ADDON_PATH)/bin/lib$(EXT_NAME).macos.template_release.x86_64.dylib
DEBUG_TARGET_MAC_X86 := $(ADDON_PATH)/bin/lib$(EXT_NAME).macos.template_debug.x86_64.dylib

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
build: $(RELEASE_TARGET_LINUX) $(DEBUG_TARGET_LINUX) ## Build release and debug binaries


.PHONY: build-mac
build-mac: $(RELEASE_TARGET_MAC_ARM) $(DEBUG_TARGET_MAC_ARM) $(RELEASE_TARGET_MAC_X86) $(DEBUG_TARGET_MAC_X86) ## Build macos binaries


.PHONY: clean
clean: ## Clean build artifacts
	rm -f $(RELEASE_TARGET_LINUX) $(DEBUG_TARGET_LINUX)
	rm -rf target


.PHONY: release
release: $(RELEASE_TARGET_LINUX) ## Build release binary
$(RELEASE_TARGET_LINUX): $(ALL_RS)
	cargo build --release
	mkdir -p $(@D)
	cp target/release/lib$(LIB_NAME).so $@


.PHONY: debug
debug: $(DEBUG_TARGET_LINUX) ## Build binary with debug symbols
$(DEBUG_TARGET_LINUX): $(ALL_RS)
	cargo build
	mkdir -p $(@D)
	cp target/debug/lib$(LIB_NAME).so $@


.PHONY: release-mac-arm
release-mac-arm: $(RELEASE_TARGET_MAC_ARM) ## Build macos arm release binary
$(RELEASE_TARGET_MAC_ARM): $(ALL_RS)
	cargo build --release --target=aarch64-apple-darwin
	mkdir -p $(@D)
	cp target/aarch64-apple-darwin/release/lib$(LIB_NAME).dylib $@


.PHONY: debug-mac-arm
debug-mac-arm: $(DEBUG_TARGET_MAC_ARM) ## Build macos arm binary with debug symbols
$(DEBUG_TARGET_MAC_ARM): $(ALL_RS)
	cargo build --target=aarch64-apple-darwin
	mkdir -p $(@D)
	cp target/aarch64-apple-darwin/debug/lib$(LIB_NAME).dylib $@


.PHONY: release-mac-x86
release-mac-x86: $(RELEASE_TARGET_MAC_X86) ## Build macos x86 release binary
$(RELEASE_TARGET_MAC_X86): $(ALL_RS)
	cargo build --release --target=x86_64-apple-darwin
	mkdir -p $(@D)
	cp target/x86_64-apple-darwin/release/lib$(LIB_NAME).dylib $@


.PHONY: debug-mac-x86
debug-mac-x86: $(DEBUG_TARGET_MAC_X86) ## Build macos x86 binary with debug symbols
$(DEBUG_TARGET_MAC_X86): $(ALL_RS)
	cargo build --target=x86_64-apple-darwin
	mkdir -p $(@D)
	cp target/x86_64-apple-darwin/debug/lib$(LIB_NAME).dylib $@
