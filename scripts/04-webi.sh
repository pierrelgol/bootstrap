#!/bin/bash
set -euo pipefail

log()    { echo -e "\033[1;34m==>\033[0m $*"; }
ok()     { echo -e "\033[1;32m✔\033[0m $*"; }
error()  { echo -e "\033[1;31m✘\033[0m $*"; }

# === Install Webi ===
if ! command -v webi &>/dev/null; then
  log "Installing Webi..."
  curl -sS https://webi.sh/webi | sh
  ok "Webi installed"
else
  ok "Webi already installed"
fi

# === Source envman for this session ===
ENV_FILE="$HOME/.config/envman/PATH.env"
if [ -f "$ENV_FILE" ]; then
  source "$ENV_FILE"
  ok "Sourced PATH.env"
else
  error "envman PATH.env not found — is Webi installed correctly?"
  exit 1
fi

BASHRC="$HOME/.bashrc"
if ! grep -q "$ENV_FILE" "$BASHRC"; then
  echo -e "\n[ -f \"$ENV_FILE\" ] && source \"$ENV_FILE\"" >> "$BASHRC"
  ok "Added envman sourcing to .bashrc"
else
  ok "envman already sourced in .bashrc"
fi

for tool in brew ziglang rust; do
  if command -v "$tool" &>/dev/null; then
    ok "$tool already installed"
  else
    log "Installing $tool via Webi..."
    webi "$tool"
    ok "$tool installed"
  fi
done

