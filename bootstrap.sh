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
  local font_dir="$HOME/.local/share/fonts"
  local temp_dir
  temp_dir=$(mktemp -d)
  local font_url_base="https://raw.githubusercontent.com/pierrelgol/bootstrap/main/CommitMono"

  # Check if already installed
  if fc-list | grep -qi "CommitMonoNerdFontMono"; then
    log_success "Commit Mono Nerd Font already installed"
    return
  fi

  log_info "Installing Commit Mono Nerd Font from bootstrap repo..."

  mkdir -p "$font_dir"

  # Download each font file individually
  for font_file in \
    CommitMonoNerdFontMono-Regular.otf \
    CommitMonoNerdFontMono-Bold.otf \
    CommitMonoNerdFontMono-Italic.otf \
    CommitMonoNerdFontMono-BoldItalic.otf
  do
    curl -fsSL "$font_url_base/$font_file" -o "$temp_dir/$font_file"
    cp "$temp_dir/$font_file" "$font_dir/"
  done

  fc-cache -f "$font_dir"
  rm -rf "$temp_dir"

  log_success "Commit Mono Nerd Font installed"
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

source_rust_env() {
  local rust_env="$HOME/.cargo/env"
  if [ -f "$rust_env" ]; then
    . "$rust_env"
    log_success "Sourced Rust environment from .cargo/env"
  else
    log_error "Rust environment file not found at $rust_env"
    exit 1
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

build_yazi_from_source() {
  local repo_dir="$HOME/local/repo"
  local bin_dir="$HOME/local/bin"
  local yazi_dir="$repo_dir/yazi"

  if command -v yazi &>/dev/null; then
    log_success "yazi already installed"
    return
  fi

  log_info "Cloning and building yazi from source..."

  mkdir -p "$repo_dir"
  git clone https://github.com/sxyazi/yazi.git "$yazi_dir"
  cd "$yazi_dir"
  cargo build --release --locked

  cp target/release/yazi "$bin_dir/"
  cp target/release/ya "$bin_dir/"
  cd "$repo_dir"
  log_success "yazi and ya installed to $bin_dir"
}

build_helix_from_source() {
  local repo_dir="$HOME/local/repo"
  local bin_dir="$HOME/local/bin"
  local helix_dir="$repo_dir/helix"

  if command -v hx &>/dev/null; then
    log_success "helix (hx) already installed"
    return
  fi

  log_info "Cloning and building helix from source..."

  git clone https://github.com/helix-editor/helix "$helix_dir"
  cd "$helix_dir"

  cargo install --path helix-term --locked

  local cargo_bin="$(cargo bin hx || echo "$HOME/.cargo/bin/hx")"

  cp "$cargo_bin" "$bin_dir/hx"

  mkdir -p "$bin_dir/helix"
  cp -r runtime "$bin_dir/helix/runtime"

  log_success "helix installed to $bin_dir/hx"
  log_info "HELIX_RUNTIME should point to $bin_dir/helix/runtime"

  export HELIX_RUNTIME="$bin_dir/helix/runtime"
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
  source_rust_env
  cargo_install bat
  cargo_install eza
  cargo_install zoxide
  cargo_install atuin
  cargo_install ripgrep

  build_yazi_from_source
  log_info "System ready."
}

main
