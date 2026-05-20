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
    fzf-tab
)

source "$ZSH/oh-my-zsh.sh"

# fzf shell integration (Ctrl+T, Ctrl+R, Alt+C, ** trigger)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
command -v fzf >/dev/null 2>&1 && eval "$(fzf --zsh)" 2>/dev/null

# fzf-git.sh — adds <CTRL+G CTRL+...> bindings for git branches/files/commits/stashes/tags
[ -f ~/.fzf-git/fzf-git.sh ] && source ~/.fzf-git/fzf-git.sh

# forgit — interactive git ops (ga, glo, gd, gco, gss, gclean, etc.)
# brew install puts it at /opt/homebrew/opt/forgit; the setup wizard also clones
# a copy to ~/.forgit so non-brew machines (Linux) work the same way.
for _f in \
  /opt/homebrew/opt/forgit/share/forgit/forgit.plugin.zsh \
  /home/linuxbrew/.linuxbrew/opt/forgit/share/forgit/forgit.plugin.zsh \
  "$HOME/.forgit/forgit.plugin.zsh"
do
  [ -f "$_f" ] && source "$_f" && break
done
unset _f

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
