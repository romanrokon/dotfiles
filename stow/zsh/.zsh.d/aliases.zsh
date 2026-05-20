alias cd='z'
[ -d /Volumes/Work/projects ] && alias pro='cd /Volumes/Work/projects'
alias tree='eza --tree'
alias find='fd --'
alias grep='rg'
alias ls='eza --icons --group-directories-first'
alias ll='ls -lh --octal-permissions --git'
alias la='ll -a'
alias lr='ll -R'
alias trash='trash -s -v' # macOS 15.0 addition, moves to users trash, stop on error, verbose
alias rm='trash -s -v' # always use trash for rm
alias cp='cp -iv'
alias mv='mv -iv'
alias vim='nvim'
alias cal='gcal --starting-day=1'
alias weather='curl v2.wttr.in'
alias ncu='npx npm-check -u --format group'
alias tgpt="terminalgpt"
alias lg='lazygit'

[ -x /Applications/Tailscale.app/Contents/MacOS/Tailscale ] && \
  alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

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
