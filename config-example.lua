--- @type DeploymentConfig
local c = {
  version = "1.0.0",
  name = "ActionbarPlus",
  projectDir="/Users/tony/sandbox/github/kapresoft/rel/wow-addon-actionbar-plus",
  addons = {
    ["ActionbarPlus"]           = {
      deploy=true,
      as="ActionbarPlusLegacy"
    },
    ["ActionbarPlus-Core"]      = {
      deploy=true
    },
    ["ActionbarPlus-BarsUI"]    = {
      deploy=false
    },
    ["ActionbarPlus-OptionsUI"] = {
      deploy=false
    },
  },

  deployments = {
    ["test"] = {
      deploy = true,
      dir="/Users/tony/Desktop/deployer/World of Warcraft"
    },
    ["wow-classic"] = {
      deploy = false,
      dir=os.getenv("WOW_CLASSIC_HOME")
    },
    ["wow-classic-anniversary"] = {
      deploy = false,
      dir=os.getenv("WOW_CLASSIC_ANNIV_HOME")
    }
  }
}

return c
