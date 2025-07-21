#!/bin/bash
set -euo pipefail

log()    { echo -e "\033[1;34m==>\033[0m $*"; }
ok()     { echo -e "\033[1;32m✔\033[0m $*"; }
error()  { echo -e "\033[1;31m✘\033[0m $*"; }

log "Detecting Linux distribution..."

if [ ! -f /etc/os-release ]; then
  error "/etc/os-release not found, cannot continue."
  exit 1
fi

. /etc/os-release

case "$ID" in
  ubuntu|debian)
    log "Updating apt and installing packages..."
    sudo apt update -y
    sudo apt install -y \
      build-essential git fish curl stow wget unzip tar xz-utils zstd \
      pkg-config cmake make gcc g++ clang lldb lld \
      libssl-dev libz-dev libbz2-dev liblzma-dev \
      libgtk-4-dev libadwaita-1-dev blueprint-compiler gettext \
      openssh-client ca-certificates gnupg software-properties-common \
      vim
    ;;
  fedora)
    log "Installing DNF packages..."
    sudo dnf install -y \
      @development-tools \
      git curl wget unzip tar fish xz stow zstd \
      pkgconf cmake gcc gcc-c++ clang lldb lld \
      openssl-devel zlib-devel bzip2-devel xz-devel \
      gtk4-devel libadwaita-devel blueprint-compiler gettext \
      openssh ca-certificates gnupg2
    ;;
  *)
    error "Unsupported distro: $ID"
    exit 1
    ;;
esac

ok "System packages installed."

