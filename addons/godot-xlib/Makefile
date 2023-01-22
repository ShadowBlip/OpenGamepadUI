
ALL_CPP := $(shell find ./ -name '*.cpp')
ALL_HEADERS := $(shell find ./src -name '*.h')
GODOT_CPP_VERSION := 19091138895d35e1ce69742889b8bfd82be57f17

.PHONY: build
build: bin/libxlib.linux.template_debug.x86_64.so bin/libxlib.linux.template_release.x86_64.so

bin/libxlib.linux.template_debug.x86_64.so: ../godot-cpp $(ALL_HEADERS) $(ALL_CPP)
	scons -Q compiledb
	scons target=template_debug

bin/libxlib.linux.template_release.x86_64.so: ../godot-cpp $(ALL_HEADERS) $(ALL_CPP)
	scons -Q compiledb
	scons target=template_release

../godot-cpp:
	cd .. && git clone https://github.com/godotengine/godot-cpp.git && cd godot-cpp && git checkout $(GODOT_CPP_VERSION)
	touch ../godot-cpp/.gdignore

.PHONY: clean
clean:
	rm -rf bin
