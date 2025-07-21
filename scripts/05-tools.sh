#!/bin/bash
set -euo pipefail

log()    { echo -e "\033[1;34m==>\033[0m $*"; }
ok()     { echo -e "\033[1;32m✔\033[0m $*"; }
error()  { echo -e "\033[1;31m✘\033[0m $*"; }

# === Source Rust and envman ===
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
[ -f "$HOME/.config/envman/PATH.env" ] && source "$HOME/.config/envman/PATH.env"

# === zigup ===
if ! command -v zigup &>/dev/null; then
  log "Installing zigup..."
  tmp=$(mktemp -d)
  curl -fsSL https://github.com/marler8997/zigup/releases/latest/download/zigup-x86_64-linux.tar.gz | tar -xz -C "$tmp"
  install -m755 "$tmp/zigup" "$HOME/local/bin/zigup"
  rm -rf "$tmp"
  ok "zigup installed"
else
  ok "zigup already installed"
fi

# === cargo tools ===
cargo_tools=(
  cargo-edit
  cargo-nextest
  bacon
  just
)

for tool in "${cargo_tools[@]}"; do
  if command -v "$tool" &>/dev/null; then
    ok "$tool already installed"
  else
    log "Installing $tool..."
    cargo install "$tool"
    ok "$tool installed"
  fi
done

# === brew tools ===
brew_tools=(
  eza
  bat
)

if ! command -v brew &>/dev/null; then
  error "brew not found (expected from Webi). Skipping brew tools."
else
  for tool in "${brew_tools[@]}"; do
    if brew list "$tool" &>/dev/null; then
      ok "$tool already installed via brew"
    else
      log "Installing $tool via brew..."
      brew install "$tool"
      ok "$tool installed"
    fi
  done
fi

