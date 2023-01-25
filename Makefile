
GODOT_VERSION ?= 4.0.beta14
GODOT ?= /usr/bin/godot4
GAMESCOPE ?= /usr/bin/gamescope

EXPORT_TEMPLATE := $(HOME)/.local/share/godot/export_templates/$(GODOT_VERSION)/linux_debug.x86_64
EXPORT_TEMPLATE_URL ?= https://downloads.tuxfamily.org/godotengine/4.0/beta14/Godot_v4.0-beta14_export_templates.tpz

ALL_GDSCRIPT := $(shell find ./ -name '*.gd')
ALL_SCENES := $(shell find ./ -name '*.tscn')

.PHONY: build
build: addons build/opengamepad-ui.x86_64
build/opengamepad-ui.x86_64: $(ALL_GDSCRIPT) $(ALL_SCENES) $(EXPORT_TEMPLATE)
	mkdir -p build
	$(GODOT) --headless --export-debug "Linux/X11"

.PHONY: plugins
plugins: addons build/plugins.zip
build/plugins.zip: $(ALL_GDSCRIPT) $(ALL_SCENES) $(EXPORT_TEMPLATE)
	mkdir -p build
	$(GODOT) --headless --export-pack "Linux/X11 (Plugins)" $@

.PHONY: import
import:
	@echo "Importing project assets. This will take some time..."
	timeout --foreground 60 $(GODOT) --headless --editor . || echo "Finished"

.PHONY: addons
addons:
	@echo "Building gdnative addons"
	cd ./addons/godot-xlib && make build

.PHONY: edit
edit:
	$(GODOT) --editor .

.PHONY: clean
clean:
	rm -rf build

.PHONY: run
run: addons build/opengamepad-ui.x86_64
	$(GAMESCOPE) -e --debug-hud \
		--debug-focus \
		--debug-layers \
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
debug: addons
	$(GAMESCOPE) -e --xwayland-count 2 -- $(GODOT) --path $(PWD) --remote-debug tcp://127.0.0.1:6007 --position 320,140 res://main.tscn
