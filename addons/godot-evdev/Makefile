
ALL_CPP := $(shell find ./ -name '*.cpp')
ALL_HEADERS := $(shell find ./src -name '*.h')
GODOT_CPP_VERSION := f2b97528c1369a6c40f3749817d00e4633afc43e

.PHONY: build
build: bin/libevdev.linux.template_debug.x86_64.so bin/libevdev.linux.template_release.x86_64.so

bin/libevdev.linux.template_debug.x86_64.so: ../godot-cpp $(ALL_HEADERS) $(ALL_CPP)
	scons -Q compiledb
	scons target=template_debug

bin/libevdev.linux.template_release.x86_64.so: ../godot-cpp $(ALL_HEADERS) $(ALL_CPP)
	scons -Q compiledb
	scons target=template_release

../godot-cpp:
	cd .. && git clone https://github.com/godotengine/godot-cpp.git && cd godot-cpp && git checkout $(GODOT_CPP_VERSION)
	touch ../godot-cpp/.gdignore

.PHONY: clean
clean:
	rm -rf bin
	rm -rf ../godot-cpp
