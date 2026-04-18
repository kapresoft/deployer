
local interfaceDir = 'Interface/AddOns'

local INSTALL_DIR='/Applications/wow'
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
