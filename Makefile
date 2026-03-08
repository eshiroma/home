all: init stow init-local init-wsl-tools default-shell

init:
	sudo apt update \
	&& sudo apt install --yes \
		curl \
		git \
		fzf \
		jq \
		keychain \
		make \
		nodejs \
		silversearcher-ag \
		stow \
		tar \
		tmux \
		vim \
		zsh

stow:
	cd stows/ && stow --target "${HOME}" *

init-local:
	[ ! -f "${HOME}/.localrc" ] && cp templates/.localrc "${HOME}/.localrc"

ANDROID_SDK_WSL := $(HOME)/android-sdk
ANDROID_CMDLINE_TOOLS_URL := https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
SDKMANAGER := $(ANDROID_SDK_WSL)/cmdline-tools/latest/bin/sdkmanager

init-wsl-tools:
	@ [ -n "$$WSL_DISTRO_NAME" ] || { echo "Skipping: Not a WSL environment."; exit 0; }
	sudo apt install --yes openjdk-17-jdk linux-tools-generic hwdata
	sudo snap install flutter --classic
	curl -o /tmp/cmdline-tools.zip "$(ANDROID_CMDLINE_TOOLS_URL)"
	mkdir -p $(ANDROID_SDK_WSL)/cmdline-tools
	unzip -q /tmp/cmdline-tools.zip -d /tmp/cmdline-tools-extract
	mv /tmp/cmdline-tools-extract/cmdline-tools $(ANDROID_SDK_WSL)/cmdline-tools/latest
	rm /tmp/cmdline-tools.zip
	yes | $(SDKMANAGER) --sdk_root="$(ANDROID_SDK_WSL)" --licenses
	yes | $(SDKMANAGER) --sdk_root="$(ANDROID_SDK_WSL)" "platform-tools" "build-tools;35.0.0" "platforms;android-35" "platforms;android-36"
	flutter config --android-sdk $(ANDROID_SDK_WSL)

default-shell:
	sudo chsh -s "$(shell which zsh)" "${USER}" && zsh

unstow:
	cd stows/ && stow --delete --target "${HOME}" *

