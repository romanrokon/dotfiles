# @ AI Context: Modular functions and specialized logic.
# These will be sourced by .zshrc via stow/zsh/.zsh.d/functions.zsh

# auto-ls settings
auto-ls-ll() {
    ll
}

auto-ls-git() {
  test -e ".git/" && onefetch --no-color-palette
}

AUTO_LS_COMMANDS=(ll git)

# Lazy-load NVM for better startup performance
# @ AI Context: These wrappers are replaced by the real NVM script when called.
nvm() {
    unset -f nvm node npm pnpm yarn
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm "$@"
}

node() {
    unset -f nvm node npm pnpm yarn
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    node "$@"
}

npm() {
    unset -f nvm node npm pnpm yarn
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    npm "$@"
}

pnpm() {
    unset -f nvm node npm pnpm yarn
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    pnpm "$@"
}

yarn() {
    unset -f nvm node npm pnpm yarn
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    yarn "$@"
}

# NVM auto-use logic
autoload -U add-zsh-hook

# @ AI Context: Automatically loads and switches NVM version when an .nvmrc is found.
# This "wakes up" the lazy-loaded NVM on demand.
load-nvmrc() {
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    # Force load NVM if we find an .nvmrc and it's currently lazy-loaded
    if [ "$(whence -w nvm)" = "nvm: function" ]; then
        # Check if it's our lazy-load wrapper by seeing if it's already "real"
        # Since we use 'unset -f', once loaded it becomes a different function or command.
        # But a safer way is to just check if the real script was sourced.
        if ! [ -n "$NVM_BIN" ]; then
             unset -f nvm node npm pnpm yarn
             [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        fi
    fi

    local nvmrc_node_version
    nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && command -v nvm &> /dev/null && [ "$(nvm version)" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}

add-zsh-hook chpwd load-nvmrc
# Run once on startup in case we start in a directory with .nvmrc
load-nvmrc
