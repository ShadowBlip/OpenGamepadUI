NUM_CPU := $(shell nproc)

# List of all build targets for all extensions
ALL_DEBUG_EXT   = $(DBUS_DEBUG_TARGET) $(THREAD_DEBUG_TARGET) $(PTY_DEBUG_TARGET) $(UNIXSOCK_DEBUG_TARGET) $(XLIB_DEBUG_TARGET)
ALL_RELEASE_EXT = $(DBUS_RELEASE_TARGET) $(THREAD_RELEASE_TARGET) $(PTY_RELEASE_TARGET) $(UNIXSOCK_RELEASE_TARGET) $(XLIB_RELEASE_TARGET)
ALL_GDEXT       = $(DBUS_GDEXT_TARGET) $(THREAD_GDEXT_TARGET) $(PTY_GDEXT_TARGET) $(UNIXSOCK_GDEXT_TARGET) $(XLIB_GDEXT_TARGET)

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

.PHONY: build
build: ## Build all GDExtensions
	$(MAKE) $(ALL_DEBUG_EXT) $(ALL_RELEASE_EXT) $(ALL_GDEXT)

## Godot CPP

GODOT_CPP_FILES := $(shell find ./godot-cpp -regex  '.*\(\.cpp\|\.h\|\.hpp\)$$') godot-cpp/SConstruct
GODOT_CPP_DEBUG := godot-cpp/bin/libgodot-cpp.linux.template_debug.x86_64.a
GODOT_CPP_RELEASE := godot-cpp/bin/libgodot-cpp.linux.template_release.x86_64.a

godot-cpp/SConstruct:
	git submodule update --init godot-cpp

$(GODOT_CPP_DEBUG): $(GODOT_CPP_FILES)
	cd godot-cpp && scons platform=linux -j$(NUM_CPU) target=template_debug

$(GODOT_CPP_RELEASE): $(GODOT_CPP_FILES)
	cd godot-cpp && scons platform=linux -j$(NUM_CPU) target=template_release

##@ GDExtensions

## ------ Godot DBus ------

DBUS_EXT_NAME = dbus
DBUS_FILES = $(shell find ./godot-$(DBUS_EXT_NAME) -regex  '.*\(\.cpp\|\.h\|\.hpp\)$$')
DBUS_GDEXT_FILE = $(DBUS_EXT_NAME).gdextension
DBUS_GDEXT_TARGET = ../addons/$(DBUS_EXT_NAME)/$(DBUS_GDEXT_FILE)
DBUS_DEBUG_LIB = lib$(DBUS_EXT_NAME).linux.template_debug.x86_64.so
DBUS_DEBUG_TARGET = ../addons/$(DBUS_EXT_NAME)/bin/$(DBUS_DEBUG_LIB)
DBUS_RELEASE_LIB = lib$(DBUS_EXT_NAME).linux.template_release.x86_64.so
DBUS_RELEASE_TARGET = ../addons/$(DBUS_EXT_NAME)/bin/$(DBUS_RELEASE_LIB)

.PHONY: godot-dbus
godot-dbus: ## Build godot-dbus extension
	$(MAKE) $(DBUS_DEBUG_TARGET) $(DBUS_RELEASE_TARGET) $(DBUS_GDEXT_TARGET)

$(DBUS_GDEXT_TARGET): ./godot-$(DBUS_EXT_NAME)/addons/$(DBUS_EXT_NAME)/$(DBUS_GDEXT_FILE)
	cp ./godot-$(DBUS_EXT_NAME)/addons/$(DBUS_EXT_NAME)/$(DBUS_GDEXT_FILE) $(DBUS_GDEXT_TARGET)

$(DBUS_DEBUG_TARGET): godot-cpp/SConstruct
	cd godot-$(DBUS_EXT_NAME) && GODOT_CPP_PATH=../godot-cpp scons \
		-j$(NUM_CPU) \
		target=template_debug
		platform=linux
	mkdir -p ../addons/$(DBUS_EXT_NAME)/bin
	cp -r ./godot-$(DBUS_EXT_NAME)/addons/$(DBUS_EXT_NAME)/bin/$(DBUS_DEBUG_LIB) ../addons/$(DBUS_EXT_NAME)/bin/$(DBUS_DEBUG_LIB)

$(DBUS_RELEASE_TARGET): godot-cpp/SConstruct
	cd godot-$(DBUS_EXT_NAME) && GODOT_CPP_PATH=../godot-cpp scons \
		-j$(NUM_CPU) \
		target=template_release
		platform=linux
	mkdir -p ../addons/$(DBUS_EXT_NAME)/bin
	cp -r ./godot-$(DBUS_EXT_NAME)/addons/$(DBUS_EXT_NAME)/bin/$(DBUS_RELEASE_LIB) ../addons/$(DBUS_EXT_NAME)/bin/$(DBUS_RELEASE_LIB)

## ------ Godot Linux Threads ------

THREAD_EXT_NAME := linuxthread
THREAD_FILES := $(shell find ./godot-$(THREAD_EXT_NAME) -regex  '.*\(\.cpp\|\.h\|\.hpp\)$$')
THREAD_GDEXT_FILE := $(THREAD_EXT_NAME).gdextension
THREAD_GDEXT_TARGET := ../addons/$(THREAD_EXT_NAME)/$(THREAD_GDEXT_FILE)
THREAD_DEBUG_LIB := lib$(THREAD_EXT_NAME).linux.template_debug.x86_64.so
THREAD_DEBUG_TARGET := ../addons/$(THREAD_EXT_NAME)/bin/$(THREAD_DEBUG_LIB)
THREAD_RELEASE_LIB := lib$(THREAD_EXT_NAME).linux.template_release.x86_64.so
THREAD_RELEASE_TARGET := ../addons/$(THREAD_EXT_NAME)/bin/$(THREAD_RELEASE_LIB)

.PHONY: godot-linuxthread
godot-linuxthread: ## Build godot-linuxthread extension
	$(MAKE) $(THREAD_DEBUG_TARGET) $(THREAD_RELEASE_TARGET) $(THREAD_GDEXT_TARGET)

$(THREAD_GDEXT_TARGET): ./godot-$(THREAD_EXT_NAME)/addons/$(THREAD_EXT_NAME)/$(THREAD_GDEXT_FILE)
	cp ./godot-$(THREAD_EXT_NAME)/addons/$(THREAD_EXT_NAME)/$(THREAD_GDEXT_FILE) $(THREAD_GDEXT_TARGET)

$(THREAD_DEBUG_TARGET): godot-cpp/SConstruct
	cd godot-$(THREAD_EXT_NAME) && GODOT_CPP_PATH=../godot-cpp scons \
		-j$(NUM_CPU) \
		target=template_debug
		platform=linux
	mkdir -p ../addons/$(THREAD_EXT_NAME)/bin
	cp -r ./godot-$(THREAD_EXT_NAME)/addons/$(THREAD_EXT_NAME)/bin/$(THREAD_DEBUG_LIB) ../addons/$(THREAD_EXT_NAME)/bin/$(THREAD_DEBUG_LIB)

$(THREAD_RELEASE_TARGET): godot-cpp/SConstruct
	cd godot-$(THREAD_EXT_NAME) && GODOT_CPP_PATH=../godot-cpp scons \
		-j$(NUM_CPU) \
		target=template_release
		platform=linux
	mkdir -p ../addons/$(THREAD_EXT_NAME)/bin
	cp -r ./godot-$(THREAD_EXT_NAME)/addons/$(THREAD_EXT_NAME)/bin/$(THREAD_RELEASE_LIB) ../addons/$(THREAD_EXT_NAME)/bin/$(THREAD_RELEASE_LIB)

## ------ Godot PTY ------

PTY_EXT_NAME := pty
PTY_FILES := $(shell find ./godot-$(PTY_EXT_NAME) -regex  '.*\(\.cpp\|\.h\|\.hpp\)$$')
PTY_GDEXT_FILE := $(PTY_EXT_NAME).gdextension
PTY_GDEXT_TARGET := ../addons/$(PTY_EXT_NAME)/$(PTY_GDEXT_FILE)
PTY_DEBUG_LIB := lib$(PTY_EXT_NAME).linux.template_debug.x86_64.so
PTY_DEBUG_TARGET := ../addons/$(PTY_EXT_NAME)/bin/$(PTY_DEBUG_LIB)
PTY_RELEASE_LIB := lib$(PTY_EXT_NAME).linux.template_release.x86_64.so
PTY_RELEASE_TARGET := ../addons/$(PTY_EXT_NAME)/bin/$(PTY_RELEASE_LIB)

.PHONY: godot-pty
godot-pty: ## Build godot-pty extension
	$(MAKE) $(PTY_DEBUG_TARGET) $(PTY_RELEASE_TARGET) $(PTY_GDEXT_TARGET)

$(PTY_GDEXT_TARGET): ./godot-$(PTY_EXT_NAME)/addons/$(PTY_EXT_NAME)/$(PTY_GDEXT_FILE)
	cp ./godot-$(PTY_EXT_NAME)/addons/$(PTY_EXT_NAME)/$(PTY_GDEXT_FILE) $(PTY_GDEXT_TARGET)

$(PTY_DEBUG_TARGET): godot-cpp/SConstruct
	cd godot-$(PTY_EXT_NAME) && GODOT_CPP_PATH=../godot-cpp scons \
		-j$(NUM_CPU) \
		target=template_debug
		platform=linux
	mkdir -p ../addons/$(PTY_EXT_NAME)/bin
	cp -r ./godot-$(PTY_EXT_NAME)/addons/$(PTY_EXT_NAME)/bin/$(PTY_DEBUG_LIB) ../addons/$(PTY_EXT_NAME)/bin/$(PTY_DEBUG_LIB)

$(PTY_RELEASE_TARGET): godot-cpp/SConstruct
	cd godot-$(PTY_EXT_NAME) && GODOT_CPP_PATH=../godot-cpp scons \
		-j$(NUM_CPU) \
		target=template_release
		platform=linux
	mkdir -p ../addons/$(PTY_EXT_NAME)/bin
	cp -r ./godot-$(PTY_EXT_NAME)/addons/$(PTY_EXT_NAME)/bin/$(PTY_RELEASE_LIB) ../addons/$(PTY_EXT_NAME)/bin/$(PTY_RELEASE_LIB)

## ------ Godot Unix Socket ------

UNIXSOCK_EXT_NAME := unixsock
UNIXSOCK_FILES := $(shell find ./godot-unix-socket -regex  '.*\(\.cpp\|\.h\|\.hpp\)$$')
UNIXSOCK_GDEXT_FILE := $(UNIXSOCK_EXT_NAME).gdextension
UNIXSOCK_GDEXT_TARGET := ../addons/$(UNIXSOCK_EXT_NAME)/$(UNIXSOCK_GDEXT_FILE)
UNIXSOCK_DEBUG_LIB := lib$(UNIXSOCK_EXT_NAME).linux.template_debug.x86_64.so
UNIXSOCK_DEBUG_TARGET := ../addons/$(UNIXSOCK_EXT_NAME)/bin/$(UNIXSOCK_DEBUG_LIB)
UNIXSOCK_RELEASE_LIB := lib$(UNIXSOCK_EXT_NAME).linux.template_release.x86_64.so
UNIXSOCK_RELEASE_TARGET := ../addons/$(UNIXSOCK_EXT_NAME)/bin/$(UNIXSOCK_RELEASE_LIB)

.PHONY: godot-unixsock
godot-unixsock: ## Build godot-unixsock extension
	$(MAKE) $(UNIXSOCK_DEBUG_TARGET) $(UNIXSOCK_RELEASE_TARGET) $(UNIXSOCK_GDEXT_TARGET)

$(UNIXSOCK_GDEXT_TARGET): ./godot-unix-socket/addons/$(UNIXSOCK_EXT_NAME)/$(UNIXSOCK_GDEXT_FILE)
	cp ./godot-unix-socket/addons/$(UNIXSOCK_EXT_NAME)/$(UNIXSOCK_GDEXT_FILE) $(UNIXSOCK_GDEXT_TARGET)

$(UNIXSOCK_DEBUG_TARGET): godot-cpp/SConstruct
	cd godot-unix-socket && GODOT_CPP_PATH=../godot-cpp scons \
		-j$(NUM_CPU) \
		target=template_debug
		platform=linux
	mkdir -p ../addons/$(UNIXSOCK_EXT_NAME)/bin
	cp -r ./godot-unix-socket/addons/$(UNIXSOCK_EXT_NAME)/bin/$(UNIXSOCK_DEBUG_LIB) ../addons/$(UNIXSOCK_EXT_NAME)/bin/$(UNIXSOCK_DEBUG_LIB)

$(UNIXSOCK_RELEASE_TARGET): godot-cpp/SConstruct
	cd godot-unix-socket && GODOT_CPP_PATH=../godot-cpp scons \
		-j$(NUM_CPU) \
		target=template_release
		platform=linux
	mkdir -p ../addons/$(UNIXSOCK_EXT_NAME)/bin
	cp -r ./godot-unix-socket/addons/$(UNIXSOCK_EXT_NAME)/bin/$(UNIXSOCK_RELEASE_LIB) ../addons/$(UNIXSOCK_EXT_NAME)/bin/$(UNIXSOCK_RELEASE_LIB)

## ------ Godot XLib ------

XLIB_EXT_NAME := xlib
XLIB_FILES := $(shell find ./godot-$(XLIB_EXT_NAME) -regex  '.*\(\.cpp\|\.h\|\.hpp\)$$')
XLIB_GDEXT_FILE := $(XLIB_EXT_NAME).gdextension
XLIB_GDEXT_TARGET := ../addons/$(XLIB_EXT_NAME)/$(XLIB_GDEXT_FILE)
XLIB_DEBUG_LIB := lib$(XLIB_EXT_NAME).linux.template_debug.x86_64.so
XLIB_DEBUG_TARGET := ../addons/$(XLIB_EXT_NAME)/bin/$(XLIB_DEBUG_LIB)
XLIB_RELEASE_LIB := lib$(XLIB_EXT_NAME).linux.template_release.x86_64.so
XLIB_RELEASE_TARGET := ../addons/$(XLIB_EXT_NAME)/bin/$(XLIB_RELEASE_LIB)

.PHONY: godot-xlib
godot-xlib: ## Build godot-xlib extension
	$(MAKE) $(XLIB_DEBUG_TARGET) $(XLIB_RELEASE_TARGET) $(XLIB_GDEXT_TARGET)

$(XLIB_GDEXT_TARGET): ./godot-$(XLIB_EXT_NAME)/addons/$(XLIB_EXT_NAME)/$(XLIB_GDEXT_FILE)
	cp ./godot-$(XLIB_EXT_NAME)/addons/$(XLIB_EXT_NAME)/$(XLIB_GDEXT_FILE) $(XLIB_GDEXT_TARGET)

$(XLIB_DEBUG_TARGET): godot-cpp/SConstruct
	cd godot-$(XLIB_EXT_NAME) && GODOT_CPP_PATH=../godot-cpp scons \
		-j$(NUM_CPU) \
		target=template_debug
		platform=linux
	mkdir -p ../addons/$(XLIB_EXT_NAME)/bin
	cp -r ./godot-$(XLIB_EXT_NAME)/addons/$(XLIB_EXT_NAME)/bin/$(XLIB_DEBUG_LIB) ../addons/$(XLIB_EXT_NAME)/bin/$(XLIB_DEBUG_LIB)

$(XLIB_RELEASE_TARGET): godot-cpp/SConstruct
	cd godot-$(XLIB_EXT_NAME) && GODOT_CPP_PATH=../godot-cpp scons \
		-j$(NUM_CPU) \
		target=template_release
		platform=linux
	mkdir -p ../addons/$(XLIB_EXT_NAME)/bin
	cp -r ./godot-$(XLIB_EXT_NAME)/addons/$(XLIB_EXT_NAME)/bin/$(XLIB_RELEASE_LIB) ../addons/$(XLIB_EXT_NAME)/bin/$(XLIB_RELEASE_LIB)


##@ Updates

.PHONY: update-godot-dbus
update-godot-dbus: ## Update godot-dbus
	cd godot-dbus
	git fetch
	git rebase origin/main
