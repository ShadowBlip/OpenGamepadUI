PREFIX ?= $(HOME)/.local

##@ General

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: install 
install: ## Install OpenGamepadUI (default: ~/.local)
	@echo "Using prefix: $(PREFIX)"
	mkdir -p $(PREFIX)/bin
	install -Dm755 usr/bin/opengamepadui \
		$(PREFIX)/bin/opengamepadui
	mkdir -p $(PREFIX)/share/applications
	install -Dm644 usr/share/applications/opengamepadui.desktop \
		$(PREFIX)/share/applications/opengamepadui.desktop
	sed -i 's|Exec=opengamepadui|Exec=$(PREFIX)/bin/opengamepadui|g' \
		$(PREFIX)/share/applications/opengamepadui.desktop
	mkdir -p $(PREFIX)/share/icons/hicolor/scalable/apps
	install -Dm644 usr/share/icons/hicolor/scalable/apps/opengamepadui.svg \
		$(PREFIX)/share/icons/hicolor/scalable/apps/opengamepadui.svg
	mkdir -p $(PREFIX)/share/opengamepadui
	install -Dm644 usr/share/opengamepadui/libdbus.linux.template_debug.x86_64.so \
		$(PREFIX)/share/opengamepadui/libdbus.linux.template_debug.x86_64.so
	install -Dm644 usr/share/opengamepadui/libevdev.linux.template_debug.x86_64.so \
		$(PREFIX)/share/opengamepadui/libevdev.linux.template_debug.x86_64.so
	install -Dm644 usr/share/opengamepadui/liblinuxthread.linux.template_debug.x86_64.so \
		$(PREFIX)/share/opengamepadui/liblinuxthread.linux.template_debug.x86_64.so
	install -Dm644 usr/share/opengamepadui/libopensd.linux.template_debug.x86_64.so \
		$(PREFIX)/share/opengamepadui/libopensd.linux.template_debug.x86_64.so
	install -Dm644 usr/share/opengamepadui/libpty.linux.template_debug.x86_64.so \
		$(PREFIX)/share/opengamepadui/libpty.linux.template_debug.x86_64.so
	install -Dm644 usr/share/opengamepadui/libxlib.linux.template_debug.x86_64.so \
		$(PREFIX)/share/opengamepadui/libxlib.linux.template_debug.x86_64.so
	install -Dm755 usr/share/opengamepadui/opengamepad-ui.x86_64 \
		$(PREFIX)/share/opengamepadui/opengamepad-ui.x86_64
	setcap 'cap_sys_nice=eip' $(PREFIX)/share/opengamepadui/opengamepad-ui.x86_64 || true
	mkdir -p $(PREFIX)/share/opengamepadui/scripts
	install -Dm755 usr/share/opengamepadui/scripts/powertools \
		$(PREFIX)/share/opengamepadui/scripts/powertools
	install -Dm755 usr/share/opengamepadui/scripts/manage_input \
		$(PREFIX)/share/opengamepadui/scripts/manage_input
	install -Dm755 usr/share/opengamepadui/scripts/make_nice \
		$(PREFIX)/share/opengamepadui/scripts/make_nice
	install -Dm644 usr/share/polkit-1/actions/org.shadowblip.powertools.policy \
		$(PREFIX)/share/polkit-1/actions/org.shadowblip.powertools.policy
	install -Dm644 usr/share/polkit-1/actions/org.shadowblip.manage_input.policy \
		$(PREFIX)/share/polkit-1/actions/org.shadowblip.manage_input.policy
	install -Dm644 usr/share/polkit-1/actions/org.shadowblip.setcap.policy \
		$(PREFIX)/share/polkit-1/actions/org.shadowblip.setcap.policy
	install -Dm644 usr/lib/udev/hwdb.d/59-opengamepadui-handheld.hwdb \
		$(PREFIX)/lib/udev/hwdb.d/59-opengamepadui-handheld.hwdb
	install -Dm644 usr/lib/udev/rules.d/61-opengamepadui-handheld.rules \
		$(PREFIX)/lib/udev/rules.d/61-opengamepadui-handheld.rules
	install -Dm644 usr/lib/systemd/user/systemd-sysext-updater.service \
		$(PREFIX)/lib/systemd/user/systemd-sysext-updater.service
	install -Dm644 usr/lib/systemd/user/ogui-overlay-mode.service \
		$(PREFIX)/lib/systemd/user/ogui-overlay-mode.service
	@echo "Installation complete"

.PHONY: uninstall
uninstall: ## Uninstall OpenGamepadUI
	rm -rf $(PREFIX)/share/applications/opengamepadui.desktop
	rm -rf $(PREFIX)/icons/hicolor/scalable/apps/opengamepadui.svg
	rm -rf $(PREFIX)/bin/opengamepadui
	rm -rf $(PREFIX)/share/opengamepadui/opengamepad-ui.x86_64
	rm -rf $(PREFIX)/share/opengamepadui/*.so
	rm -rf $(PREFIX)/share/opengamepadui/scripts/powertools
	rm -rf $(PREFIX)/share/polkit-1/actions/org.shadowblip.powertools.policy
	rm -rf $(PREFIX)/lib/udev/hwdb.d/59-opengamepadui-handheld.hwdb
	rm -rf $(PREFIX)/lib/udev/rules.d/10-opengamepadui-handheld.rules
	rm -rf $(PREFIX)/lib/systemd/user/systemd-sysext-updater.service
	rm -rf $(PREFIX)/lib/systemd/user/ogui-overlay-mode.service
	@echo "Uninstall complete"
