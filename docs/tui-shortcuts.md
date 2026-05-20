# TUI Shortcuts

Keyboard shortcuts wired up across fzf, fzf-tab, fzf-git, zsh plugins, and the terminal.

## fzf — navigation & preview

Applies inside **every** fzf prompt (`Ctrl+T`, `Ctrl+R`, `Alt+C`, `fkill`, `fbr`, fzf-tab completions, forgit, etc.).

| Keys | Action |
|---|---|
| `Ctrl+N` / `Ctrl+P` | Move down / up in list (only list nav binding) |
| `Ctrl+J` / `Ctrl+K` | Scroll preview down / up by line |
| `Ctrl+F` / `Ctrl+B` | Scroll preview page down / up |
| `Ctrl+/` | Toggle preview pane on/off |
| `Alt+W` | Toggle line wrap in preview |
| `?` | Cycle preview window size: right-80% → right-40% → down-50% → hidden → right-60% |
| `Ctrl+Y` | Copy selection to clipboard, exit |
| `Tab` | Mark selection (multi-select mode) |
| `Enter` | Accept selection |
| `Esc` / `Ctrl+C` | Cancel |

## fzf — global keybindings (anywhere on the command line)

| Keys | Action |
|---|---|
| `Ctrl+T` | Fuzzy file picker → paste path into command line (preview via `bat`) |
| `Ctrl+R` | Fuzzy search command history |
| `Alt+C` | Fuzzy dir picker → `cd` (preview via `eza --tree`) |
| `**` then `Tab` | Explicit fuzzy completion trigger for any command |

## fzf-tab — universal completion

Replaces zsh's native tab completion. Just hit `Tab` after any command + a space.

| Context | Behavior |
|---|---|
| `vim <Tab>` | Fuzzy file picker with `bat` preview |
| `cd <Tab>` | Fuzzy dir picker with `eza --tree` preview |
| `kill <Tab>` | Process picker |
| `git checkout <Tab>` | Branch picker with `git log` preview |
| `ssh <Tab>` | Host picker from `~/.ssh/config` |
| `< / >` | Switch completion group when multiple categories shown |
| `Tab` | Accept current |

## fzf-git.sh

`Ctrl+G` prefix → second key picks resource.

| Keys | Picks |
|---|---|
| `Ctrl+G Ctrl+B` | Git branches |
| `Ctrl+G Ctrl+F` | Modified files |
| `Ctrl+G Ctrl+H` | Commit history |
| `Ctrl+G Ctrl+S` | Stashes |
| `Ctrl+G Ctrl+T` | Tags |
| `Ctrl+G Ctrl+R` | Remotes |

## zsh history-substring-search

| Keys | Action |
|---|---|
| `↑` | Previous match for what you've typed so far |
| `↓` | Next match for what you've typed so far |

## zsh-autosuggestions

| Keys | Action |
|---|---|
| `→` | Accept the entire ghost suggestion |
| `Ctrl+E` | Move to end of line / accept full suggestion |
| `Alt+→` | Accept one word of the suggestion |

## Command-line editing

| Keys | Action |
|---|---|
| `Ctrl+A` | Beginning of line |
| `Ctrl+E` | End of line |
| `Ctrl+W` | Delete word back |
| `Alt+B` / `Alt+F` | Move one word back / forward |
| `Ctrl+U` | Delete to start of line |
| `Ctrl+L` | Clear screen |

## Ghostty (terminal)

| Keys | Action |
|---|---|
| `Cmd+T` | New tab |
| `Cmd+W` | Close tab |
| `Cmd+D` | Split right |
| `Cmd+Shift+D` | Split down |
| `Cmd+[` / `Cmd+]` | Previous / next split |
| `Cmd+Plus` / `Cmd+-` | Font bigger / smaller |
| `Cmd+K` | Clear scrollback |

## Lazygit (custom keybinds covered by its built-in `?` help)

Press `?` inside lazygit to see context-sensitive shortcuts. Highlights:

| Keys | Action |
|---|---|
| `Space` | Stage / unstage current file or hunk |
| `c` | Commit |
| `P` | Push |
| `p` | Pull |
| `R` | Refresh |
| `q` / `Esc` | Quit panel |

## Yazi (file manager)

| Keys | Action |
|---|---|
| `j` / `k` | Down / up |
| `h` / `l` | Parent / open |
| `Space` | Select |
| `y` / `x` / `p` | Yank / cut / paste |
| `d` | Trash |
| `r` | Rename |
| `?` | Help overlay |

## SwiftBar plugin scripts (macOS menubar)

Click the plugin in your menubar — actions are listed in the dropdown. No global keybinds; each plugin has clickable entries.

## Notes

- `Ctrl+J` defaults to `accept` in fzf — overridden here to scroll preview. Use `Enter` to accept.
- `Ctrl+K` defaults to `kill-line` — overridden here to scroll preview up. Use `Ctrl+U` to delete-to-start.
- List nav intentionally limited to `Ctrl+N/P` to free up `Ctrl+J/K` for preview scroll.
