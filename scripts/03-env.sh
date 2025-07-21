#!/bin/bash
set -euo pipefail

log()    { echo -e "\033[1;34m==>\033[0m $*"; }
ok()     { echo -e "\033[1;32m✔\033[0m $*"; }
error()  { echo -e "\033[1;31m✘\033[0m $*"; }

# === Directories ===
log "Setting up directories..."
mkdir -p \
  "$HOME/local/bin" \
  "$HOME/local/repo" \
  "$HOME/workspace" \
  "$HOME/.local/bin"
ok "Created local dirs"

# === Dotfiles ===
DOTFILES_REPO="https://github.com/pierrelgol/dotfiles"
DOTFILES_DIR="$HOME/.dotfiles"

if [ -d "$DOTFILES_DIR" ]; then
  log "Dotfiles already cloned, pulling latest..."
  git -C "$DOTFILES_DIR" pull
else
  log "Cloning dotfiles..."
  git clone --depth 1 "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

# === Backup conflicting files ===
log "Checking for conflicting files..."
cd "$HOME"
for file in .bashrc .profile .bash_profile .zshrc; do
  if [ -f "$file" ] && [ ! -L "$file" ]; then
    mv "$file" "$file.backup"
    log "Backed up $file → $file.backup"
  fi
done

# === Stow dotfiles ===
cd "$DOTFILES_DIR"
log "Stowing dotfiles..."
stow */
ok "Dotfiles applied with stow"

# === Update PATH ===
BASHRC="$HOME/.bashrc"
paths=(
  "$HOME/local/bin"
  "$HOME/.local/bin"
)

for dir in "${paths[@]}"; do
  if [[ ":$PATH:" != *":$dir:"* ]]; then
    export PATH="$dir:$PATH"
  fi

  if ! grep -Fxq "export PATH=\"$dir:\$PATH\"" "$BASHRC"; then
    echo "export PATH=\"$dir:\$PATH\"" >> "$BASHRC"
    log "Added $dir to PATH in .bashrc"
  fi
done

ok "PATH updated and persistent"
