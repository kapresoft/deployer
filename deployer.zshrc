# GIVEN: DEPLOYER_HOME from deployer-profile-helper.sh

alias w-helpme=_w_helpme
w-deployer() { INVOKED_AS=$funcstack[1] $DEPLOYER_HOME/bin/deployer.lua "$@"; }
w-sync-libs() { INVOKED_AS=$funcstack[1] ${DEPLOYER_HOME}/bin/sync-libs.lua "$@"; }

_w_helpme() {
    echo "Available WoW Scripts:"
    printf "  %-15s %s\n" "w-deployer" "-> local wow deployer"
    printf "  %-15s %s\n" "w-sync-libs" "-> pull local libs to a wow project"
}
