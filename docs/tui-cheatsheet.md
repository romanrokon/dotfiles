# TUI Cheatsheet

Reference for the custom commands, widgets, and tools wired up in this setup.

## fzf widgets (custom)

| Command | What |
|---|---|
| `fkill [sig]` | Pick process(es) to kill. Multi-select with `TAB`. Default `SIGTERM`; pass `9` for `SIGKILL`. Preview shows full process info. |
| `fbr` | Pick git branch (local + remote) → checkout. Preview shows recent log. |
| `fco` | Pick commit → checkout. Preview shows full diff. |
| `fssh` | Pick host from `~/.ssh/config` (+ `config.local`) → connect. |
| `fnpm` | Pick script from `package.json` → run via `pnpm`. |
| `fdocker` | Pick container → `exec sh` / `exec bash` / `logs -f` / `restart` / `stop` / `stats`. |
| `fbrew` | Pick brew package → `upgrade` / `uninstall` / `info` / `reinstall`. |
| `frm` | Multi-pick files in cwd → trash. |
| `fkube` | Pick kubectl context → switch. |

## forgit (interactive git)

Available after the `forgit.plugin.zsh` source line in `.zshrc`.

| Command | What |
|---|---|
| `ga` | Interactive `git add` with diff preview |
| `glo` | fzf log browser |
| `gd` | fzf diff browser |
| `gco` | fzf checkout (file or branch) |
| `gss` | fzf stash picker |
| `gclean` | fzf-pick untracked files to remove |
| `grh` | fzf reset HEAD picker |
| `gcb` | fzf-pick branch to delete |

## Mac thermal / system utils

| Command | Alias | What |
|---|---|---|
| `cooldown` | `cool` | Kill iCloud/Spotlight daemons + purge inactive RAM + show swap holders. Notifies on completion. |
| `cooldown --aggressive` | `coola` | Also restart Slack/Chrome/Arc/Spotify + dev servers (next/vite/tsserver/etc). |
| `cooldown --dry-run` | `coold` | Preview kills without running. |
| `heatlog` | `heat` | Background sampler: temp/fan/mem/swap → CSV + native notifications on threshold breach. |
| `spotlight-off` | `spot-off` | Disable Spotlight indexing + erase index. Raycast unaffected. |
| `spotlight-on` | `spot-on` | Re-enable Spotlight indexing (30–60min rebuild). |
| `pihole-backup` | — | SSH to pihole, pull Teleporter `.zip` to iCloud Drive. Rotates to keep last 8. Scheduled weekly Sunday 03:00. |

## Containers

| Command | What |
|---|---|
| `docker compose -f docker-compose.yml -f docker-compose.arm64.yml up -d` | Bring up the wizardry stack |
| `make-backup` | Postgres dump to `NOGIT/backups/backup_$(date +%Y%m%d_%H%M%S).sql` |
| `make-stop` | Compose stop with arm64 override |
| `orbctl docker migrate` | One-shot import from Docker Desktop |

## Git worktrees

| Command | What |
|---|---|
| `gw <name>` | Create branch + worktree + copy globally-ignored files into it |
| `lg` | Open `lazygit` |

## Navigation

| Command | What |
|---|---|
| `z <part>` | Smart `cd` (zoxide) — fuzzy match recent directories |
| `zi` | Interactive zoxide picker |
| `pro` | `cd /Volumes/Work/projects` (only on machines that have it) |
| `tree` | `eza --tree` (auto-respects `.gitignore` via `tree --git-ignore`) |
| `ll` / `la` / `lr` | `eza` with details / hidden / recursive |

## Search / find / view

| Command | Notes |
|---|---|
| `grep` → `rg` (ripgrep) | Default replacement |
| `find` → `fd --` | Default replacement |
| `cat` for code → `bat` | Syntax highlighting + line numbers (used in fzf previews) |
| `yazi` | Modal terminal file manager |
| `fastfetch` | System info on shell launch |
| `onefetch` | Git repo info on `cd` into a repo |

## Container, fan, downloads (menu bar — macOS)

| Click | Plugin |
|---|---|
| `⬇` / `⬇ N • X MB/s` | **aria2** — current downloads, pause/resume, AriaNg link |
| `💽 N%` | **disk** — per-volume usage, cleanup actions (brew cleanup, docker prune, empty trash, purge RAM) |
| `🛡 Nms` | **pihole** — Tailscale + DNS + admin liveness, open admin, ssh shortcut |
| `🖥 N% N%` | **sysmon** — CPU/RAM/temp/battery, cooldown shortcut |

## Aria2 (downloads)

| Command | What |
|---|---|
| `aria2c <url>` | One-shot CLI download (uses `~/.aria2/aria2.conf`) |
| daemon (auto-start) | Browser extension *Aria2 Explorer* captures all downloads |
| `osascript -e 'quit app "..."'` analog | `launchctl bootout gui/$(id -u)/com.rzman.aria2` |

## Misc

| Command | What |
|---|---|
| `cbonsai -l -i` | Ambient bonsai tree growing in a terminal pane |
| `cmatrix -s` | Matrix rain (any key exits) |
| `tgpt "..."` | Terminal AI chat (terminalgpt) |
| `ga` / `pa` | Gemini chat workspace |
| `cc` | `claude` |
| `ccw` | `claude-work` (separate config dir) |
