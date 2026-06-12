# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# @ AI Context: Modular .zshrc that sources components from .zsh.d/
# This file is symlinked by Stow to ~/.zshrc

# @ AI Context: Active profile (written by setup wizard step 02).
# 'server' = headless SBC — skip GUI/desktop/AI/heavy-plugin bits below.
# Anything else (incl. missing file) = desktop behavior.
[ -f ~/.config/setup-profile ] && export SETUP_PROFILE="$(cat ~/.config/setup-profile)"
SETUP_PROFILE="${SETUP_PROFILE:-desktop}"

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

DISABLE_UNTRACKED_FILES_DIRTY="true"
HIST_STAMPS="dd/mm/yyyy"

if [[ "$SETUP_PROFILE" == "server" ]]; then
    # Minimal plugin set — fast startup, no GUI desktop notifications, no NVM.
    plugins=(
        git
        colored-man-pages
        ssh-agent
        history-substring-search
        zsh-autosuggestions
        F-Sy-H
        fzf-tab
    )
else
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
fi

source "$ZSH/oh-my-zsh.sh"

# fzf shell integration (Ctrl+T, Ctrl+R, Alt+C, ** trigger).
# fzf >= 0.48 supports `fzf --zsh`; older builds (Debian 12 default = 0.38)
# need the legacy key-bindings + completion scripts sourced directly.
if command -v fzf >/dev/null 2>&1; then
    if fzf --zsh >/dev/null 2>&1; then
        eval "$(fzf --zsh)"
    else
        for _f in \
            /usr/share/doc/fzf/examples/key-bindings.zsh \
            /usr/share/doc/fzf/examples/completion.zsh \
            /usr/share/fzf/key-bindings.zsh \
            /usr/share/fzf/completion.zsh \
            /opt/homebrew/opt/fzf/shell/key-bindings.zsh \
            /opt/homebrew/opt/fzf/shell/completion.zsh
        do
            [ -f "$_f" ] && source "$_f"
        done
        unset _f
    fi
fi
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# fzf-git.sh + forgit — desktop-only (depend on plugin clones skipped on server).
if [[ "$SETUP_PROFILE" != "server" ]]; then
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
fi

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

# Initialize zoxide (must be last). --cmd cd makes zoxide own the `cd` command
# directly (uses `\builtin cd` internally, no alias recursion). Guard so a
# missing binary doesn't crash startup on an SBC without zoxide.
export _ZO_DOCTOR=0
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh --cmd cd)"
