# dotfiles

```sh
git clone git@github.com:r0mankon/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./setup.sh
```

`setup.sh` is the unified entrypoint. It detects OS (macOS/Linux) and runs the right path. Use `DRY_RUN=1 ./setup.sh` to preview.

## Layout

- `setup.sh` — interactive wizard, dry-run aware, tracks state.
- `setup.private.sh` — secrets / private overlays (separate repo).
- `setup.claude-dual.sh` — install `claude-work` dual-config wrapper.
- `stow-all.sh` — symlink every `stow/*/` package into `$HOME` via GNU Stow.
- `stow/` — packages: `zsh`, `git`, `ghostty`, `lazygit`, `swiftbar`, `bin`, etc.
- `brew.txt`, `apt.txt` — package manifests.
- `NOGIT/` — globally git-ignored scratch / backups.

## Manual extras

### Fonts

- **Editor**: Meslo / Menlo, JetBrains Mono, Cascadia Code
- **Terminal**: [Meslo Nerd Font (P10k-patched)](https://github.com/romkatv/powerlevel10k/blob/master/font.md), Cascadia Mono PL

### Linux deb / AppImage

Some packages aren't in apt and must be downloaded manually from upstream.

### macOS — NTFS write support

```sh
brew tap gromgit/homebrew-fuse
brew install ntfs-3g-mac
```

Then disable SIP in recovery, replace `mount_ntfs`, re-enable SIP:

```sh
csrutil disable                                          # in recovery
sudo mount -uw /
sudo mv /sbin/mount_ntfs /sbin/mount_ntfs.original
sudo ln -s /usr/local/sbin/mount_ntfs /sbin/mount_ntfs
csrutil enable                                           # in recovery
```

## Troubleshooting

- **`stow` conflict**: target file already exists. Remove or back up, re-run.
- **zoxide warning**: zoxide init must be last line in `.zshrc`. `_ZO_DOCTOR=0` suppresses it for Claude Code Bash tool which prepends `cd`.
- **`compinit` insecure dirs**: `compaudit | xargs chmod g-w,o-w`.
- **Missing completions**: drop files in `~/.zsh/completions/` (already on `$FPATH`).

## Caution

- `~/.config/user-dirs.dirs` — don't blindly delete on Linux; it defines XDG user dirs.
