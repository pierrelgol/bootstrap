#!/bin/bash
set -euo pipefail

setup_ssh_keys() {
  log_info "Setting up SSH keys..."
  mkdir -p "$HOME/.ssh"

  for keyname in github school; do
    local keypath="$HOME/.ssh/$keyname"
    if [ ! -f "$keypath" ]; then
      ssh-keygen -t ed25519 -f "$keypath" -N "" -C "$keyname"
      log_success "SSH key generated: $keyname"
    else
      log_success "SSH key already exists: $keyname"
    fi
  done

  echo -e "\n\033[1;34m==>\033[0m Public keys:\n"
  cat "$HOME/.ssh/github.pub"
  echo
  cat "$HOME/.ssh/school.pub"
  echo -e "\n\033[1;34m==>\033[0m Add these keys to their respective platforms, then press ENTER to continue..."
  read -r

  ssh-add "$HOME/.ssh/github"
  ssh-add "$HOME/.ssh/school"
  log_success "SSH keys added to ssh-agent"
}

install_system_packages() {
  log_info "Installing system development packages..."

  if [ ! -f /etc/os-release ]; then
    log_error "/etc/os-release not found. Cannot detect distro."
    return 1
  fi

  . /etc/os-release

  case "$ID" in
    ubuntu|debian)
      sudo apt update
      sudo apt install -y \
        git curl wget openssh-client vim build-essential \
        clang lldb lld llvm-dev libclang-dev \
        pkg-config cmake make gcc g++ \
        unzip tar xz-utils zstd \
        libssl-dev libz-dev libbz2-dev liblzma-dev \
        ca-certificates gnupg software-properties-common
      ;;
    fedora)
      sudo dnf install -y \
        git curl wget openssh vim \
        clang lldb lld llvm-devel clang-devel \
        pkgconf cmake make gcc gcc-c++ \
        unzip tar xz zstd \
        openssl-devel zlib-devel bzip2-devel xz-devel \
        ca-certificates gnupg2
      ;;
    *)
      log_error "Unsupported distro: $ID. Install development tools manually."
      return 1
      ;;
  esac

  log_success "System packages installed"
}

INTERACTIVE_MODE=true

run_step() {
  local step_name="$1"
  local step_func="$2"

  if [ "$INTERACTIVE_MODE" = false ]; then
    $step_func
    return
  fi

  while true; do
    echo -e "\n\033[1;36m==>\033[0m Run step '\033[1m$step_name\033[0m'? [Y]es / [n]o / [s]kip all prompts: "
    read -r choice
    case "$choice" in
      [Yy]|"") $step_func && break ;;
      [Nn]) log_info "Skipped step: $step_name" && break ;;
      [Ss]) INTERACTIVE_MODE=false && log_info "Skipping prompts from now on..." && $step_func && break ;;
      *) echo "Please enter Y, n, or s." ;;
    esac
  done
}

log_info() {
  echo -e "\033[1;34m==>\033[0m $1"
}

log_success() {
  echo -e "\033[1;32m\u2714\033[0m $1"
}

log_error() {
  echo -e "\033[1;31m\u2717\033[0m $1"
}

setup_directories() {
  log_info "Setting up directory structure..."
  mkdir -p "$HOME/local/bin" "$HOME/local/repo" "$HOME/workspace" "$HOME/.local/share/fonts"
  log_success "Directories created"
}

setup_path_env() {
  local bashrc="$HOME/.bashrc"
  local paths=(
    "$HOME/local/bin"
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"
  )

  for dir in "${paths[@]}"; do
    if [[ ":$PATH:" != *":$dir:"* ]]; then
      export PATH="$dir:$PATH"
    fi

    if ! grep -Fxq "export PATH=\"$dir:\$PATH\"" "$bashrc"; then
      echo "export PATH=\"$dir:\$PATH\"" >> "$bashrc"
      log_info "Added $dir to PATH in .bashrc"
    else
      log_success "$dir already in PATH in .bashrc"
    fi
  done

  log_success "Updated PATH with all local binary directories"
}

install_font_commit_mono() {
  local font_dir="$HOME/.local/share/fonts"
  local temp_dir
  temp_dir=$(mktemp -d)
  local font_url_base="https://raw.githubusercontent.com/pierrelgol/bootstrap/main/CommitMono"

  if fc-list | grep -qi "CommitMonoNerdFontMono"; then
    log_success "Commit Mono Nerd Font already installed"
    return
  fi

  log_info "Installing Commit Mono Nerd Font from bootstrap repo..."
  mkdir -p "$font_dir"

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

setup_envman_current() {
  local env_file="$HOME/.config/envman/PATH.env"
  if [ -f "$env_file" ]; then
    source "$env_file"
    log_success "Sourced PATH.env in current shell"
  else
    log_error "PATH.env not found. Webi may not have installed correctly."
    exit 1
  fi
}

install_webi() {
  if [ ! -f "$HOME/.local/bin/webi" ]; then
    log_info "Installing Webi..."
    curl -sS https://webi.sh/webi | sh
    setup_envman_current
  else
    log_success "Webi already installed"
  fi
}


setup_envman_persistent() {
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
  setup_envman_current
  if command -v "$tool" &>/dev/null; then
    log_success "$tool already installed"
  else
    log_info "Installing $tool via Webi..."
    webi "$tool"
    log_success "$tool installed"
    setup_envman_current
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

  cd "$repo_dir"
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

  cd "$repo_dir"
  if command -v hx &>/dev/null; then
    log_success "helix (hx) already installed"
    return
  fi

  log_info "Cloning and building helix from source..."

  git clone https://github.com/helix-editor/helix "$helix_dir"
  cd "$helix_dir"

  cargo install --path helix-term --locked

  local cargo_bin="$HOME/.cargo/bin/hx"

  if [ ! -f "$cargo_bin" ]; then
    log_error "helix binary not found at $cargo_bin"
    return 1
  fi

  cp "$cargo_bin" "$bin_dir/hx"
  mkdir -p "$bin_dir/helix"
  cp -r runtime "$bin_dir/helix/runtime"

  log_success "helix installed to $bin_dir/hx"
  log_info "HELIX_RUNTIME should point to $bin_dir/helix/runtime"

  export HELIX_RUNTIME="$bin_dir/helix/runtime"
  cd "$repo_dir"
}

build_zls_from_source() {
  local repo_dir="$HOME/local/repo"
  local bin_dir="$HOME/local/bin"
  local zls_dir="$repo_dir/zls"

  cd "$repo_dir"
  if command -v zls &>/dev/null; then
    log_success "zls already installed"
    return
  fi

  local zig_version
  zig_version=$(zig version)
  if [[ ! "$zig_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log_error "Could not detect valid Zig version (got: $zig_version)"
    return 1
  fi

  log_info "Cloning ZLS and checking out tag $zig_version"

  mkdir -p "$repo_dir"
  git clone https://github.com/zigtools/zls.git "$zls_dir"
  cd "$zls_dir"

  if git rev-parse "$zig_version" >/dev/null 2>&1; then
    git checkout "$zig_version"
  else
    log_error "No ZLS tag found for Zig $zig_version. Staying on default branch."
  fi

  zig build -Doptimize=ReleaseSafe -p "$HOME/local"

  log_success "ZLS built and installed to $bin_dir"
  cd "$repo_dir"
}

install_zigup() {
  local bin_dir="$HOME/local/bin"
  local zigup_url="https://github.com/marler8997/zigup/releases/latest/download/zigup-x86_64-linux.tar.gz"
  local temp_dir
  temp_dir=$(mktemp -d)

  if command -v zigup &>/dev/null; then
    log_success "zigup already installed"
    return
  fi

  log_info "Installing zigup..."

  curl -fsSL "$zigup_url" | tar -xz -C "$temp_dir"

  if [ ! -f "$temp_dir/zigup" ]; then
    log_error "zigup binary not found after extraction"
    return 1
  fi

  mv "$temp_dir/zigup" "$bin_dir/"
  chmod +x "$bin_dir/zigup"
  rm -rf "$temp_dir"

  log_success "zigup installed to $bin_dir"
}

build_ghostty_from_source() {
  local install_prefix="$HOME/.local"
  local bin_dir="$install_prefix/bin"
  local repo_dir="$HOME/local/repo"
  local ghostty_dir="$repo_dir/ghostty"

  if command -v ghostty &>/dev/null; then
    log_success "ghostty already installed"
    return
  fi

  local zig_version
  zig_version=$(zig version)
  if [[ ! "$zig_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log_error "Could not detect valid Zig version (got: $zig_version)"
    return 1
  fi

  log_info "Installing system dependencies for Ghostty..."

  if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
      ubuntu|debian)
        sudo apt update
        sudo apt install -y libgtk-4-dev libadwaita-1-dev git blueprint-compiler gettext
        ;;
      fedora)
        sudo dnf install -y gtk4-devel zig libadwaita-devel blueprint-compiler gettext
        ;;
      *)
        log_error "Unsupported distro: $ID. Install GTK4, libadwaita, blueprint-compiler, gettext manually."
        return 1
        ;;
    esac
  else
    log_error "/etc/os-release not found. Cannot detect distro."
    return 1
  fi

  log_info "Cloning Ghostty and checking out branch $zig_version"
  mkdir -p "$repo_dir"
  git clone https://github.com/ghostty-org/ghostty "$ghostty_dir"
  cd "$ghostty_dir"

  if git rev-parse "$zig_version" >/dev/null 2>&1; then
    git checkout "$zig_version"
  else
    log_error "No branch found for Zig version $zig_version in Ghostty. Staying on default branch."
  fi

  zig build -Doptimize=ReleaseFast -p "$install_prefix"
  log_success "Ghostty built and installed to $bin_dir"
}

install_chezmoi_dotfiles() {
  if command -v chezmoi &>/dev/null; then
    log_success "chezmoi already installed"
  else
    log_info "Installing and applying chezmoi..."
    sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply pierrelgol
    log_success "chezmoi installed and dotfiles applied"
  fi
}

main() {
  log_info "Starting bootstrap..."

  run_step "Install system packages (requires sudo)" install_system_packages
  run_step "Setup directories" setup_directories
  run_step "Add local bin directories to PATH" setup_path_env
  run_step "Install Commit Mono font" install_font_commit_mono
  run_step "Setup SSH keys" setup_ssh_keys
  run_step "Install Webi" install_webi
  run_step "Source envman (current shell)" setup_envman_current
  run_step "Source envman persistently" setup_envman_persistent

  run_step "Install Brew (Webi)" "webi_install brew"
  run_step "Install Zig  (Webi)" "webi_install ziglang"
  run_step "Install Go   (Webi)" "webi_install golang@stable"
  run_step "Install Rust (Webi)" "webi_install rust"
  run_step "Source Rust env" source_rust_env
  run_step "Source envman (current shell)" setup_envman_current
  run_step "Source envman persistently" setup_envman_persistent

  run_step "Build yazi from source" build_yazi_from_source
  run_step "Build helix from source" build_helix_from_source

  run_step "Build ZLS from source" build_zls_from_source
  run_step "Install zigup" install_zigup
  run_step "Build Ghostty from source" build_ghostty_from_source
  run_step "Install and apply chezmoi dotfiles" install_chezmoi_dotfiles

  log_info "System ready."
}

main
