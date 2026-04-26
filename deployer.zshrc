# GIVEN: DEPLOYER_HOME from deployer-profile-helper.sh
alias w-deployer="ALIAS_NAME=w-deployer ${DEPLOYER_HOME}/bin/deployer.lua"
alias w-sync-libs="ALIAS_NAME=w-sync-libs ${DEPLOYER_HOME}/bin/sync-libs.lua"
alias w-helpme=_w_helpme

_w_helpme() {
    echo "Available WoW Scripts:"
    printf "  %-15s %s\n" "w-deployer" "-> local wow deployer"
    printf "  %-15s %s\n" "w-sync-libs" "-> pull local libs to a wow project"
}
