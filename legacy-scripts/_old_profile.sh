#!/usr/bin/env zsh

INSTALL_DIR="$(cd "$(dirname "$0")" && pwd)"

echo INSTALL_DIR=${INSTALL_DIR}
# Create symlinks
#mkdir -p "$HOME/.local/bin"

# Timestamp function - returns current time with microseconds
# Returns timestamp with milliseconds: 2026-04-24 14:30:45.123
ts() {
    # Try GNU date first (if installed via Homebrew as gdate)
    if command -v gdate &>/dev/null; then
        gdate +"%Y-%m-%d %H:%M:%S.%3N"
    # Perl fallback – fastest, built into macOS [citation:7]
    elif command -v perl &>/dev/null; then
        perl -MTime::HiRes -e 'use POSIX qw(strftime); my ($s, $ms) = (Time::HiRes::time(), int((Time::HiRes::time() * 1000) % 1000)); printf "%s.%03d\n", strftime("%Y-%m-%d %H:%M:%S", localtime($s)), $ms'
    # Python fallback – also always on macOS
    elif command -v python3 &>/dev/null; then
        python3 -c 'import time; t=time.time(); ms=int((t*1000)%1000); print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(t)) + f".{ms:03d}")'
    # Last resort – seconds only
    else
        date +"%Y-%m-%d %H:%M:%S"
    fi
}

# Print with timestamp prefix
p() {
  echo "[$(ts)] $*"
}

# Print with timestamp prefix
p() {
  echo "[$(ts)] $*"
}

_setupShebang() {
  local -a cmd
  local shebang_script="$INSTALL_DIR/lua-wow-shebang.lua"
  p "Linking the shebang script: $shebang_script"
  local shebang_name=$(basename "$shebang_script" .lua)
  cmd=(ln -sf $shebang_script "$HOME/.local/bin/$shebang_name")
  p "Executing: ${cmd[*]}"
  "${cmd[@]}"
  p "Done: ${cmd[*]}"
}

_Main() {
  _setupShebang

  local installTarget="$HOME/.local/bin"
  local source="$INSTALL_DIR/bin"
  p "Installing WOW lua scripts to: $installTarget"
  for script in "${source}/"*.lua; do
      name="wow-$(basename "$script" .lua)"
      p "  $script => ${installTarget}/${name}"
      cmd=(ln -sf $script "${installTarget}/${name}")
      p "Executing: $cmd"
      $cmd || { echo "Error: Command failed" >&2; return 1; }
      cmd=(chmod +x $script)
      p "  ${cmd[*]}"
      $cmd || { echo "Error: Command failed" >&2; return 1; }
  done

  # This may not be need if lua-wow-shebang is used
  # One magic line
  #echo "export LUA_PATH='$INSTALL_DIR/?.lua;$INSTALL_DIR/?/init.lua;./?.lua;;'" >> "$HOME/.profile"
  #echo "Installed! Run 'source ~/.profile'"
}

_Main "$@"
