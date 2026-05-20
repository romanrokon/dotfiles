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
# We unset existing aliases first to prevent Zsh parse errors.
unalias nvm node npm pnpm yarn 2>/dev/null

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
    # User prefers pnpm
    pnpm "$@"
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

# @ AI Context: Gemini Chat Workspace Command
# Usage: pa | ga | gemini-chat
# Sets up a workspace and starts Gemini in Sandbox mode.
gemini-chat() {
    local workspace="$HOME/.gemini-chat"
    mkdir -p "$workspace"
    
    cd "$workspace" || return

    # Default to Sandbox mode for safety during research/chat
    gemini --sandbox --skip-trust "$@"
}

alias pa='gemini-chat'

# @ AI Context: Automate worktree creation and sync globally ignored files
gw() {
    if [ -z "$1" ]; then
        echo "Usage: gw <name>"
        return 1
    fi
    local wt_name="$1"
    
    # Create the branch and worktree
    git worktree add -b "$wt_name" "$wt_name"
    local exit_code=$?
    
    if [ $exit_code -eq 0 ] && [ -f "$HOME/.gitignore_global" ]; then
        echo "Syncing globally ignored files to the new worktree..."
        while IFS= read -r item || [ -n "$item" ]; do
            # Skip comments and empty lines
            [[ -z "$item" || "$item" == \#* ]] && continue
            
            # Remove trailing slash to handle directories correctly with -e
            local target="${item%/}"
            
            # Copy if it exists in the current repo
            if [ -e "$target" ]; then
                echo "  -> Copying $target"
                cp -R "$target" "$wt_name/"
            fi
        done < "$HOME/.gitignore_global"
    fi
    return $exit_code
}

alias git-worktree='gw'

# ---------- fzf widgets ----------
# fkill: pick process(es) to kill — shows pid/cpu/mem/name, preview shows full info
fkill() {
  local pids sig
  sig=${1:-15}  # default SIGTERM; pass 9 for SIGKILL
  pids=$(ps -Ao pid=,pcpu=,pmem=,rss=,comm= | \
    awk '{
      pid=$1; cpu=$2; mem=$3; rss=$4;
      cmd=""; for(i=5;i<=NF;i++) cmd=cmd" "$i;
      n=split(cmd,p,"/"); name=p[n];
      printf "%-7s %5s%% %5s%% %7.0fMB  %s\n", pid, cpu, mem, rss/1024, substr(name,1,40)
    }' | sort -k2 -rn | \
    fzf --multi --header="kill -$sig  PID  %CPU  %MEM      RSS  NAME" \
        --preview 'ps -o pid,user,pcpu,pmem,rss,etime,start,command -p {1} 2>/dev/null' \
        --preview-window=down:6:wrap | \
    awk '{print $1}')
  [ -n "$pids" ] && echo "$pids" | xargs kill -"$sig" && echo "✓ killed: $(echo $pids | tr '\n' ' ')"
}

# fbr: pick git branch to checkout (local + remote)
fbr() {
  local branch
  branch=$(git branch --all --color=always | grep -v HEAD |
    fzf --ansi --header="checkout branch" --preview "git log --color=always --oneline -20 \$(echo {} | sed 's/.* //' | sed 's|remotes/[^/]*/||')") || return
  branch=$(echo "$branch" | sed 's/.* //' | sed 's|remotes/[^/]*/||')
  git checkout "$branch"
}

# fco: pick commit to checkout / cherry-pick / etc
fco() {
  local commit
  commit=$(git log --color=always --pretty=oneline --abbrev-commit --reverse |
    fzf --ansi --tac --no-sort --header="checkout commit" --preview 'git show --color=always {1}') || return
  git checkout "$(echo "$commit" | awk '{print $1}')"
}

# fssh: pick host from ~/.ssh/config (+ private config.local) and connect
fssh() {
  local host
  host=$(awk '/^Host / && $2 !~ /\*/ {print $2}' ~/.ssh/config ~/.ssh/config.local 2>/dev/null | sort -u |
    fzf --header="ssh to host" --preview "grep -A 5 '^Host {}\$' ~/.ssh/config ~/.ssh/config.local 2>/dev/null") || return
  ssh "$host"
}

# fnpm: pick script from package.json and run via pnpm
fnpm() {
  [ ! -f package.json ] && echo "no package.json here" && return 1
  local script
  script=$(jq -r '.scripts | to_entries[] | "\(.key)\t\(.value)"' package.json |
    fzf --header="pnpm run" --preview 'echo {}' | awk '{print $1}') || return
  pnpm run "$script"
}

# fdocker: pick container, run command (default: exec sh)
fdocker() {
  local container action
  container=$(docker ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' |
    fzf --header="container action" --preview 'docker stats --no-stream {1} 2>/dev/null' | awk '{print $1}') || return
  action=$(printf "exec sh\nexec bash\nlogs -f\nrestart\nstop\nstats" |
    fzf --header="action on $container") || return
  docker $action "$container"
}

# fbrew: pick brew package to upgrade or uninstall
fbrew() {
  local pkg action
  pkg=$(brew list | fzf --header="brew action" --preview 'brew info {}') || return
  action=$(printf "upgrade\nuninstall\ninfo\nreinstall" |
    fzf --header="action on $pkg") || return
  brew $action "$pkg"
}

# frm: fuzzy-pick files in cwd and trash (multi-select)
frm() {
  local files
  files=$(fd --type f --hidden --exclude .git | fzf --multi --header="trash files (TAB to multi-select)" \
    --preview 'bat --color=always --style=numbers --line-range=:200 {}') || return
  echo "$files" | xargs -I{} trash "{}"
}

# fkube: pick kubectl context
fkube() {
  command -v kubectl >/dev/null || { echo "kubectl not installed"; return 1; }
  local ctx
  ctx=$(kubectl config get-contexts -o name | fzf --header="kubectl context") || return
  kubectl config use-context "$ctx"
}
