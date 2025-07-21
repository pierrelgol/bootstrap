#!/bin/bash
set -euo pipefail

log()    { echo -e "\033[1;34m==>\033[0m $*"; }
ok()     { echo -e "\033[1;32m✔\033[0m $*"; }
error()  { echo -e "\033[1;31m✘\033[0m $*"; }

log "Setting up SSH keys..."

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

for keyname in github school; do
  keypath="$HOME/.ssh/$keyname"
  if [ ! -f "$keypath" ]; then
    ssh-keygen -t ed25519 -f "$keypath" -N "" -C "$keyname"
    ok "SSH key generated: $keyname"
  else
    ok "SSH key already exists: $keyname"
  fi
done

log "Public keys:"
echo
cat "$HOME/.ssh/github.pub"
echo
cat "$HOME/.ssh/school.pub"
echo

read -p "Add these keys to their platforms, then press ENTER to continue..."

eval "$(ssh-agent -s)"
ssh-add "$HOME/.ssh/github"
ssh-add "$HOME/.ssh/school"
ok "SSH keys added to agent"

