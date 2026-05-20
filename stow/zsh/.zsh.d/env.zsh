# @ AI Context: Modular environment variables.
# Integrated from env and env.mac.zsh.

# Path cleanup - prevent duplicates
typeset -U path

# Homebrew for Mac
if [[ "$OSTYPE" == "darwin"* ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    export HOMEBREW_UPDATE_PREINSTALL=0
fi

path=(
    "$HOME/.bin"
    "$HOME/.local/bin"
    "$HOME/bin"
    "/opt/local/bin"
    "/opt/local/sbin"
    "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
    $path
)

export PATH

# Android & Java
export ANDROID_HOME="$HOME/.bubblewrap/android_sdk"
export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"

path=(
    "$ANDROID_HOME/emulator"
    "$ANDROID_HOME/tools"
    "$ANDROID_HOME/tools/bin"
    "$ANDROID_HOME/platform-tools"
    $path
)

export NVM_DIR="$HOME/.nvm"

# Fallback Node path for non-interactive shells (like Claude hooks)
if [ -d "$NVM_DIR/versions/node" ]; then
    fallback_node_bin=$(ls -td "$NVM_DIR/versions/node"/v* 2>/dev/null | head -1)/bin
    if [ -d "$fallback_node_bin" ]; then
        path=("$fallback_node_bin" $path)
    fi
fi

# Deno
[ -f "$HOME/.deno/env" ] && . "$HOME/.deno/env"
if [[ ":$FPATH:" != *":$HOME/.zsh/completions:"* ]]; then
    export FPATH="$HOME/.zsh/completions:$FPATH"
fi

# ---------- fzf ----------
# Default options: dark theme, inline info, height 60%, borders, preview pane right.
export FZF_DEFAULT_OPTS="
  --height 60%
  --layout=reverse
  --border=rounded
  --info=inline
  --prompt='❯ '
  --pointer='▶'
  --marker='✓'
  --color=fg:#c0caf5,bg:-1,hl:#7aa2f7,fg+:#c0caf5,bg+:#3b4261,hl+:#7dcfff
  --color=info:#7aa2f7,prompt:#7dcfff,pointer:#bb9af7,marker:#9ece6a,spinner:#9ece6a,header:#9ece6a
  --bind='ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --bind='ctrl-/:toggle-preview'
  --bind='ctrl-j:preview-down,ctrl-k:preview-up'
  --bind='ctrl-f:preview-page-down,ctrl-b:preview-page-up'
  --bind='alt-w:toggle-preview-wrap'
  --bind='?:change-preview-window(right,80%|right,40%|down,50%|hidden|right,60%)'
"

# Use fd (already installed) for file/dir search — respects .gitignore, faster than find.
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"
fi

# Previews — bat for files, eza for dirs.
if command -v bat >/dev/null 2>&1; then
  export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 {}' --preview-window=right:60%:wrap"
fi
if command -v eza >/dev/null 2>&1; then
  export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always --icons {}' --preview-window=right:60%"
fi

export FZF_CTRL_R_OPTS="--preview 'echo {2..}' --preview-window=down:3:wrap --bind='ctrl-/:toggle-preview'"

# fzf-tab — show preview in completion, no group sep, accept on enter
zstyle ':fzf-tab:complete:cd:*'        fzf-preview 'eza --tree --level=2 --color=always --icons $realpath 2>/dev/null'
zstyle ':fzf-tab:complete:z:*'         fzf-preview 'eza --tree --level=2 --color=always --icons $realpath 2>/dev/null'
zstyle ':fzf-tab:complete:*:*'         fzf-preview '
  if [[ -d $realpath ]]; then eza --tree --level=2 --color=always --icons $realpath
  elif [[ -f $realpath ]]; then bat --color=always --style=numbers --line-range=:200 $realpath 2>/dev/null
  else echo $word
  fi'
zstyle ':fzf-tab:*' fzf-flags '--height=60%' '--layout=reverse' '--border=rounded'
zstyle ':fzf-tab:*' switch-group '<' '>'

# forgit options
export FORGIT_FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS"
