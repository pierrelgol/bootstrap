#!/bin/bash
set -euo pipefail

log()    { echo -e "\033[1;34m==>\033[0m $*"; }
ok()     { echo -e "\033[1;32m✔\033[0m $*"; }
error()  { echo -e "\033[1;31m✘\033[0m $*"; }

FONT_NAME="CommitMonoNerdFontMono"
FONT_SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../font/CommitMono" && pwd)"
FONT_DEST_DIR="$HOME/.local/share/fonts"

mkdir -p "$FONT_DEST_DIR"

if fc-list | grep -qi "$FONT_NAME"; then
  ok "$FONT_NAME already installed"
  exit 0
fi

log "Installing $FONT_NAME from $FONT_SRC_DIR"

cp "$FONT_SRC_DIR"/*.otf "$FONT_DEST_DIR/"
fc-cache -f "$FONT_DEST_DIR"

ok "$FONT_NAME installed and font cache updated"

