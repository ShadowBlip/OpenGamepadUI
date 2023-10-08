PREFIX ?= $(HOME)/.local
CACHE_DIR ?= .cache
ROOTFS ?= $(CACHE_DIR)/rootfs
OGUI_VERSION ?= $(shell grep 'core = ' core/global/version.tres | cut -d '"' -f2)
GODOT_VERSION ?= $(shell godot --version | grep -o '[0-9].*[0-9]')
GODOT_RELEASE ?= $(shell godot --version | rev | cut -d '.' -f2 | rev)
GODOT_REVISION := $(GODOT_VERSION).$(GODOT_RELEASE)
GODOT ?= /usr/bin/godot
GAMESCOPE ?= /usr/bin/gamescope

EXPORT_TEMPLATE := $(HOME)/.local/share/godot/export_templates/$(GODOT_REVISION)/linux_debug.x86_64
#EXPORT_TEMPLATE_URL ?= https://downloads.tuxfamily.org/godotengine/$(GODOT_VERSION)/Godot_v$(GODOT_VERSION)-$(GODOT_RELEASE)_export_templates.tpz
EXPORT_TEMPLATE_URL ?= https://github.com/godotengine/godot/releases/download/$(GODOT_VERSION)-$(GODOT_RELEASE)/Godot_v$(GODOT_VERSION)-$(GODOT_RELEASE)_export_templates.tpz

ALL_GDSCRIPT := $(shell find ./ -name '*.gd')
ALL_SCENES := $(shell find ./ -name '*.tscn')
ALL_RESOURCES := $(shell find ./ -regex  '.*\(tres\|svg\|png\)$$')
PROJECT_FILES := $(ALL_GDSCRIPT) $(ALL_SCENES) $(ALL_RESOURCES)

# Docker image variables
IMAGE_NAME ?= ghcr.io/shadowblip/opengamepadui-builder
IMAGE_TAG ?= latest

# Remote debugging variables 
SSH_USER ?= deck
SSH_HOST ?= 192.168.0.65
SSH_MOUNT_PATH ?= /tmp/remote
SSH_DATA_PATH ?= /home/$(SSH_USER)/Projects

# systemd-sysext variables 
SYSEXT_ID ?= steamos
SYSEXT_VERSION_ID ?= 3.4.8

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
	echo $(GODOT_VERSION)

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
test: ## Run all unit tests
	$(GODOT) --path $(PWD) --headless --debug \
		--remote-debug tcp://127.0.0.1:6007 \
		res://core/systems/testing/run_tests.tscn

.PHONY: build
build: build/opengamepad-ui.x86_64 ## Build and export the project
build/opengamepad-ui.x86_64: $(PROJECT_FILES) $(EXPORT_TEMPLATE)
	@echo "Building OpenGamepadUI v$(OGUI_VERSION)"
	mkdir -p build
	$(GODOT) --headless --export-debug "Linux/X11"

.PHONY: metadata
metadata: build/metadata.json ## Build update metadata
build/metadata.json: build/opengamepad-ui.x86_64 assets/crypto/keys/opengamepadui.key
	@echo "Building update metadata"
	@FILE_SIGS='{'; \
	cd build; \
	# Sign any GDExtension libraries \
	for lib in `ls *.so`; do \
		echo "Signing file: $$lib"; \
		SIG=$$(openssl dgst -sha256 -sign ../assets/crypto/keys/opengamepadui.key $$lib | base64 -w 0); \
		HASH=$$(sha256sum $$lib | cut -d' ' -f1); \
		FILE_SIGS="$$FILE_SIGS\"$$lib\": {\"signature\": \"$$SIG\", \"hash\": \"$$HASH\"}, "; \
	done; \
	# Sign the binary files \
	echo "Signing file: opengamepad-ui.sh"; \
	SIG=$$(openssl dgst -sha256 -sign ../assets/crypto/keys/opengamepadui.key opengamepad-ui.sh | base64 -w 0); \
	HASH=$$(sha256sum opengamepad-ui.sh | cut -d' ' -f1); \
	FILE_SIGS="$$FILE_SIGS\"opengamepad-ui.sh\": {\"signature\": \"$$SIG\", \"hash\": \"$$HASH\"}, "; \
	echo "Signing file: opengamepad-ui.x86_64"; \
	SIG=$$(openssl dgst -sha256 -sign ../assets/crypto/keys/opengamepadui.key opengamepad-ui.x86_64 | base64 -w 0); \
	HASH=$$(sha256sum opengamepad-ui.x86_64 | cut -d' ' -f1); \
	FILE_SIGS="$$FILE_SIGS\"opengamepad-ui.x86_64\": {\"signature\": \"$$SIG\", \"hash\": \"$$HASH\"}}"; \
	# Write out the signatures to metadata.json \
	echo "{\"version\": \"$(OGUI_VERSION)\", \"engine_version\": \"$(GODOT_REVISION)\", \"files\": $$FILE_SIGS}" > metadata.json

	@echo "Metadata written to $@"


.PHONY: import
import: ## Import project assets
	@echo "Importing project assets. This will take some time..."
	timeout --foreground 60 $(GODOT) --headless --editor . || echo "Finished"

.PHONY: edit
edit: ## Open the project in the Godot editor
	$(GODOT) --editor .

.PHONY: clean
clean: ## Remove build artifacts
	rm -rf build
	rm -rf $(ROOTFS)
	rm -rf $(CACHE_DIR)
	rm -rf dist
	rm -rf .godot

.PHONY: run run-force
run: build/opengamepad-ui.x86_64 run-force ## Run the project in gamescope
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
debug: ## Run the project in debug mode in gamescope
	$(GAMESCOPE) -e --xwayland-count 2 -- \
		$(GODOT) --path $(PWD) --remote-debug tcp://127.0.0.1:6007 \
		--position 320,140 res://entrypoint.tscn

.PHONY: debug-overlay
debug-overlay: ## Run the project in debug mode in gamescope with --overlay-mode
	$(GAMESCOPE) -e --xwayland-count 2 -- \
		$(GODOT) --path $(PWD) --remote-debug tcp://127.0.0.1:6007 \
		--position 320,140 res://entrypoint.tscn --overlay-mode -- steam -gamepadui -steamos3 -steampal -steamdeck

.PHONY: docs
docs: docs/api/classes/.generated ## Generate docs
docs/api/classes/.generated: $(ALL_GDSCRIPT)
	rm -rf docs/api/classes
	$(GODOT) \
		--editor \
		--path $(PWD) \
		--quit \
		--doctool docs/api/classes \
		--no-docbase \
		--gdscript-docs core
	rm -rf docs/api/classes/core--*
	$(MAKE) -C docs/api rst

.PHONY: inspect
inspect: ## Launch Gamescope inspector
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


.PHONY: deploy-update
deploy-update: dist/update.zip ## Build and deploy update zip to remote device
	ssh $(SSH_USER)@$(SSH_HOST) mkdir -p .local/share/opengamepadui/updates
	scp dist/update.zip $(SSH_USER)@$(SSH_HOST):~/.local/share/opengamepadui/updates


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
dist: dist/opengamepadui.tar.gz dist/opengamepadui.raw dist/update.zip ## Create all redistributable versions of the project
	cd dist && sha256sum opengamepadui.tar.gz > opengamepadui.tar.gz.sha256.txt
	cd dist && sha256sum opengamepadui.raw > opengamepadui.raw.sha256.txt
	cd dist && sha256sum update.zip > update.zip.sha256.txt


.PHONY: dist-archive
dist-archive: dist/opengamepadui.tar.gz ## Create a redistributable tar.gz of the project
dist/opengamepadui.tar.gz: rootfs
	@echo "Building redistributable tar.gz archive"
	mkdir -p dist
	mv $(ROOTFS) $(CACHE_DIR)/opengamepadui
	cd $(CACHE_DIR) && tar cvfz opengamepadui.tar.gz opengamepadui
	mv $(CACHE_DIR)/opengamepadui.tar.gz dist
	mv $(CACHE_DIR)/opengamepadui $(ROOTFS)


.PHONY: dist-update-zip
dist-update-zip: dist/update.zip ## Create an update zip archive
dist/update.zip: build/metadata.json
	@echo "Building redistributable update zip"
	mkdir -p $(CACHE_DIR)
	rm -rf $(CACHE_DIR)/update.zip
	cd build && zip -5 ../$(CACHE_DIR)/update *.so opengamepad-ui.* metadata.json
	mkdir -p dist
	cp $(CACHE_DIR)/update.zip $@


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


# Refer to .releaserc.yaml for release configuration
.PHONY: release 
release: ## Publish a release with semantic release 
	npx semantic-release

# E.g. make in-docker TARGET=build
.PHONY: in-docker
in-docker:
	@# Run the given make target inside Docker
	docker run --rm \
		-v $(PWD):/src \
		--workdir /src \
		-e HOME=/home/build \
		--user $(shell id -u):$(shell id -g) \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		make $(TARGET)

.PHONY: docker-builder
docker-builder:
	@# Pull any existing image to cache it
	docker pull $(IMAGE_NAME):$(IMAGE_TAG) || echo "No remote image to pull"
	@# Build the Docker image that will build the project
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) -f docker/Dockerfile ./docker

.PHONY: docker-builder-push
docker-builder-push: docker-builder
	docker push $(IMAGE_NAME):$(IMAGE_TAG)
