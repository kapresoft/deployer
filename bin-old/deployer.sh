#!/usr/bin/env bash

set -euo pipefail

LUA_SCRIPT_NAME="deployer.lua"
SOURCE="${BASH_SOURCE[0]}"
while [[ -L "$SOURCE" ]]; do
  DIR="$(cd -P -- "$(dirname -- "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P -- "$(dirname -- "$SOURCE")/.." && pwd)"
export LUA_PATH="$SCRIPT_DIR/lua/?.lua;$SCRIPT_DIR/lua/?/init.lua;;"
LUA_SCRIPT="${SCRIPT_DIR}/${LUA_SCRIPT_NAME}"

[[ -f "$LUA_SCRIPT" ]] || {
  printf '[ERROR]: missing Lua script: %s\n' "$LUA_SCRIPT" >&2
  exit 1
}

exec lua "$LUA_SCRIPT" "$@"
