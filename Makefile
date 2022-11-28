
GODOT ?= /usr/bin/godot4
GAMESCOPE ?= /usr/bin/gamescope

ALL_GDSCRIPT := $(shell find ./ -name '*.gd')
ALL_SCENES := $(shell find ./ -name '*.tscn')

.PHONY: build
build: build/opengamepad-ui.x86_64
build/opengamepad-ui.x86_64: .godot $(ALL_GDSCRIPT) $(ALL_SCENES)
	mkdir -p build
	$(GODOT) --headless --export-debug "Linux/X11"

.PHONY: plugins
plugins: build/plugins.zip
build/plugins.zip: .godot $(ALL_GDSCRIPT) $(ALL_SCENES)
	mkdir -p build
	$(GODOT) --headless --export-pack "Linux/X11 (Plugins)" $@

.PHONY: import
import: .godot
.godot:
	@echo "Importing project assets. This will take some time..."
	timeout --foreground 60 $(GODOT) --headless --editor . || echo "Finished"

.PHONY: edit
edit:
	$(GODOT) --editor .

.PHONY: clean
clean:
	rm -rf build

.PHONY: run
run: build/opengamepad-ui.x86_64
	$(GAMESCOPE) --xwayland-count 2 -- ./build/opengamepad-ui.x86_64
