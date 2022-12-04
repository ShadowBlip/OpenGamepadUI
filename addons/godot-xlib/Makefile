
ALL_CPP := $(shell find ./ -name '*.cpp')
ALL_HEADERS := $(shell find ./src -name '*.h')

.PHONY: build
build: bin/libxlib.linux.template_debug.x86_64.so bin/libxlib.linux.template_release.x86_64.so

bin/libxlib.linux.template_debug.x86_64.so: ../godot-cpp $(ALL_HEADERS) $(ALL_CPP)
	scons -Q compiledb
	scons target=template_debug

bin/libxlib.linux.template_release.x86_64.so: ../godot-cpp $(ALL_HEADERS) $(ALL_CPP)
	scons -Q compiledb
	scons target=template_release

../godot-cpp:
	cd .. && git clone https://github.com/godotengine/godot-cpp.git
	touch ../godot-cpp/.gdignore

