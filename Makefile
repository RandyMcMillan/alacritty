TARGET = gnostr

ASSETS_DIR = extra
RELEASE_DIR = target/release
MANPAGE = $(ASSETS_DIR)/man/alacritty.1.scd
MANPAGE-MSG = $(ASSETS_DIR)/man/alacritty-msg.1.scd
MANPAGE-CONFIG = $(ASSETS_DIR)/man/alacritty.5.scd
MANPAGE-CONFIG-BINDINGS = $(ASSETS_DIR)/man/alacritty-bindings.5.scd
TERMINFO = $(ASSETS_DIR)/alacritty.info
COMPLETIONS_DIR = $(ASSETS_DIR)/completions
COMPLETIONS = $(COMPLETIONS_DIR)/_alacritty \
	$(COMPLETIONS_DIR)/alacritty.bash \
	$(COMPLETIONS_DIR)/alacritty.fish

APP_NAME = gnostr.app
APP_TEMPLATE = $(ASSETS_DIR)/osx/$(APP_NAME)
APP_DIR = $(RELEASE_DIR)/osx
APP_BINARY = $(RELEASE_DIR)/$(TARGET)
APP_BINARY_DIR = $(APP_DIR)/$(APP_NAME)/Contents/MacOS
APP_EXTRAS_DIR = $(APP_DIR)/$(APP_NAME)/Contents/Resources
APP_COMPLETIONS_DIR = $(APP_EXTRAS_DIR)/completions

DMG_NAME = gnostr.dmg
DMG_DIR = $(RELEASE_DIR)/osx

COMMIT_HASH=$(shell test -z "$(shell git status --porcelain)" \
    && echo "$(shell git rev-parse --short HEAD)" \
    || echo "$(shell git rev-parse --short HEAD)-dirty")
export COMMIT_HASH

vpath $(TARGET) $(RELEASE_DIR)
vpath $(APP_NAME) $(APP_DIR)
vpath $(DMG_NAME) $(APP_DIR)

help: ### Print this help message
	@awk 'BEGIN {FS = ":.*?###"} /^[a-zA-Z_-]+:.*?###/ {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
#@grep -E '^[a-zA-Z._-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

all: binary app ### make binary universal-bin

binary: $(TARGET)-native ### Build binary
universal-bin: $(TARGET)-universal ### Build universal-bin
$(TARGET)-native: ### $(TARGET-native)
	MACOSX_DEPLOYMENT_TARGET="10.11" cargo build --release
$(TARGET)-universal:
	MACOSX_DEPLOYMENT_TARGET="10.11" cargo build --release --target=x86_64-apple-darwin || rustup target add x86_64-apple-darwin
	MACOSX_DEPLOYMENT_TARGET="10.11" cargo build --release --target=aarch64-apple-darwin || rustup target add aarch64-apple-darwin
	@lipo target/{x86_64,aarch64}-apple-darwin/release/$(TARGET) -create -output $(APP_BINARY)

app: $(APP_NAME)-native ### Create a gnostr.app
universal-app: $(APP_NAME)-universal ### Create a universal gnostr.app
$(APP_NAME)-%: $(TARGET)-%
	@mkdir -p $(APP_BINARY_DIR)
	@mkdir -p $(APP_EXTRAS_DIR)
	@mkdir -p $(APP_COMPLETIONS_DIR)
	@scdoc < $(MANPAGE) | gzip -c > $(APP_EXTRAS_DIR)/alacritty.1.gz
	@scdoc < $(MANPAGE-MSG) | gzip -c > $(APP_EXTRAS_DIR)/alacritty-msg.1.gz
	@scdoc < $(MANPAGE-CONFIG) | gzip -c > $(APP_EXTRAS_DIR)/alacritty.5.gz
	@scdoc < $(MANPAGE-CONFIG-BINDINGS) | gzip -c > $(APP_EXTRAS_DIR)/alacritty-bindings.5.gz
	@tic -xe alacritty,alacritty-direct -o $(APP_EXTRAS_DIR) $(TERMINFO)
	@cp -fRp $(APP_TEMPLATE) $(APP_DIR)
	@cp -fp $(APP_BINARY) $(APP_BINARY_DIR)
	@cp -fp $(COMPLETIONS) $(APP_COMPLETIONS_DIR)
	@touch -r "$(APP_BINARY)" "$(APP_DIR)/$(APP_NAME)"
	@codesign --remove-signature "$(APP_DIR)/$(APP_NAME)"
	@codesign --force --deep --sign - "$(APP_DIR)/$(APP_NAME)"
	@echo "Created '$(APP_NAME)' in '$(APP_DIR)'"

dmg: $(DMG_NAME)-native ### Create a gnostr.dmg
dmg-universal: $(DMG_NAME)-universal ### Create a universal gnostr.dmg
$(DMG_NAME)-%: $(APP_NAME)-%
	##TODO set Finder icon when mounted
	@echo "Packing disk image..."
	echo $(COMMIT_HASH)
	@rm -rf $(APP_DIR)/*.git
	@git clone --bare --recursive --depth 1 . $(APP_DIR)/$(COMMIT_HASH).git
	@cp -fp  $(ASSETS_DIR)/osx/.VolumeIcon.icns $(APP_DIR)/.VolumeIcon.icns
	sips -i $(APP_DIR)/.VolumeIcon.icns
	DeRez -only icns $(APP_DIR)/.VolumeIcon.icns > icns.rsrc
	@ln -sf /Applications $(APP_DIR)/Applications
	hdiutil create \
		-noatomic \
		-volname gnostr-$(COMMIT_HASH) \
		-fs HFS+ \
		-srcfolder ./$(APP_DIR) \
		-ov -format UDZO \
		gnostr.dmg
	Rez -append icns.rsrc -o gnostr.dmg
	SetFile -c icnC $(APP_DIR)/.VolumeIcon.icns
	SetFile -a C gnostr.dmg
	@echo "Packing disk image..."
	@echo "Packed '$(APP_NAME)' in '$(APP_DIR)'"

install: $(INSTALL)-native ###        open gnostr.dmg
install-universal: $(INSTALL)-native ###      open universal gnostr.dmg
$(INSTALL)-%: $(DMG_NAME)-%
	@open $(DMG_NAME)

.PHONY: app binary clean dmg install $(TARGET) $(TARGET)-universal

clean: ## Remove all build artifacts
	@cargo clean
