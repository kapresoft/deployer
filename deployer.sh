#!/usr/bin/env bash

set -euo pipefail

LUA_BIN="${LUA_BIN:-lua}"
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
#printf "SCRIPT_DIR: %s\n" "$SCRIPT_DIR"
DEPLOY_LUA="${SCRIPT_DIR}/deployer.lua"

exec "$LUA_BIN" "$DEPLOY_LUA" "$@"
