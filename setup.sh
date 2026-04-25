#!/usr/bin/env bash
set -euo pipefail

local_bin="$HOME/.local/bin"
mkdir -p "$local_bin"

scripts=(
  deployer
  sync-libs
)

for name in "${scripts[@]}"; do
  src="$PWD/bin/${name}.sh"
  dst="$local_bin/$name"

  chmod +x "$src"

  if [[ -f $dst ]]; then
    echo "File exists: $dst"
  else
    ln -sf "$src" "$dst"
    printf 'Installed: %s -> %s\n' "$dst" "$src"
  fi
done

printf 'Make sure ~/.local/bin is in your PATH.\n'
