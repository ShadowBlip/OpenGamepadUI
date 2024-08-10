NUM_CPU := $(shell nproc)

# Variables to define all the extensions to build. If a new extension is added,
# they should be added to these lists.
ADDONS_PATH = ../addons
ALL_EXT_PATHS = ../addons/dbus ../addons/linuxthread ../addons/pty ../addons/unixsock ../addons/xlib
ALL_CPP_FILES = $(shell find ./godot-cpp -regex  '.*\(\.cpp\|\.h\|\.hpp\)$$') godot-cpp/SConstruct

ALL_SCONS_FILES = godot-cpp/SConstruct \
									godot-dbus/SConstruct \
									godot-linuxthread/SConstruct \
									godot-pty/SConstruct \
									godot-unix-socket/SConstruct \
									godot-xlib/SConstruct

ALL_DEBUG_EXT = $(ADDONS_PATH)/dbus/bin/libdbus.linux.template_debug.x86_64.so \
								$(ADDONS_PATH)/linuxthread/bin/liblinuxthread.linux.template_debug.x86_64.so \
								$(ADDONS_PATH)/pty/bin/libpty.linux.template_debug.x86_64.so \
								$(ADDONS_PATH)/unixsock/bin/libunixsock.linux.template_debug.x86_64.so \
								$(ADDONS_PATH)/xlib/bin/libxlib.linux.template_debug.x86_64.so

ALL_RELEASE_EXT = $(ADDONS_PATH)/dbus/bin/libdbus.linux.template_release.x86_64.so \
									$(ADDONS_PATH)/linuxthread/bin/liblinuxthread.linux.template_release.x86_64.so \
									$(ADDONS_PATH)/pty/bin/libpty.linux.template_release.x86_64.so \
									$(ADDONS_PATH)/unixsock/bin/libunixsock.linux.template_release.x86_64.so \
									$(ADDONS_PATH)/xlib/bin/libxlib.linux.template_release.x86_64.so

ALL_GDEXT_FILES = $(ADDONS_PATH)/dbus/dbus.gdextension \
									$(ADDONS_PATH)/linuxthread/linuxthread.gdextension \
									$(ADDONS_PATH)/pty/pty.gdextension \
									$(ADDONS_PATH)/unixsock/unixsock.gdextension \
									$(ADDONS_PATH)/xlib/xlib.gdextension

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
build: ## Build all GDExtensions
	$(MAKE) release debug

.PHONY: release
release: $(ALL_RELEASE_EXT)
$(ALL_RELEASE_EXT) &: $(ALL_GDEXT_FILES) $(ALL_CPP_FILES)
	scons platform=linux -j$(NUM_CPU) target=template_release

.PHONY: debug
debug: $(ALL_DEBUG_EXT)
$(ALL_DEBUG_EXT) &: $(ALL_GDEXT_FILES) $(ALL_CPP_FILES)
	scons platform=linux -j$(NUM_CPU) target=template_debug

$(ALL_GDEXT_FILES) &: $(ALL_SCONS_FILES)
	mkdir -p $(ALL_EXT_PATHS)
	cp ./godot-dbus/addons/dbus/dbus.gdextension $(ADDONS_PATH)/dbus
	cp ./godot-linuxthread/addons/linuxthread/linuxthread.gdextension $(ADDONS_PATH)/linuxthread
	cp ./godot-pty/addons/pty/pty.gdextension $(ADDONS_PATH)/pty
	cp ./godot-unix-socket/addons/unixsock/unixsock.gdextension $(ADDONS_PATH)/unixsock
	cp ./godot-xlib/addons/xlib/xlib.gdextension $(ADDONS_PATH)/xlib

.PHONY: clean
clean: ## Clean all build artifacts
	rm -rf $(ALL_EXT_PATHS)
	find ./ -type f -name '*.o' -delete
	find ./ -type f -name '*.a' -delete
	find ./ -type f -name '*.os' -delete
	find ./ -type f -name '*.so' -delete

godot-cpp/SConstruct:
	git submodule update --init godot-cpp

godot-dbus/SConstruct:
	git submodule update --init godot-dbus

godot-linuxthread/SConstruct:
	git submodule update --init godot-linuxthread

godot-pty/SConstruct:
	git submodule update --init godot-pty

godot-unix-socket/SConstruct:
	git submodule update --init godot-unix-socket

godot-xlib/SConstruct:
	git submodule update --init godot-xlib

##@ Updates

.PHONY: update-dbus
update-dbus: ## Update godot-dbus
	cd godot-dbus
	git fetch
	git rebase origin/main

.PHONY: update-linuxthread
update-linuxthread: ## Update godot-linuxthread
	cd godot-linuxthread
	git fetch
	git rebase origin/main

.PHONY: update-pty
update-pty: ## Update godot-pty
	cd godot-pty
	git fetch
	git rebase origin/main

.PHONY: update-unixsock
update-unixsock: ## Update godot-unixsock
	cd godot-unixsock
	git fetch
	git rebase origin/main

.PHONY: update-xlib
update-xlib: ## Update godot-xlib
	cd godot-xlib
	git fetch
	git rebase origin/main
