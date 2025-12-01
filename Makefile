all: init stow init-local default-shell

init:
	sudo apt update \
	&& sudo apt install --yes \
		curl \
		git \
		fzf \
		jq \
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

default-shell:
	sudo chsh -s "$(shell which zsh)" "${USER}" && zsh

unstow:
	cd stows/ && stow --delete --target "${HOME}" *

