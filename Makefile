
PREFIX ?= $(HOME)/.local
CACHE_DIR ?= .cache
ROOTFS ?= $(CACHE_DIR)/rootfs
GODOT_VERSION ?= 4.0.1
GODOT_RELEASE ?= stable
GODOT_REVISION := $(GODOT_VERSION).$(GODOT_RELEASE)
GODOT ?= /usr/bin/godot
GAMESCOPE ?= /usr/bin/gamescope

EXPORT_TEMPLATE := $(HOME)/.local/share/godot/export_templates/$(GODOT_REVISION)/linux_debug.x86_64
#EXPORT_TEMPLATE_URL ?= https://downloads.tuxfamily.org/godotengine/$(GODOT_VERSION)/Godot_v$(GODOT_VERSION)-$(GODOT_RELEASE)_export_templates.tpz
EXPORT_TEMPLATE_URL ?= https://github.com/godotengine/godot/releases/download/$(GODOT_VERSION)-$(GODOT_RELEASE)/Godot_v$(GODOT_VERSION)-$(GODOT_RELEASE)_export_templates.tpz

ALL_GDSCRIPT := $(shell find ./ -name '*.gd')
ALL_SCENES := $(shell find ./ -name '*.tscn')

# Remote debugging variables 
SSH_USER ?= deck
SSH_HOST ?= 192.168.0.65
SSH_MOUNT_PATH ?= /tmp/remote
SSH_DATA_PATH ?= /home/$(SSH_USER)/Projects

# systemd-sysext variables 
SYSEXT_ID ?= steamos
SYSEXT_VERSION_ID ?= 3.4.6

# Include any user defined settings
-include settings.mk

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

.PHONY: install 
install: rootfs ## Install OpenGamepadUI (default: ~/.local)
	cd $(ROOTFS) && make install PREFIX=$(PREFIX)

.PHONY: uninstall
uninstall: ## Uninstall OpenGamepadUI
	cd $(ROOTFS) && make uninstall PREFIX=$(PREFIX)

##@ Systemd Extension

.PHONY: enable-ext
enable-ext: ## Enable systemd extensions
	mkdir -p $(HOME)/.var/lib/extensions
	sudo ln -s $(HOME)/.var/lib/extensions /var/lib/extensions
	sudo systemctl enable systemd-sysext
	sudo systemctl start systemd-sysext
	systemd-sysext status

.PHONY: disable-ext
disable-ext: ## Disable systemd extensions
	sudo systemctl stop systemd-sysext
	sudo systemctl disable systemd-sysext

.PHONY: install-ext
install-ext: systemd-sysext ## Install OpenGamepadUI as a systemd extension
	cp dist/opengamepadui.raw $(HOME)/.var/lib/extensions
	sudo systemd-sysext refresh
	systemd-sysext status

.PHONY: uninstall-ext
uninstall-ext: ## Uninstall the OpenGamepadUI systemd extension
	rm -rf $(HOME)/.var/lib/extensions
	sudo systemd-sysext refresh
	systemd-sysext status

##@ Development

.PHONY: test
test: addons ## Run all unit tests
	$(GODOT) --path $(PWD) --headless --debug \
		--remote-debug tcp://127.0.0.1:6007 \
		res://core/systems/testing/run_tests.tscn

.PHONY: build
build: addons build/opengamepad-ui.x86_64 ## Build and export the project
build/opengamepad-ui.x86_64: $(ALL_GDSCRIPT) $(ALL_SCENES) $(EXPORT_TEMPLATE)
	mkdir -p build
	$(GODOT) --headless --export-debug "Linux/X11"

.PHONY: update-pack
update-pack: addons build/update.pck ## Build and export update pack
build/update.pck: $(ALL_GDSCRIPT) $(ALL_SCENES) $(EXPORT_TEMPLATE)
	mkdir -p build
	$(GODOT) --headless --export-pack "Linux/X11 (Update Pack)" $@

.PHONY: plugins
plugins: addons build/plugins.zip ## Build and export plugins
build/plugins.zip: $(ALL_GDSCRIPT) $(ALL_SCENES) $(EXPORT_TEMPLATE)
	mkdir -p build
	$(GODOT) --headless --export-pack "Linux/X11 (Plugins)" $@

.PHONY: import
import: ## Import project assets
	@echo "Importing project assets. This will take some time..."
	timeout --foreground 60 $(GODOT) --headless --editor . || echo "Finished"

.PHONY: addons
addons: ## Build GDExtension add-ons
	@echo "Building gdnative addons"
	cd ./addons/godot-xlib && make build
	cd ./addons/godot-evdev && make build
	cd ./addons/godot-pty && make build
	cd ./addons/godot-opensd && make build

.PHONY: edit
edit: ## Open the project in the Godot editor
	$(GODOT) --editor .

.PHONY: clean
clean: ## Remove build artifacts
	rm -rf build
	rm -rf $(ROOTFS)
	rm -rf $(CACHE_DIR)
	rm -rf dist
	cd ./addons/godot-xlib && make clean
	cd ./addons/godot-evdev && make clean
	cd ./addons/godot-pty && make clean
	cd ./addons/godot-opensd && make clean

.PHONY: run run-force
run: addons build/opengamepad-ui.x86_64 run-force ## Run the project in gamescope
run-force:
	$(GAMESCOPE) -w 1920 -h 1080 -f -e \
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
debug: addons ## Run the project in debug mode in gamescope
	$(GAMESCOPE) -e --xwayland-count 2 -- \
		$(GODOT) --path $(PWD) --remote-debug tcp://127.0.0.1:6007 \
		--position 320,140 res://entrypoint.tscn

.PHONY: debug-qam
debug-qam: addons ## Run the project in debug mode in gamescope with --only-qam
	$(GAMESCOPE) -e --xwayland-count 2 -- \
		$(GODOT) --path $(PWD) --remote-debug tcp://127.0.0.1:6007 \
		--position 320,140 res://entrypoint.tscn --only-qam -- steam -gamepadui -steamos3 -steampal -steamdeck

.PHONY: inspect
inspect: addons ## Launch Gamescope inspector
	$(GODOT) --path $(PWD) res://core/ui/menu/debug/gamescope_inspector.tscn


.PHONY: signing-keys
signing-keys: assets/crypto/keys/opengamepadui.pub ## Generate a signing keypair to sign packages

assets/crypto/keys/opengamepadui.key:
	@echo "Generating signing keys"
	mkdir -p assets/crypto/keys
	openssl genrsa -out $@ 4096

assets/crypto/keys/opengamepadui.pub: assets/crypto/keys/opengamepadui.key
	openssl rsa -in $^ -outform PEM -pubout -out $@


##@ Remote Debugging

.PHONY: deploy
deploy: dist-archive $(SSH_MOUNT_PATH)/.mounted ## Build, deploy, and tunnel to a remote device
	cp dist/opengamepadui.tar.gz $(SSH_MOUNT_PATH)
	cd $(SSH_MOUNT_PATH) && tar xvfz opengamepadui.tar.gz


.PHONY: deploy-pack
deploy-pack: dist/update.pck.sig ## Build and deploy update pack to remote device
	ssh $(SSH_USER)@$(SSH_HOST) mkdir -p .local/share/opengamepadui/updates
	scp dist/update.pck $(SSH_USER)@$(SSH_HOST):~/.local/share/opengamepadui/updates
	scp dist/update.pck.sig $(SSH_USER)@$(SSH_HOST):~/.local/share/opengamepadui/updates


.PHONY: deploy-ext
deploy-ext: dist-ext ## Build and deploy systemd extension to remote device
	ssh $(SSH_USER)@$(SSH_HOST) mkdir -p .var/lib/extensions .config/systemd/user
	scp dist/opengamepadui.raw $(SSH_USER)@$(SSH_HOST):~/.var/lib/extensions
	scp rootfs/usr/lib/systemd/user/systemd-sysext-updater.service $(SSH_USER)@$(SSH_HOST):~/.config/systemd/user
	ssh -t $(SSH_USER)@$(SSH_HOST) systemctl --user enable systemd-sysext-updater
	ssh -t $(SSH_USER)@$(SSH_HOST) systemctl --user start systemd-sysext-updater
	sleep 3
	ssh -t $(SSH_USER)@$(SSH_HOST) sudo systemd-sysext refresh
	ssh $(SSH_USER)@$(SSH_HOST) systemd-sysext status


.PHONY: enable-debug
enable-debug: ## Set OpenGamepadUI command to use remote debug on target device
	ssh $(SSH_USER)@$(SSH_HOST) mkdir -p .config/environment.d
	echo 'OGUICMD="opengamepadui --remote-debug tcp://127.0.0.1:6007"' | \
		ssh $(SSH_USER)@$(SSH_HOST) bash -c \
		'cat > .config/environment.d/opengamepadui-session.conf'


.PHONY: tunnel
tunnel: ## Create an SSH tunnel to allow remote debugging
	ssh $(SSH_USER)@$(SSH_HOST) -N -f -R 6007:localhost:6007


# Mounts the remote device and creates an SSH tunnel for remote debugging
$(SSH_MOUNT_PATH)/.mounted:
	mkdir -p $(SSH_MOUNT_PATH)
	sshfs -o default_permissions $(SSH_USER)@$(SSH_HOST):$(SSH_DATA_PATH) $(SSH_MOUNT_PATH)
	$(MAKE) tunnel
	touch $(SSH_MOUNT_PATH)/.mounted


##@ Distribution

.PHONY: rootfs
rootfs: build/opengamepad-ui.x86_64
	rm -rf $(ROOTFS)
	mkdir -p $(ROOTFS)
	cp -r rootfs/* $(ROOTFS)
	mkdir -p $(ROOTFS)/usr/share/opengamepadui
	cp -r build/*.so $(ROOTFS)/usr/share/opengamepadui
	cp -r build/opengamepad-ui.x86_64 $(ROOTFS)/usr/share/opengamepadui
	touch $(ROOTFS)/.gdignore


.PHONY: dist 
dist: dist/opengamepadui.tar.gz dist/opengamepadui.raw dist/update.pck.sig ## Create all redistributable versions of the project
	cd dist && sha256sum opengamepadui.tar.gz > opengamepadui.tar.gz.sha256.txt
	cd dist && sha256sum update.pck > update.pck.sha256.txt
	cd dist && sha256sum opengamepadui.raw > opengamepadui.raw.sha256.txt


.PHONY: dist-archive
dist-archive: dist/opengamepadui.tar.gz ## Create a redistributable tar.gz of the project
dist/opengamepadui.tar.gz: rootfs
	@echo "Building redistributable tar.gz archive"
	mkdir -p dist
	mv $(ROOTFS) $(CACHE_DIR)/opengamepadui
	cd $(CACHE_DIR) && tar cvfz opengamepadui.tar.gz opengamepadui
	mv $(CACHE_DIR)/opengamepadui.tar.gz dist
	mv $(CACHE_DIR)/opengamepadui $(ROOTFS)


.PHONY: dist-update-pack
dist-update-pack: dist/update.pck ## Create an update pack archive
dist/update.pck: update-pack
	@echo "Building redistributable update pack"
	mkdir -p dist
	cp build/update.pck $@

dist/update.pck.sig: dist/update.pck assets/crypto/keys/opengamepadui.key
	@echo "Signing update pack $<"
	openssl dgst -sha256 -sign assets/crypto/keys/opengamepadui.key -out $@ $<


# https://blogs.igalia.com/berto/2022/09/13/adding-software-to-the-steam-deck-with-systemd-sysext/
.PHONY: dist-ext
dist-ext: dist/opengamepadui.raw ## Create a systemd-sysext extension archive
dist/opengamepadui.raw: dist/opengamepadui.tar.gz $(CACHE_DIR)/opengamepadui-session.tar.gz $(CACHE_DIR)/RyzenAdj/build/ryzenadj
	@echo "Building redistributable systemd extension"
	mkdir -p dist
	rm -rf dist/opengamepadui.raw $(CACHE_DIR)/opengamepadui.raw
	cp dist/opengamepadui.tar.gz $(CACHE_DIR)
	cd $(CACHE_DIR) && tar xvfz opengamepadui.tar.gz opengamepadui/usr
	mkdir -p $(CACHE_DIR)/opengamepadui/usr/lib/extension-release.d
	echo ID=$(SYSEXT_ID) > $(CACHE_DIR)/opengamepadui/usr/lib/extension-release.d/extension-release.opengamepadui
	echo VERSION_ID=$(SYSEXT_VERSION_ID) >> $(CACHE_DIR)/opengamepadui/usr/lib/extension-release.d/extension-release.opengamepadui

	@# Copy opengamepadui-session into the extension
	cd $(CACHE_DIR) && tar xvfz opengamepadui-session.tar.gz
	cp -r $(CACHE_DIR)/OpenGamepadUI-session-main/usr/* $(CACHE_DIR)/opengamepadui/usr

	@# Copy ryzenadj files into the extension
	install -Dsm 755 $(CACHE_DIR)/RyzenAdj/build/ryzenadj $(CACHE_DIR)/opengamepadui/usr/bin/ryzenadj
	install -Dsm 744 $(CACHE_DIR)/RyzenAdj/build/libryzenadj.so $(CACHE_DIR)/opengamepadui/usr/lib/libryzenadj.so
	install -Dm 644 $(CACHE_DIR)/RyzenAdj/lib/ryzenadj.h $(CACHE_DIR)/opengamepadui/usr/include/ryzenadj.h

	@# Build the extension archive
	cd $(CACHE_DIR) && mksquashfs opengamepadui opengamepadui.raw
	rm -rf $(CACHE_DIR)/opengamepadui $(CACHE_DIR)/OpenGamepadUI-session-main
	mv $(CACHE_DIR)/opengamepadui.raw $@


$(CACHE_DIR)/RyzenAdj/build/ryzenadj:
	rm -Rf $(CACHE_DIR)/RyzenAdj
	@# Copy ryzenadj into the extension
	git clone https://github.com/FlyGoat/RyzenAdj.git $(CACHE_DIR)/RyzenAdj
	mkdir -p $(CACHE_DIR)/RyzenAdj/build
	cd $(CACHE_DIR)/RyzenAdj/build && cmake -DCMAKE_BUILD_TYPE=Release .. && make


$(CACHE_DIR)/opengamepadui-session.tar.gz:
	wget -O $@ https://github.com/ShadowBlip/OpenGamepadUI-session/archive/refs/heads/main.tar.gz
