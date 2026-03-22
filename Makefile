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

