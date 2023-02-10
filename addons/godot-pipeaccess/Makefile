
ALL_CPP := $(shell find ./ -name '*.cpp')
ALL_HEADERS := $(shell find ./src -name '*.h')
GODOT_CPP_VERSION := 516fad14e45d341211121832bb3daa172aebd6e1

.PHONY: build
build: bin/libpipeaccess.linux.template_debug.x86_64.so bin/libpipeaccess.linux.template_release.x86_64.so

bin/libpipeaccess.linux.template_debug.x86_64.so: ../godot-cpp $(ALL_HEADERS) $(ALL_CPP)
	rm -rf $@
	#scons -Q compiledb
	scons target=template_debug

bin/libpipeaccess.linux.template_release.x86_64.so: ../godot-cpp $(ALL_HEADERS) $(ALL_CPP)
	rm -rf $@
	#scons -Q compiledb
	scons target=template_release

../godot-cpp:
	cd .. && git clone https://github.com/godotengine/godot-cpp.git && cd godot-cpp && git checkout $(GODOT_CPP_VERSION)
	touch ../godot-cpp/.gdignore

.PHONY: clean
clean:
	rm -rf bin
	rm -rf ../godot-cpp
