# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# @ AI Context: Modular .zshrc that sources components from .zsh.d/
# This file is symlinked by Stow to ~/.zshrc

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

DISABLE_UNTRACKED_FILES_DIRTY="true"
HIST_STAMPS="dd/mm/yyyy"

plugins=(
    git
    colorize
    cp
    safe-paste
    bgnotify
    F-Sy-H
    zsh-autosuggestions
    history-substring-search
    zsh-npm-scripts-autocomplete
    emoji-clock
    colored-man-pages
    ssh-agent
    python
    pipenv
    zsh-nvm
)

source $ZSH/oh-my-zsh.sh

# Preferred editor
if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR='vim'
else
    export EDITOR='nvim'
fi

# Load modular configs
[[ -f ~/.zsh.d/env.zsh ]] && source ~/.zsh.d/env.zsh
[[ -f ~/.zsh.d/functions.zsh ]] && source ~/.zsh.d/functions.zsh
[[ -f ~/.zsh.d/aliases.zsh ]] && source ~/.zsh.d/aliases.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
source ~/.oh-my-zsh/custom/plugins/auto-ls.zsh

# Initialize zsh completions
autoload -Uz compinit
compinit

# Initialize zoxide (must be last)
export _ZO_DOCTOR=0
eval "$(zoxide init zsh)"
