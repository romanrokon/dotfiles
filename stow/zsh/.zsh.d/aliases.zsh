# zoxide itself owns `cd` via `zoxide init zsh --cmd cd` in .zshrc — no alias needed.
# `cdi` (interactive zoxide picker) and the bare `cd -` / `cd ..` still work.
[ -d /Volumes/Work/projects ] && alias pro='cd /Volumes/Work/projects'
alias tree='eza --tree'
alias find='fd --'
alias grep='rg'
alias ls='eza --icons --group-directories-first'
alias ll='ls -lh --octal-permissions --git'
alias la='ll -a'
alias lr='ll -R'
# Cross-platform trash. macOS brew 'trash' takes -s -v. Linux trash-cli ships
# 'trash-put' (with -v but no -s). Fall back to real rm if neither is present.
if [[ "$OSTYPE" == "darwin"* ]] && command -v trash >/dev/null 2>&1; then
    alias trash='trash -s -v'
    alias rm='trash -s -v'
elif command -v trash-put >/dev/null 2>&1; then
    alias trash='trash-put -v'
    alias rm='trash-put -v'
fi
# Else (no trash tool): rm stays as system rm — leave alone so users aren't surprised.
alias cp='cp -iv'
alias mv='mv -iv'
# Use nvim when available, fall back to system vim (server profile installs vim only).
command -v nvim >/dev/null 2>&1 && alias vim='nvim'
alias cal='gcal --starting-day=1'
alias weather='curl v2.wttr.in'
# alias ncu='npx ncu -i --format group'
alias ncu='npx npm-check -u --format group'
alias tgpt="terminalgpt"
alias npm=pnpm
alias lg='lazygit'

[ -x /Applications/Tailscale.app/Contents/MacOS/Tailscale ] && \
  alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

# Debian/Ubuntu rename binaries to avoid conflicts — alias back to upstream names
if [[ "$OSTYPE" == "linux"* ]]; then
  command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1 && alias fd='fdfind'
  command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1 && alias bat='batcat'
fi

# Desktop-only aliases — pruned on server profile because they wrap apps that
# aren't installed (Arc browser, Claude/Gemini CLIs, npm-check, etc.) or are
# macOS-specific (Spotlight). cool/heat are kept because the underlying scripts
# dispatch to Linux siblings cleanly.
if [[ "${SETUP_PROFILE:-desktop}" == "server" ]]; then
    for _a in cc claude-work ccw arc make-backup make-stop spot-off spot-on ncu tgpt; do
        unalias "$_a" 2>/dev/null
    done
    unset _a
fi

auto-ls-ll() {
    ll
}

auto-ls-git() {
  test -e ".git/" && onefetch --no-color-palette
}

AUTO_LS_COMMANDS=(ll git)

arc() {
  open -a "Arc" "$@"
}

alias cc=claude
alias claude-work="CLAUDE_CONFIG_DIR=~/.claude-work claude"
alias ccw=claude-work

# Docker & Backup
alias make-backup="docker-compose -f docker-compose.yml -f docker-compose.arm64.yml exec -T db pg_dump -U app app > NOGIT/backups/backup_\$(date +%Y%m%d_%H%M%S).sql"
alias make-stop="docker-compose -f docker-compose.yml -f docker-compose.arm64.yml stop"

# Mac thermal utils (canonical in stow/bin/.bin/, symlinked to ~/.bin/)
alias cool='cooldown'
alias coola='cooldown --aggressive'
alias coold='cooldown --dry-run'
alias heat='heatlog'

# Spotlight toggle (Raycast unaffected)
alias spot-off='spotlight-off'
alias spot-on='spotlight-on'
