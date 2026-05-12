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
load-nvmrc() {
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    # Load NVM if we find an .nvmrc and it hasn't been loaded yet
    if ! command -v nvm &> /dev/null; then
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
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
