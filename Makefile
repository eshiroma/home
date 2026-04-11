all: init stow init-local init-wsl-tools default-shell

init:
	sudo apt update \
	&& sudo apt install --yes \
		curl \
		fd-find \
		git \
		htop \
		fzf \
		jq \
		keychain \
		make \
		nodejs \
		silversearcher-ag \
		sqlite3 \
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

stow-claude: stow-agents
	cd stows-optional/ && stow --target "${HOME}" claude

unstow:
	cd stows/ && stow --delete --target "${HOME}" *

unstow-claude:
	cd stows-optional/ && stow --delete --target "${HOME}" claude

stow-gemini: stow-agents
	cd stows-optional/ && stow --target "${HOME}" gemini

unstow-gemini:
	cd stows-optional/ && stow --delete --target "${HOME}" gemini

stow-agents:
	cd stows-optional/ && stow --target "${HOME}" agents

unstow-agents:
	cd stows-optional/ && stow --delete --target "${HOME}" agents

# Gemini CLI cannot update itself:
#   ✕ Automatic update failed. Please try updating manually
# To "update manually":
#   sudo npm update -g @google/gemini-cli
install-gemini:
	curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - \
	&& sudo apt-get install -y nodejs \
	&& sudo npm install -g @google/gemini-cli

