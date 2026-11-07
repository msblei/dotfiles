#!/usr/bin/env bash
# Restore this setup on a Mac. Idempotent: safe to re-run.
#   git clone git@github.com:msblei/dotfiles.git ~/dotfiles && ~/dotfiles/install.sh
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
PACKAGES=(ghostty tmux fish git zsh gh claude codex nvim)

step() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }

step "Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
brew bundle --file="$DIR/Brewfile"

step "Symlinks (stow)"
# Parent dirs must exist as real directories, otherwise stow would symlink the
# whole directory into the repo and app state would land in git.
mkdir -p "$HOME/.config/ghostty" "$HOME/.config/fish" "$HOME/.config/git" \
         "$HOME/.config/gh" "$HOME/.claude" "$HOME/.codex"
stow -v -d "$DIR" -t "$HOME" --restow "${PACKAGES[@]}"

step "Local, untracked files (created only if missing)"
seed() { # seed <source> <target> [mode]
  if [ -e "$2" ]; then echo "keep   $2"; else cp "$1" "$2"; [ -n "${3:-}" ] && chmod "$3" "$2"; echo "create $2  <- $(basename "$1")"; fi
}
seed "$DIR/templates/claude-settings.json"   "$HOME/.claude/settings.json"
seed "$DIR/templates/codex-config.toml"      "$HOME/.codex/config.toml"
seed "$DIR/templates/notify.env.example"     "$HOME/.config/notify.env" 600
seed "$DIR/templates/gitconfig.local.example" "$HOME/.gitconfig.local"

step "Shell"
if [ "$SHELL" != "$(command -v fish)" ]; then
  echo "To make fish the login shell:"
  echo "  echo $(command -v fish) | sudo tee -a /etc/shells && chsh -s $(command -v fish)"
fi

cat <<MSG

Done. Remaining manual steps:
  1. Put your ntfy topic in ~/.config/notify.env and your email in ~/.gitconfig.local
  2. Run 'nvim' once so vim.pack installs the plugins pinned in nvim-pack-lock.json
  3. Run 'gh auth login', 'claude', and 'codex' once to authenticate
MSG
