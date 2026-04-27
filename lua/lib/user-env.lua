local u = require('util')
-- user-properties.lua is optional and is in .gitignore
local user_props, user_props_path = u.try_require_user_props()
local i, e, pf = u.i, u.e, u.pf

local interfaceDir = 'Interface/AddOns'
local INSTALL_DIR='/Applications/World of Warcraft'

--[[-----------------------------------------------------------------------------
Main
-------------------------------------------------------------------------------]]

if (user_props and user_props.WOW_INSTALL )then
  INSTALL_DIR = user_props.WOW_INSTALL
  i('UserProperties found at:', user_props_path)
  i('Using WoW INSTALL_DIR from user-properties.lua:', INSTALL_DIR)
  if not u:DirExists(INSTALL_DIR) then
    e('WoW INSTALL_DIR does not exist:', INSTALL_DIR)
    os.exit(1)
  end
end

local ADDON_DIR='Interface/AddOns'
local flavors = {
  ['classic'] = "_classic_",
  ['classic_era'] = "_classic_era_",
  ['classic_anniversary'] = "_anniversary_",
  ['retail'] = "_retail_",
  ['classic_beta'] = "_classic_beta_",
  ['classic_ptr'] = "_classic_ptr_",
  ['classic_era_ptr'] = "_classic_era_ptr_",
  ['ptr'] = "_ptr_",
}
--- @class GameVersionInfo
--- @field installDir string
--- @field addOnDir string

local function enrich(env)
  for name, baseDir in pairs(flavors) do
    --- @type GameVersionInfo
    local gv = {
      installDir = INSTALL_DIR,
      addOnDir = ('%s/%s/%s'):format(INSTALL_DIR, baseDir, ADDON_DIR),
    }
    env.wow[name] = gv
  end
end

--- @class GameInstallSpecs
--- @field classic GameVersionInfo
--- @field classic_era GameVersionInfo
--- @field classic_anniversary GameVersionInfo

--- @class DeployerUserConfig
--- @field home string          @The user home dir $HOME
--- @field wow GameInstallSpecs @The world of warcraft game installs
local env = {
    home = os.getenv('HOME'),
    wow = {}
}; enrich(env)

return env
