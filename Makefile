
PREFIX ?= $(HOME)/.local
ROOTFS ?= .rootfs
GODOT_VERSION ?= 4.0
GODOT_RELEASE ?= rc2
GODOT_REVISION := $(GODOT_VERSION).$(GODOT_RELEASE)
GODOT ?= /usr/bin/godot4
GAMESCOPE ?= /usr/bin/gamescope

EXPORT_TEMPLATE := $(HOME)/.local/share/godot/export_templates/$(GODOT_REVISION)/linux_debug.x86_64
EXPORT_TEMPLATE_URL ?= https://downloads.tuxfamily.org/godotengine/$(GODOT_VERSION)/$(GODOT_RELEASE)/Godot_v$(GODOT_VERSION)-$(GODOT_RELEASE)_export_templates.tpz

ALL_GDSCRIPT := $(shell find ./ -name '*.gd')
ALL_SCENES := $(shell find ./ -name '*.tscn')

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

.PHONY: install 
install: rootfs ## Install OpenGamepadUI (default: ~/.local)
	cd $(ROOTFS) && make install PREFIX=$(PREFIX)

.PHONY: uninstall
uninstall: ## Uninstall OpenGamepadUI
	cd $(ROOTFS) && make uninstall PREFIX=$(PREFIX)

##@ Development

.PHONY: build
build: addons build/opengamepad-ui.x86_64 ## Build and export the project
build/opengamepad-ui.x86_64: $(ALL_GDSCRIPT) $(ALL_SCENES) $(EXPORT_TEMPLATE)
	mkdir -p build
	$(GODOT) --headless --export-debug "Linux/X11"

.PHONY: plugins
plugins: addons build/plugins.zip ## Build and export plugins
build/plugins.zip: $(ALL_GDSCRIPT) $(ALL_SCENES) $(EXPORT_TEMPLATE)
	mkdir -p build
	$(GODOT) --headless --export-pack "Linux/X11 (Plugins)" $@

.PHONY: import
import: ## Import project assets
	@echo "Importing project assets. This will take some time..."
	timeout --foreground 60 $(GODOT) --headless --editor . || echo "Finished"

.PHONY: addons
addons: ## Build GDExtension add-ons
	@echo "Building gdnative addons"
	cd ./addons/godot-xlib && make build
	cd ./addons/godot-evdev && make build
	cd ./addons/godot-pty && make build

.PHONY: edit
edit: ## Open the project in the Godot editor
	$(GODOT) --editor .

.PHONY: clean
clean: ## Remove build artifacts
	rm -rf build
	rm -rf $(ROOTFS)
	rm -rf dist
	cd ./addons/godot-xlib && make clean
	cd ./addons/godot-evdev && make clean

.PHONY: run run-force
run: addons build/opengamepad-ui.x86_64 run-force ## Run the project in gamescope
run-force:
	$(GAMESCOPE) -w 1920 -h 1080 -f -e \
		--xwayland-count 2 -- ./build/opengamepad-ui.x86_64

$(EXPORT_TEMPLATE):
	mkdir -p $(HOME)/.local/share/godot/export_templates
	@echo "Downloading export templates"
	wget $(EXPORT_TEMPLATE_URL) -O $(HOME)/.local/share/godot/export_templates/templates.zip
	@echo "Extracting export templates"
	unzip $(HOME)/.local/share/godot/export_templates/templates.zip -d $(HOME)/.local/share/godot/export_templates/
	rm $(HOME)/.local/share/godot/export_templates/templates.zip
	mv $(HOME)/.local/share/godot/export_templates/templates $(@D)

.PHONY: debug 
debug: addons ## Run the project in debug mode in gamescope
	$(GAMESCOPE) -e --xwayland-count 2 -- \
		$(GODOT) --path $(PWD) --remote-debug tcp://127.0.0.1:6007 \
		--position 320,140 res://entrypoint.tscn

.PHONY: inspect
inspect: addons ## Launch Gamescope inspector
	$(GODOT) --path $(PWD) res://core/ui/menu/debug/gamescope_inspector.tscn


##@ Distribution

.PHONY: rootfs
rootfs: ## Build the archive structure
	rm -rf $(ROOTFS)
	mkdir -p $(ROOTFS)
	cp -r rootfs/* $(ROOTFS)
	mkdir -p $(ROOTFS)/usr/share/opengamepadui
	cp -r build/*.so $(ROOTFS)/usr/share/opengamepadui
	cp -r build/opengamepad-ui.x86_64 $(ROOTFS)/usr/share/opengamepadui
	touch $(ROOTFS)/.gdignore


.PHONY: dist 
dist: dist/opengamepadui.tar.gz ## Create an archive distribution of the project
dist/opengamepadui.tar.gz: build rootfs
	mv $(ROOTFS) opengamepadui
	tar cvfz opengamepadui.tar.gz opengamepadui
	mkdir -p dist
	mv opengamepadui.tar.gz dist
	mv opengamepadui $(ROOTFS)
