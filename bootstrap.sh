#!/bin/bash
set -euo pipefail

log_info() {
  echo -e "\033[1;34m==>\033[0m $1"
}

log_success() {
  echo -e "\033[1;32m✔\033[0m $1"
}

log_error() {
  echo -e "\033[1;31m✗\033[0m $1"
}

ensure_webi_installed() {
  if [ ! -f "$HOME/.local/bin/webi" ]; then
    log_info "Installing Webi..."
    curl -sS https://webi.sh/webi | sh
  else
    log_success "Webi already installed"
  fi
}

ensure_envman_sourced() {
  local env_file="$HOME/.config/envman/PATH.env"

  if [ -f "$env_file" ]; then
    source "$env_file"
    log_success "Sourced PATH.env in current shell"
  else
    log_error "PATH.env not found. Webi may not have installed correctly."
    exit 1
  fi
}

ensure_envman_persistent() {
  local env_file="$HOME/.config/envman/PATH.env"
  local bashrc="$HOME/.bashrc"

  if ! grep -q "$env_file" "$bashrc"; then
    echo -e "\n[ -f \"$env_file\" ] && source \"$env_file\"" >> "$bashrc"
    log_info "Added PATH.env sourcing to .bashrc"
  else
    log_success "PATH.env already sourced in .bashrc"
  fi
}

main() {
  log_info "Starting bootstrap..."
  ensure_webi_installed
  ensure_envman_sourced
  ensure_envman_persistent
  log_info "Webi is ready. Try running \`webi ziglang\` or \`webi rust\` next."
}

main
