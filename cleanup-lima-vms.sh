#!/bin/bash

set -euo pipefail

FORCE=false

usage() {
  echo "Usage: $0 [-f]"
  echo "  -f  Force cleanup without confirmation prompt"
}

while getopts ":fh" opt; do
  case "$opt" in
    f)
      FORCE=true
      ;;
    h)
      usage
      exit 0
      ;;
    \?)
      usage
      exit 1
      ;;
  esac
done

VMS=()
while read -r vm; do
  [[ -n "$vm" ]] && VMS+=("$vm")
done < <(limactl list --format '{{.Name}}')

if (( ${#VMS[@]} == 0 )); then
  echo "No Lima VMs found."
  exit 0
fi

echo "Lima VMs to remove:"
for vm in "${VMS[@]}"; do
  echo "  - $vm"
done

if [[ "$FORCE" != "true" ]]; then
  read -r -p "Stop and delete all listed VMs? [y/N]: " REPLY
  if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
fi

for vm in "${VMS[@]}"; do
  echo "Stopping $vm (if running)..."
  limactl stop "$vm" >/dev/null 2>&1 || true
done

for vm in "${VMS[@]}"; do
  echo "Deleting $vm..."
  limactl delete "$vm"
done

echo "Cleanup complete."
