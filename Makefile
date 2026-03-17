PREFIX ?= /usr/local
BINARY_NAME = stillside
INSTALL_PATH = $(PREFIX)/bin/$(BINARY_NAME)
PLIST_NAME = com.stillside.agent.plist
LAUNCH_AGENTS_DIR = $(HOME)/Library/LaunchAgents

.PHONY: build install uninstall clean

build:
	swift build -c release

install: build
	@mkdir -p $(PREFIX)/bin
	cp .build/release/Stillside $(INSTALL_PATH)
	@mkdir -p $(LAUNCH_AGENTS_DIR)
	sed 's|BINARY_PATH|$(INSTALL_PATH)|g' Support/$(PLIST_NAME) > $(LAUNCH_AGENTS_DIR)/$(PLIST_NAME)
	launchctl unload $(LAUNCH_AGENTS_DIR)/$(PLIST_NAME) 2>/dev/null || true
	launchctl load $(LAUNCH_AGENTS_DIR)/$(PLIST_NAME)
	@echo "Stillside installed and running."

uninstall:
	launchctl unload $(LAUNCH_AGENTS_DIR)/$(PLIST_NAME) 2>/dev/null || true
	rm -f $(LAUNCH_AGENTS_DIR)/$(PLIST_NAME)
	rm -f $(INSTALL_PATH)
	@echo "Stillside uninstalled."

clean:
	rm -rf .build
	@echo "Build artifacts cleaned."
