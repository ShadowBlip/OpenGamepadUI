
GODOT ?= $(HOME)/Projects/godot-engine/Godot_v4.0-beta6_linux.x86_64
GAMESCOPE ?= $(HOME)/Projects/gamescope/build/gamescope

ALL_GDSCRIPT := $(shell find ./ -name '*.gd')
ALL_SCENES := $(shell find ./ -name '*.tscn')

.PHONY: build
build: build/opengamepad-ui.x86_64
build/opengamepad-ui.x86_64: $(ALL_GDSCRIPT) $(ALL_SCENES)
	mkdir -p build
	$(GODOT) --headless --export-debug "Linux/X11"

.PHONY: plugins
plugins: build/plugins.zip
build/plugins.zip: $(ALL_GDSCRIPT) $(ALL_SCENES)
	mkdir -p build
	$(GODOT) --headless --export-pack "Linux/X11 (Plugins)" $@

.PHONY: clean
clean:
	rm -rf build

.PHONY: run
run: build/opengamepad-ui.x86_64
	$(GAMESCOPE) --xwayland-count 2 -- ./build/opengamepad-ui.x86_64
