all: init stow init-local init-wsl-tools default-shell

init:
	sudo apt update \
	&& sudo apt install --yes \
		curl \
		fd-find \
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

init-wsl-tools:
	@ [ -n "$$WSL_DISTRO_NAME" ] && sudo apt-get update && sudo apt-get install -y wslu || echo "Skipping: Not a WSL environment."

default-shell:
	sudo chsh -s "$(shell which zsh)" "${USER}" && zsh

stow-claude:
	cd stows-optional/ && stow --target "${HOME}" claude

unstow:
	cd stows/ && stow --delete --target "${HOME}" *

unstow-claude:
	cd stows-optional/ && stow --delete --target "${HOME}" claude

stow-gemini:
	cd stows-optional/ && stow --target "${HOME}" gemini

unstow-gemini:
	cd stows-optional/ && stow --delete --target "${HOME}" gemini

install-gemini:
	curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - \
	&& sudo apt-get install -y nodejs \
	&& sudo npm install -g @google/gemini-cli

