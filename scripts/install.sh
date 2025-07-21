#!/bin/bash
set -euo pipefail

STEPS=(
  00-packages.sh
  01-fonts.sh
  02-ssh.sh
  03-env.sh
  04-webi.sh
  05-tools.sh
  06-build.sh
)

log() { echo -e "\n\033[1;36m==>\033[0m Running: $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for step in "${STEPS[@]}"; do
  log "$step"
  bash "$SCRIPT_DIR/$step"
done

echo -e "\n\033[1;32m✔\033[0m All steps completed successfully."

