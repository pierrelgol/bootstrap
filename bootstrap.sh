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

bootstrap_setup_directories() {
  log_info "Setting up directory structure..."
  mkdir -p "$HOME/local/bin"
  mkdir -p "$HOME/local/repo"
  mkdir -p "$HOME/workspace"
  mkdir -p "$HOME/.local/share/fonts"
  log_success "Directories created"
}

bootstrap_install_font_commit_mono() {
  FONT_DIR="$HOME/.local/share/fonts"
  FONT_NAME="CommitMono"
  FONT_URL="https://github.com/arrowtype/commit-mono/releases/download/v1.1/CommitMono-1.1.zip"

  if fc-list | grep -qi "CommitMono"; then
    log_success "Commit Mono already installed"
    return
  fi

  log_info "Installing Commit Mono font..."
  TEMP_DIR=$(mktemp -d)
  curl -L "$FONT_URL" -o "$TEMP_DIR/commitmono.zip"
  unzip -qq "$TEMP_DIR/commitmono.zip" -d "$TEMP_DIR"
  cp "$TEMP_DIR"/fonts/otf/*.otf "$FONT_DIR"
  fc-cache -f "$FONT_DIR"
  rm -rf "$TEMP_DIR"
  log_success "Commit Mono installed"
}

bootstrap_install_webi() {
  if [ ! -f "$HOME/.local/bin/webi" ]; then
    log_info "Installing Webi..."
    curl -sS https://webi.sh/webi | sh
  else
    log_success "Webi already installed"
  fi
}

bootstrap_source_envman() {
  local env_file="$HOME/.config/envman/PATH.env"

  if [ -f "$env_file" ]; then
    source "$env_file"
    log_success "Sourced PATH.env in current shell"
  else
    log_error "PATH.env not found. Webi may not have installed correctly."
    exit 1
  fi
}

bootstrap_source_envman_persistent() {
  local env_file="$HOME/.config/envman/PATH.env"
  local bashrc="$HOME/.bashrc"

  if ! grep -q "$env_file" "$bashrc"; then
    echo -e "\n[ -f \"$env_file\" ] && source \"$env_file\"" >> "$bashrc"
    log_info "Added PATH.env sourcing to .bashrc"
  else
    log_success "PATH.env already sourced in .bashrc"
  fi
}

webi_install() {
  local tool="$1"

  if command -v "$tool" &>/dev/null; then
    log_success "$tool already installed"
  else
    log_info "Installing $tool via Webi..."
    webi "$tool"
    log_success "$tool installed"
  fi
}

cargo_install() {
  local tool="$1"
  if command -v "$tool" &>/dev/null; then
    log_success "$tool already installed"
  else
    log_info "Installing $tool with cargo..."
    cargo install "$tool"
    log_success "$tool installed"
  fi
}

main() {
  log_info "Starting bootstrap..."
  bootstrap_setup_directories
  bootstrap_install_font_commit_mono
  bootstrap_install_webi
  bootstrap_source_envman
  bootstrap_source_envman_persistent
  webi_install ziglang
  webi_install rust
  webi_install yazi
  cargo_install bat
  cargo_install eza
  cargo_install zoxide
  cargo_install atuin
  cargo_install ripgrep
  log_info "System ready."
}

main
