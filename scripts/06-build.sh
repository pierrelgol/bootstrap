#!/bin/bash
set -euo pipefail

log()    { echo -e "\033[1;34m==>\033[0m $*"; }
ok()     { echo -e "\033[1;32m✔\033[0m $*"; }
error()  { echo -e "\033[1;31m✘\033[0m $*"; }

REPO_DIR="$HOME/local/repo"
BIN_DIR="$HOME/local/bin"
mkdir -p "$REPO_DIR" "$BIN_DIR"

[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
[ -f "$HOME/.config/envman/PATH.env" ] && source "$HOME/.config/envman/PATH.env"

# === Build yazi ===
YAZI_DIR="$REPO_DIR/yazi"
if command -v yazi &>/dev/null; then
  ok "yazi already installed"
else
  log "Cloning and building yazi..."
  [ -d "$YAZI_DIR" ] || git clone --depth 1 https://github.com/sxyazi/yazi "$YAZI_DIR"
  cd "$YAZI_DIR"
  cargo build --release --locked
  cp target/release/yazi "$BIN_DIR"
  cp target/release/ya "$BIN_DIR"
  ok "yazi and ya installed"
fi

# === Build helix ===
HELIX_DIR="$REPO_DIR/helix"
if command -v hx &>/dev/null; then
  ok "helix (hx) already installed"
else
  log "Cloning and building helix..."
  [ -d "$HELIX_DIR" ] || git clone --depth 1 https://github.com/helix-editor/helix "$HELIX_DIR"
  cd "$HELIX_DIR"
  cargo install --path helix-term --locked
  cp "$HOME/.cargo/bin/hx" "$BIN_DIR/hx"
  mkdir -p "$BIN_DIR/helix"
  cp -r runtime "$BIN_DIR/helix/runtime"
  export HELIX_RUNTIME="$BIN_DIR/helix/runtime"
  ok "helix built and installed"
fi

# === Build ZLS ===
ZLS_DIR="$REPO_DIR/zls"
if command -v zls &>/dev/null; then
  ok "zls already installed"
else
  zig_version=$(zig version || echo "")
  if [[ ! "$zig_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    error "Zig version not detected or invalid: $zig_version"
    exit 1
  fi

  log "Cloning and building ZLS for Zig $zig_version..."
  [ -d "$ZLS_DIR" ] || git clone https://github.com/zigtools/zls "$ZLS_DIR"
  cd "$ZLS_DIR"

  if git rev-parse "$zig_version" &>/dev/null; then
    git checkout "$zig_version"
  else
    log "No exact ZLS tag for $zig_version — using default branch"
  fi

  zig build -Doptimize=ReleaseFast -p "$HOME/local"
  ok "ZLS built and installed"
fi
