all: init stow

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
		zsh

stow:
	cd stows/ && stow --target "${HOME}" *

default-shell:
	sudo chsh -s "$(shell which zsh)" "${USER}"

unstow:
	cd stows/ && stow --delete --target "${HOME}" *

