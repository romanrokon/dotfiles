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
