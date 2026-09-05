TARGET = alacritty

# Dynamically resolve Cargo's actual target directory
TARGET_DIR := $(shell cargo metadata --format-version 1 2>/dev/null | python3 -c "import sys, json; print(json.load(sys.stdin)['target_directory'])" 2>/dev/null || echo "target")

ASSETS_DIR = extra
RELEASE_DIR = $(TARGET_DIR)/release
MANPAGE = $(ASSETS_DIR)/man/alacritty.1.scd
MANPAGE-MSG = $(ASSETS_DIR)/man/alacritty-msg.1.scd
MANPAGE-CONFIG = $(ASSETS_DIR)/man/alacritty.5.scd
MANPAGE-CONFIG-BINDINGS = $(ASSETS_DIR)/man/alacritty-bindings.5.scd
TERMINFO = $(ASSETS_DIR)/alacritty.info
COMPLETIONS_DIR = $(ASSETS_DIR)/completions
COMPLETIONS = $(COMPLETIONS_DIR)/_alacritty \
	$(COMPLETIONS_DIR)/alacritty.bash \
	$(COMPLETIONS_DIR)/alacritty.fish

APP_NAME = Alacritty.app
APP_TEMPLATE = $(ASSETS_DIR)/osx/$(APP_NAME)
APP_DIR = $(RELEASE_DIR)/osx
APP_BINARY = $(RELEASE_DIR)/$(TARGET)
APP_BINARY_DIR = $(APP_DIR)/$(APP_NAME)/Contents/MacOS
APP_EXTRAS_DIR = $(APP_DIR)/$(APP_NAME)/Contents/Resources
APP_COMPLETIONS_DIR = $(APP_EXTRAS_DIR)/completions

DMG_NAME = Alacritty.dmg
DMG_DIR = $(RELEASE_DIR)/osx

LOCAL_TARGET_DIR = target/release/osx

all: help

fix-config:
	@if [ -f .cargo/config.toml ]; then \
		sed -i '' 's|target_dir = ./target|target_dir = "./target"|g' .cargo/config.toml ; \
	fi

help: fix-config ## Print this help message
	@grep -E '^[a-zA-Z._-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

binary: $(TARGET)-native ## Build a release binary
binary-universal: $(TARGET)-universal ## Build a universal release binary

$(TARGET)-native: fix-config
	MACOSX_DEPLOYMENT_TARGET="10.12" cargo build --release

$(TARGET)-universal: fix-config
	MACOSX_DEPLOYMENT_TARGET="10.12" cargo build --release --target=x86_64-apple-darwin
	MACOSX_DEPLOYMENT_TARGET="10.12" cargo build --release --target=aarch64-apple-darwin
	@lipo $(TARGET_DIR)/x86_64-apple-darwin/release/$(TARGET) $(TARGET_DIR)/aarch64-apple-darwin/release/$(TARGET) -create -output $(APP_BINARY)

app: build-app copy-app-local ## Create and copy Alacritty.app locally
app-universal: build-app-universal copy-app-local ## Create and copy universal Alacritty.app locally

build-app: $(TARGET)-native
	@$(MAKE) assemble-app

build-app-universal: $(TARGET)-universal
	@$(MAKE) assemble-app

assemble-app:
	@mkdir -p $(APP_BINARY_DIR)
	@mkdir -p $(APP_EXTRAS_DIR)
	@mkdir -p $(APP_COMPLETIONS_DIR)
	@scdoc < $(MANPAGE) | gzip -c > $(APP_EXTRAS_DIR)/alacritty.1.gz
	@scdoc < $(MANPAGE-MSG) | gzip -c > $(APP_EXTRAS_DIR)/alacritty-msg.1.gz
	@scdoc < $(MANPAGE-CONFIG) | gzip -c > $(APP_EXTRAS_DIR)/alacritty.5.gz
	@scdoc < $(MANPAGE-CONFIG-BINDINGS) | gzip -c > $(APP_EXTRAS_DIR)/alacritty-bindings.5.gz
	@tic -x -o $(APP_EXTRAS_DIR) $(TERMINFO) 2>/dev/null || tic -o $(APP_EXTRAS_DIR) $(TERMINFO)
	@cp -fRp $(APP_TEMPLATE) $(APP_DIR)
	@cp -fp $(APP_BINARY) $(APP_BINARY_DIR)
	@cp -fp $(COMPLETIONS) $(APP_COMPLETIONS_DIR)
	@touch -r "$(APP_BINARY)" "$(APP_DIR)/$(APP_NAME)"
	@codesign --remove-signature "$(APP_DIR)/$(APP_NAME)"
	@codesign --force --deep --sign - "$(APP_DIR)/$(APP_NAME)"
	@echo "Created '$(APP_NAME)' in '$(APP_DIR)'"

copy-app-local:
	@mkdir -p $(LOCAL_TARGET_DIR)
	@cp -fRp "$(APP_DIR)/$(APP_NAME)" "$(LOCAL_TARGET_DIR)/"
	@echo "Copied '$(APP_NAME)' to '$(LOCAL_TARGET_DIR)/$(APP_NAME)'"

dmg: app ## Create an Alacritty.dmg
	@echo "Packing disk image..."
	@ln -sf /Applications $(DMG_DIR)/Applications
	@hdiutil create $(DMG_DIR)/$(DMG_NAME) \
		-volname "Alacritty" \
		-fs HFS+ \
		-srcfolder $(APP_DIR) \
		-ov -format UDZO
	@mkdir -p $(LOCAL_TARGET_DIR)
	@cp -fp "$(DMG_DIR)/$(DMG_NAME)" "$(LOCAL_TARGET_DIR)/"
	@echo "Packed and copied '$(DMG_NAME)' to '$(LOCAL_TARGET_DIR)/$(DMG_NAME)'"

install: dmg ## Mount disk image
	@open $(DMG_DIR)/$(DMG_NAME)

.PHONY: all help fix-config app app-universal build-app build-app-universal assemble-app copy-app-local binary binary-universal clean dmg install

clean: ## Remove all build artifacts
	@cargo clean
