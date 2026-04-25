#!/usr/bin/env bash

set -euo pipefail

LUA_SCRIPT_NAME="sync-libs.lua"
SOURCE="${BASH_SOURCE[0]}"
while [[ -L "$SOURCE" ]]; do
  DIR="$(cd -P -- "$(dirname -- "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P -- "$(dirname -- "$SOURCE")/.." && pwd)"
export LUA_PATH="$SCRIPT_DIR/?.lua;$SCRIPT_DIR/?/init.lua;;"
echo LUA_PATH=$LUA_PATH
LUA_SCRIPT="${SCRIPT_DIR}/${LUA_SCRIPT_NAME}"

[[ -f "$LUA_SCRIPT" ]] || {
  printf '[ERROR]: missing Lua script: %s\n' "$LUA_SCRIPT" >&2
  exit 1
}

exec lua "$LUA_SCRIPT" "$@"
