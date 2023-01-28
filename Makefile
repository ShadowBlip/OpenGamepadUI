
GODOT_VERSION ?= 4.0.beta15
GODOT ?= /usr/bin/godot4
GAMESCOPE ?= /usr/bin/gamescope

EXPORT_TEMPLATE := $(HOME)/.local/share/godot/export_templates/$(GODOT_VERSION)/linux_debug.x86_64
EXPORT_TEMPLATE_URL ?= https://downloads.tuxfamily.org/godotengine/4.0/beta15/Godot_v4.0-beta15_export_templates.tpz

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

.PHONY: edit
edit: ## Open the project in the Godot editor
	$(GODOT) --editor .

.PHONY: clean
clean: ## Remove build artifacts
	rm -rf build
	cd ./addons/godot-xlib && make clean

.PHONY: run
run: addons build/opengamepad-ui.x86_64 ## Run the project in gamescope
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
		--position 320,140 res://main.tscn

.PHONY: inspect
inspect: addons ## Launch Gamescope inspector
	$(GODOT) --path $(PWD) res://core/ui/menu/debug/gamescope_inspector.tscn
