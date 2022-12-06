# https://medium.datadriveninvestor.com/how-to-quickly-embed-python-in-your-c-application-23c19694813
ALL_CPP := $(shell find ./ -name '*.cpp')
ALL_HEADERS := $(shell find ./src -name '*.h')

.PHONY: build
build: bin/libpythonscript.linux.template_debug.x86_64.so bin/libpythonscript.linux.template_release.x86_64.so

bin/libpythonscript.linux.template_debug.x86_64.so: ../godot-cpp $(ALL_HEADERS) $(ALL_CPP)
	scons -Q compiledb
	scons target=template_debug

bin/libpythonscript.linux.template_release.x86_64.so: ../godot-cpp $(ALL_HEADERS) $(ALL_CPP)
	scons -Q compiledb
	scons target=template_release

../godot-cpp:
	cd .. && git clone https://github.com/godotengine/godot-cpp.git
	touch ../godot-cpp/.gdignore

.PHONY: clean
clean:
	rm -rf bin
