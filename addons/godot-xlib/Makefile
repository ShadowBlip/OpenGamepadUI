
.PHONY: build
build: ../godot-cpp
	scons -Q compiledb
	scons target=template_debug
	scons target=template_release

../godot-cpp:
	cd .. && git clone https://github.com/godotengine/godot-cpp.git

