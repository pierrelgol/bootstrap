#!/bin/bash
set -euo pipefail

REPO_URL="https://github.com/pierrelgol/bootstrap"
CLONE_DIR="$HOME/.bootstrap"

rm -rf "$CLONE_DIR"
git clone --depth 1 "$REPO_URL" "$CLONE_DIR"
bash "$CLONE_DIR/scripts/install.sh"
