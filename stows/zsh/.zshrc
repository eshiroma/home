autoload -U +X bashcompinit && bashcompinit
autoload -U promptinit && promptinit
autoload -U colors && colors
autoload -U select-word-style
select-word-style bash

# Minimal color prompt.
PROFILE_COLOR=green
[ -f "${HOME}/.localrc" ] && source "${HOME}/.localrc"
export FG_PROMPT_COLOR=$PROFILE_COLOR
export BG_PROMPT_COLOR=black
export PS1="%{$fg[$FG_PROMPT_COLOR]$bg[$BG_PROMPT_COLOR]%}$reset_color$fg[$FG_PROMPT_COLOR]$bg[$BG_PROMPT_COLOR]%m$reset_color:$fg[$FG_PROMPT_COLOR]$bg[$BG_PROMPT_COLOR]%~/$reset_color
$ "

eval $(dircolors -b)

# Setting up history.
export HISTSIZE=100000000
export SAVEHIST=100000000
export HISTFILE=~/.history
setopt append_history
setopt extended_history
setopt hist_ignore_dups
setopt hist_find_no_dups

setopt INTERACTIVECOMMENTS

export PATH=$PATH:~/scripts
export PATH=$PATH:~/.local/bin
export PATH=$PATH:~/go/bin

# fzf
source /usr/share/doc/fzf/examples/key-bindings.zsh
source /usr/share/doc/fzf/examples/completion.zsh

export TERM=xterm-256color
export FZF_TMUX=1
export FZF_CTRL_T_COMMAND="command ag '' -l"

