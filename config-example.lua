--- @type DeploymentConfig
local c = {
  version = "1.0.0",
  name = "ActionbarPlus",
  projectDir="~/addons/wow-addon-actionbar-plus",
  addons = {
    ["ActionbarPlus"]           = { deploy=true },
    ["ActionbarPlus-Core"]      = { deploy=true },
    ["ActionbarPlus-BarsUI"]    = { deploy=true },
    ["ActionbarPlus-OptionsUI"] = { deploy=true },
  },
  deployments = {
    ["wow-classic"] = {
      deploy = true,
      dir="/Applications/World of Warcraft/_classic_/Interface/AddOns"
    },
    ["wow-classic-anniversary"] = {
      deploy = true,
      dir=os.getenv("WOW_CLASSIC_ANNIV_HOME")
    }
  }
}

return c
