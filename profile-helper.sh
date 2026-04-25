#!/usr/bin/env zsh

setopt local_options
setopt extended_glob

# Usage function
usage() {
  cat <<EOF
Usage: ${0:t} [-v|--verbose] [-t|--target <os>] [input]

Options:
    -v, --verbose       Enable verbose output
    -t, --target <os>   Target operating system (default: macos)
    -s, --shell         Execute in a shell env (for sourcing in .zshrc)
    -h, --help          Show this help message

Examples:
    ${0:t} -t linux --shell -v
    ${0:t} --target macos -v
    ${0:t} -v
EOF
  exit 0
}

example_usage() {
  local this=$0
  echo "Add the following at the end of your ~/.[shell rc file] file:"
  echo
  echo "eval \$(${this} -t macosx -s) && source \${SHELL_PROFILE_SCRIPT}"
}

# Default values
verbose=false
is_shell=false
target_os="macos" # Default to macos
input=""

# Parse options
zparseopts -D -E -F -- \
  {s,-shell}=shell_flag \
  {v,-verbose}=verbose_flag \
  {t,-target}=target_os_option \
  {h,-help}=help_flag ||
  {
    echo "Error: Unknown option" >&2
    usage
    exit 1
  }

[[ -n "$shell_flag" ]] && is_shell=true
[[ -n "$help_flag" ]] && usage
[[ -n "$verbose_flag" ]] && verbose=true

# Handle target option (overrides default if provided)
if [[ -n "$target_os_option" && -n "${target_os_option[2]}" ]]; then
  target_os="${target_os_option[2]}"
fi

deployer_zshrc_name=deployer.zshrc
if [[ -n "$is_shell" ]]; then
    deployer_home="$(dirname $0)"
    deployer_zshrc="${deployer_home}/${deployer_zshrc_name}"
    if [[ ! -f "$deployer_zshrc"  ]]; then
      echo "echo [ERROR]: Script not found: $deployer_zshrc"
      echo "echo [ERROR]: Source: $0"
      --echo "echo DEPLOYER_HOME=\"${deployer_home}\""
      exit 0
    fi

    echo -n "export DEPLOYER_HOME=\"${deployer_home}\""
    echo -n ";path=(\"\$DEPLOYER_HOME/shebang\" \$path)"
    echo -n "; source ${deployer_zshrc}"
    echo
    exit 0
fi

echo "0: $0"
echo "dirname: $(dirname $0)"
echo "Add the following at the end of your ~/.[shell rc file] file:"; echo
echo "eval \$(${helper} -t ${shell_profile_os} -s) && source \${SHELL_PROFILE_SCRIPT}"
echo
