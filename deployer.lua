--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
local sformat, srep = string.format, string.rep
local tinsert, tconcat = table.insert, table.concat
local lfs = require("lfs")
local scriptPath = arg and arg[0]
local RSYNC_EXCLUDES_FILENAME = 'rsync-excludes.txt'
local sep = '--------------------'

local function setupModulePath()
  local dir = scriptPath:match("(.+)/[^/]+$") or "."
  package.path = dir .. "/?.lua;" .. dir .. "/?/init.lua;" .. package.path
end; setupModulePath()

local u = require("util-lib")
assert(type(u) == 'table', 'Failed to load util library: util-lib.lua')

local excludeFile = u:Dirname(scriptPath) .. '/rsync-excludes.txt'

--[[-----------------------------------------------------------------------------
Start
-------------------------------------------------------------------------------]]
--- Validates that a deployment directory is safe and writable
--- @param dest string
--- @return boolean, string? @Validation status and the optional error message
local function ValidateDeployDir(dest)
  if type(dest) ~= "string" then
    return false, 'ValidateDeployDir(dest): <dest> should be a string.'
  end
  if u:IsBlank(dest) then
    return false, ('DeployDir is blank; dir=[%s]'):format(dest)
  end

  -- normalize (remove trailing slash)
  dest = u:RemoveTrailingSlash(dest)

  local isWritable, isWritableErr = u:IsWriteableDir(dest)
  if not isWritable then
    return false, ('Dir is not writable; dir=[%s]; msg=[%s]'):format(dest, isWritableErr)
  end

  return true
end

local INVALID_FILE_MSGF = 'Invalid config file: <path> (not found or unreadable): %s'
local INVALID_CONFIG_MSG = '-c or --config requires a path to a deployer config; -c /path/to/config.lua'

--- @param configPath string The deployer config file
local function validateConfigPath(configPath)
  assert(type(configPath) == 'string')
  assert(not u:StartsWith(configPath, '--'), INVALID_CONFIG_MSG)
  assert(u:IsReadableFile(configPath), INVALID_FILE_MSGF:format(tostring(configPath)))
end

local function printUsage()
  print("Usage: deploy.lua -c <config.lua>")
  print("  Options:")
  print("         -c|--config [path]  : The path to the deployer config file")
  print("         -n|--dry-run [path] : Dry run")
  print("         -v|--verbose        : Run deployer with additional details")
  print("         -h|--help           : Show this message")
end

--- @param conf table
local function PreVerify(conf)
  assert(type(conf) == "table", "Invalid config: expected table, but was " .. type(conf))

  assert(conf.addons ~= nil and next(conf.addons) ~= nil,
    "Invalid config: 'addons' must not be empty")

  assert(conf.deployments ~= nil and next(conf.deployments) ~= nil,
    "Invalid config: 'deployments' must not be empty")

  for name, addon in pairs(conf.addons) do
    assert(type(name) == "string" and not u:IsBlank(name),
      "Invalid addon entry: name is blank")

    assert(type(addon) == "table",
      ("Invalid addon '%s': expected table"):format(name))

    assert(not u:IsBlank(name),
      ("Invalid addon '%s': name is blank"):format(name))
  end

  for name, dep in pairs(conf.deployments) do
    assert(type(name) == "string" and not u:IsBlank(name),
      "Invalid deployment entry: name is blank")

    assert(type(dep) == "table",
      ("Invalid deployment '%s': expected table"):format(name))

    assert(not u:IsBlank(dep.dir),
      ("Invalid deployment '%s': dir is blank"):format(name))
  end
end

--[[-----------------------------------------------------------------------------
Main
-------------------------------------------------------------------------------]]
--- @class DeployerArguments
--- @field configPath string
--- @field verbose boolean?
--- @field dryRun boolean?
--- @field help boolean?
--- @field quiet boolean?

--- @class Deployer
--- @field config DeploymentConfig
--- @field args DeployerArguments The command line arguments
--- @field rsyncExcludeFile? string
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
    elseif arg[i] == "-h" or arg[i] == "--help" then
      args.help = true; return args
    elseif arg[i] == "-n" or arg[i] == "--dry-run" then
      args.dryRun = true
    elseif arg[i] == "-q" or arg[i] == "--quiet" then
      args.quiet = true
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
  if not configPath then printUsage(); return end

  local config = u:LoadConfig(configPath)
  if not config then return nil end

  local ok, err = pcall(function() PreVerify(config) end)
  if not ok then
    print("[ERROR]: Config pre-verification failed\n  •" .. err); return nil
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
--- @return number @The number of deployments
function o:ForEachDeployment(callbackFn)
  assertsafe(type(callbackFn) == 'function', 'ForEachDeployment(callbackFn): <callbackFn> should be a function')
  local count = 0
  for name, deployment in pairs(self.config.deployments) do
    deployment.name = name
    if deployment and deployment.deploy then
      self:ForEachEnabledAddOn(function(addOn)
        count = count + 1
        callbackFn(addOn, deployment)
      end)
    end
  end
  return count
end

function o:Exec()
  local m = 'Exec'

  self.args = self:__ParseArgs()
  if self.args.help then printUsage(); return end

  if not self.args.quiet then
    printf('%s:: Script: %s', m, scriptPath)
    printf('%s:: Current-Dir: %s', m, lfs.currentdir())
  end

  local excludesFile = ('%s/%s'):format(u:Dirname(scriptPath), RSYNC_EXCLUDES_FILENAME)
  if u:IsReadableFile(excludesFile) then
    self.rsyncExcludeFile = excludesFile
    if not self.args.quiet then
      printf('%s:: Rsync-Excludes: %s', m, self.rsyncExcludeFile)
    end
  end
  if not self.args.quiet then print() end

  self._shortArgs = {}
  self._rsyncFlags = {
    '--delete', '--prune-empty-dirs', '--out-format=" • %n => ${dest}/%n"'
  }
  if self.args.quiet then tinsert(self._shortArgs, 'q') end

  self.config = self:LoadDeploymentConfig()
  --print('args=', fmt(self.args))
  if not self.config then return end
  if self.args.verbose then tinsert(self._shortArgs, 'v') end

  local shortArgs = ''
  local rsyncFlags = ''
  if self.args.dryRun then tinsert(self._rsyncFlags, '--dry-run') end
  if self.rsyncExcludeFile then  tinsert(self._rsyncFlags, '--exclude-from="' .. self.rsyncExcludeFile .. '"') end

  if #self._shortArgs > 0 then shortArgs = tconcat(self._shortArgs) end
  if #self._rsyncFlags > 0 then rsyncFlags = tconcat(self._rsyncFlags, ' ') end

  local count = self:ForEachDeployment(function(addOn, deployment)
    local deployAs = addOn.name
    local deployDir = u:RemoveTrailingSlash(deployment.dir)

    local validDeployDir, validDeployDirErr = ValidateDeployDir(deployDir)
    if not validDeployDir then
      --Users/tony/Desktop/deployer/World of Warcraft/
      print(m, ('Deploy dir validation failed for addon[%s]:\n'):format(addOn.name),
          '- ' .. validDeployDirErr);
      return
    end

    if not u:IsBlank(addOn.as) then deployAs = addOn.as end
    deployAs = u:RemoveTrailingSlash(deployAs)

    local src = ("%s/."):format(addOn.name)
    local dest = ("%s/%s/."):format(deployDir, deployAs)

    self:rsync(src, dest, shortArgs, rsyncFlags, deployDir)
  end)
  if count <= 0 then
    printf('%s:: No addons were configured for deployment', m)
  end
end

--- Example: `rsync -rt --delete --prune-empty-dirs --out-format=\ •\ %n\ =\>\ /Applications/wow/_classic_era_/Interface/AddOns/DevSuite/%n --exclude-from=./dev/rsync-excludes.txt`
--- @param dest string
--- @param shortArgs string
--- @param rsyncFlags string
--- @param deployDir string
function o:rsync(src, dest, shortArgs, rsyncFlags, deployDir)
  local m = 'rsync'
  local cmd = ('rsync -rt%s %s "%s" "%s"'):format(shortArgs, rsyncFlags, src, dest)
  if not self.args.quiet then
    printf('%s [%s]::\nCommand: %s\n', ts(), m, cmd)
  else
    printf('%s [%s]:: %s => %s', ts(), m, src, dest)
  end
  local ok = os.execute(cmd)
  assertsafe(ok, '%s [%s]:: ERROR\nRsync command failed:\n%s\n', ts(), m, cmd)
  if not self.args.quiet then
    print()
    printf('%s [%s]:: Deploy complete\n  • deployDir=[ %s ]\n  • src=[ %s ]\n  • target=[ %s ]\n%s',
        ts(), m, deployDir, src, dest, sep)
  end
end

o:Exec()

