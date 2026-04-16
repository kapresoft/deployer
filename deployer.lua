--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
local sformat, srep = string.format, string.rep
local tinsert, tconcat = table.insert, table.concat

-- block obviously dangerous system paths
local forbidden = {
  "/", "/System", "/System/", "/usr", "/usr/", "/bin", "/bin/",
  "/sbin", "/sbin/", "/etc", "/etc/", "/var", "/var/",
  "/Applications", "/Applications/"
}

local function dump(t, indent)
  indent = indent or 0
  local pad = srep("  ", indent)

  for k, v in pairs(t) do
    if type(v) == "table" then
      print(pad .. k .. " = {")
      dump(v, indent + 1)
      print(pad .. "}")
    else
      print(pad .. k .. " = " .. tostring(v))
    end
  end
end

--- Formats a table into a single-line comma-separated string.
--- @param t table Table to format
--- @return string CSV formatted string (k=v pairs)
local function fmt(t)
  local parts = {}
  for k, v in pairs(t) do
    tinsert(parts, k .. "=" .. tostring(v))
  end
  return tconcat(parts, ", ")
end

--- Checks if a string starts with a prefix (case-insensitive).
--- @param str string
--- @param match string
--- @return boolean
local function startsWith(str, match)
  if type(str) ~= "string" or type(match) ~= "string" then
    return false
  end
  return str:sub(1, #match):lower() == match:lower()
end

--- @param path string
--- @return boolean, string?
local function isReadableFile(path)
  assert(type(path) == 'string', 'isReadableFile(path): <path> should be a string.')
  local f, err = io.open(path, "r")
  if not f then
    return false, err
  end
  f:close()
  return true
end

local INVALID_FILE_MSGF = 'Invalid config file: <path> (not found or unreadable): %s'
local INVALID_CONFIG_MSG = '-c or --config requires a path to a deployer config; -c /path/to/config.lua'

--- @param configPath string The deployer config file
local function validateConfigPath(configPath)
  assert(type(configPath) == 'string')
  assert(not startsWith(configPath, '--'), INVALID_CONFIG_MSG)
  assert(isReadableFile(configPath), INVALID_FILE_MSGF:format(tostring(configPath)))
end

local function printUsage()
  print("Usage: deploy.lua -c <config.lua>")
  print("  Options:")
  print("         -c|--config [path]  : The path to the deployer config file")
  print("         -n|--dry-run [path] : Dry run")
  print("         -v|--verbose        : Run deployer with additional details")
  print("         -h|--help           : Show this message")
end

--[[-----------------------------------------------------------------------------
Main
-------------------------------------------------------------------------------]]
--- @class DeployerArguments
--- @field configPath string
--- @field verbose boolean?
--- @field dryRun boolean?
--- @field help boolean?


--- @class Deployer
--- @field config DeploymentConfig
--- @field help boolean?
--- @field verbose boolean?
--- @field dryRun boolean?
--- @field args DeployerArguments The command line arguments
--- @field _shortArgs string[]
--- @field _rsyncFlags string[]
local o = {}

--- @private
--- @return DeployerArguments
function o:__ParseArgs()
  --- @type DeployerArguments
  local args = {}
  local configPath
  for i = 1, #arg do
    if arg[i] == "-c" or arg[i] == "--config" then
      args.configPath = arg[i + 1]
    elseif arg[i] == "-n" or arg[i] == "--dry-run" then
      args.dryRun = true
    elseif arg[i] == "-h" or arg[i] == "--help" then
      args.help = true; return args
    elseif arg[i] == "-v" or arg[i] == "--verbose" then
      args.verbose = true
    end
  end
  local valid, msg = pcall(function()
    validateConfigPath(args.configPath)
  end)
  if not valid then
    print(msg); print('')
    printUsage(); print('')
  end
  return args
end

--- @return DeploymentConfig?
function o:LoadDeploymentConfig()
  local configPath = self.args.configPath
  if not configPath then
    printUsage(); return
  end
  local chunk, err = loadfile(configPath)
  if not chunk then
    print("Error loading config:", err); return
  end

  --- @type boolean, DeploymentConfig
  local ok, config = pcall(chunk)
  if not ok then
    print("Error executing config:", config); return nil
  end
  return config
end

--- @param callbackFn fun(addOn:ProjectAddOnInfo) : void
function o:ForEachAddOn(callbackFn)
  for name, addOn in pairs(self.config.addons) do
    addOn.name = name
    if addOn and callbackFn then callbackFn(addOn) end
  end
end

--- @param callbackFn fun(addOn:ProjectAddOnInfo) : void
function o:ForEachEnabledAddOn(callbackFn)
  self:ForEachAddOn(function(addOn) if addOn.deploy == true then callbackFn(addOn) end end)
end

--- @param callbackFn fun(addOn: ProjectAddOnInfo, deployment:DeploymentTarget) : void
function o:ForEachDeployment(callbackFn)
  self:ForEachEnabledAddOn(function(addOn)
    for name, deployment in pairs(self.config.deployments) do
      deployment.name = name
      if deployment and deployment.deploy and callbackFn then
        callbackFn(addOn, deployment)
      end
    end
  end)
end

--- Example: `rsync -rt --delete --prune-empty-dirs --out-format=\ •\ %n\ =\>\ /Applications/wow/_classic_era_/Interface/AddOns/DevSuite/%n --exclude-from=./dev/rsync-excludes.txt`
--- @param src string
--- @param dest string
function o:rsync(shortArgs, rsyncFlags, src, dest)
  local cmd = ('rsync -rt%s %s "%s" "%s"'):format(shortArgs, rsyncFlags, src, dest)
  print('[rsync]: ' .. cmd)
  --local ok = os.execute(cmd)
  --assert(ok, 'Rsync command failed: ' .. cmd)
end

--- Checks if a string is nil or only whitespace
--- @param str string?
--- @return boolean
local function IsBlank(str)
  if str == nil then return true end
  return str:match("^%s*$") ~= nil
end

--- Removes a trailing slash from a string (if present)
--- @param str string?
--- @return string?
local function RemoveTrailingSlash(str)
  if type(str) ~= "string" then return str end
  return (str:gsub("/+$", ""))
end

function o:Main()
  self.args = self:__ParseArgs()
  if self.help then
    printUsage(); return
  end

  self._rsyncFlags = {
    '--delete', '--prune-empty-dirs'
  }
  self._shortArgs = {}
  self.config = self:LoadDeploymentConfig()
  print('args=', fmt(self.args))
  if not self.config then return end
  if self.verbose then tinsert(self._shortArgs, 'v') end

  local shortArgs = ''
  local rsyncFlags = ''
  if self.args.dryRun then tinsert(self._rsyncFlags, '--dry-run') end
  if #self._shortArgs > 0 then shortArgs = tconcat(self._shortArgs) end
  if #self._rsyncFlags > 0 then rsyncFlags = tconcat(self._rsyncFlags, ' ') end

  self:ForEachDeployment(function(addOn, deployment)
    local src = './' .. addOn.name
    local deployAs = addOn.name
    local deployDir = RemoveTrailingSlash(deployment.dir)
    if IsBlank(deployDir) then print('DeployDir is blank'); return end
    if not IsBlank(addOn.as) then deployAs = addOn.as end
    deployAs = '/' .. RemoveTrailingSlash(deployAs)

    local dest = deployDir .. deployAs
    self:rsync(shortArgs, rsyncFlags, src, dest)
  end)
end

o:Main()
