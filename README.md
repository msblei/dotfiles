# dotfiles

My macOS dev setup: **Ghostty** → **fish** → **tmux** → **Neovim**, plus **Claude Code** and
**Codex** with a shared notification hook (terminal bell after 10 s idle, phone push via
[ntfy](https://ntfy.sh) after 60 s, cancelled by any activity).

Managed with [GNU Stow](https://www.gnu.org/software/stow/): every top-level package directory
mirrors `$HOME`, and `stow <pkg>` symlinks its files into place. Edit the files where they
live (`~/.tmux.conf`, `~/.config/nvim/…`), then commit in `~/dotfiles`.

## Restore on a fresh Mac

```sh
git clone git@github.com:msblei/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

`install.sh` installs Homebrew + the `Brewfile`, stows every package, and seeds the local
files below if they don't exist yet. Then fill in `~/.config/notify.env` and
`~/.gitconfig.local`, and open `nvim` once so `vim.pack` installs the pinned plugins.

## Layout

| package   | links into                                   | notes |
|-----------|----------------------------------------------|-------|
| `ghostty` | `~/.config/ghostty/config`                   | 3 lines; `command` is the Apple-Silicon brew path |
| `tmux`    | `~/.tmux.conf`                               | vi copy mode, bell passthrough for the notify hook |
| `fish`    | `~/.config/fish/config.fish`                 | `fish_variables` is machine state, not tracked |
| `git`     | `~/.gitconfig`, `~/.config/git/ignore`       | email comes from untracked `~/.gitconfig.local` |
| `zsh`     | `~/.zshenv`, `~/.zprofile`                   | brew shellenv + `~/.local/bin` for the non-fish case |
| `gh`      | `~/.config/gh/config.yml`                    | `hosts.yml` (auth) is not tracked |
| `claude`  | `~/.claude/notify.sh`                        | the shared hook script |
| `codex`   | `~/.codex/hooks.json`                        | calls the same `~/.claude/notify.sh` |
| `nvim`    | `~/.config/nvim/`                            | vendored kickstart.nvim + `lua/custom/plugins/` |

## Copied, not linked

Two files are rewritten by their apps with machine-specific or private content, so they are
**not** symlinked. The repo keeps a sanitized template; `install.sh` copies it only when the
real file is missing.

| template                          | target                     | stripped |
|-----------------------------------|----------------------------|----------|
| `templates/claude-settings.json`  | `~/.claude/settings.json`  | `autoMode` (per-project allow rules / environment profile) |
| `templates/codex-config.toml`     | `~/.codex/config.toml`     | `[projects.*]` trust, `[marketplaces]`, `[plugins]`, `[mcp_servers]`, `[hooks.state]` |

After changing hooks, model, theme, etc. in the live file, run `bin/sync-templates` and commit.

## Deliberately untracked

- `~/.config/notify.env` — the ntfy topic. Anyone who knows it can read your notifications and
  push to your phone. `templates/notify.env.example` shows the format.
- `~/.gitconfig.local` — email address.
- `~/.codex/auth.json`, `~/.config/gh/hosts.yml`, `~/.ssh/` — credentials.
- `~/.claude/{projects,history.jsonl,…}`, `~/.codex/{sessions,*.sqlite,…}` — transcripts and state.
- `~/.local/share/nvim`, `~/.local/state/nvim` — installed plugins (restored from the lockfile) and shada/undo.
