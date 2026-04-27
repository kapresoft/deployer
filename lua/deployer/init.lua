--[[-----------------------------------------------------------------------------
Lua Vars
-------------------------------------------------------------------------------]]
local u = require('util')
local ts = u.ts
local cli = require("deployer.cli")
local iou = require('io-util')
local p, i = u.p, u.i

--[[-----------------------------------------------------------------------------
DeployerMain
-------------------------------------------------------------------------------]]
--- @class DeployerMain
--- @field config DeploymentConfig
--- @field args DeployerArguments The command line arguments
--- @field rsyncExcludeFile? string
--- @field _shortArgs string[]
--- @field _rsyncFlags string[]
local o = {}

--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
local tinsert, tconcat = table.insert, table.concat
local lfs = require("lfs")
local scriptPath = arg and arg[0]

local RSYNC_EXCLUDES_FILENAME = 'rsync-excludes.txt'
local RSYNC_EXCLUDES_FILE = ('%s/%s'):format(deployerHome(), RSYNC_EXCLUDES_FILENAME)
local PROJ_RSYNC_EXCLUDES_FILE = ('./dev/%s'):format(RSYNC_EXCLUDES_FILENAME)

local WATCH_EXCLUDES = {
  "\\.(release|idea|github|vscode)/.*", -- hidden dirs
  "dev/.*", ".*\\.(yaml|yml|sh|md|json|txt)", "_setup\\.*",
}

local sep = '--------------------'

--local function setupModulePath()
--  local dir = scriptPath:match("(.+)/[^/]+$") or "."
--  package.path = dir .. "/?.lua;" .. dir .. "/?/init.lua;" .. package.path
--end; setupModulePath()

assert(type(u) == 'table', 'Failed to load util library: util-lib.lua')

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
  print(("Usage: %s -c <config.lua>\n"):format(invokedAs()))
  print("Deploy WoW addons to your local game installs.\n")
  print("Options:")
  print("   -c|--config [path]    The path to the deployer config file")
  print("   -n|--dry-run [path]   Dry run")
  print("   -v|--verbose          Run deployer with additional details")
  print("   -h|--help             Show this message")
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
--- @field watch boolean?

--- @private
--- @param arg string[]
--- @return DeployerArguments
function o:__ParseArgs(arg)
  --- @type DeployerArguments
  local opts = {}
  for index = 1, #arg do
    if arg[index] == "-c" or arg[index] == "--config" then
      opts.configPath = arg[index + 1]
    elseif arg[index] == "-h" or arg[index] == "--help" then
      opts.help = true; return opts
    elseif arg[index] == "-w" or arg[index] == "--watch" then
      opts.watch = true
    elseif arg[index] == "-n" or arg[index] == "--dry-run" then
      opts.dryRun = true
    elseif arg[index] == "-q" or arg[index] == "--quiet" then
      opts.quiet = true
    elseif arg[index] == "-v" or arg[index] == "--verbose" then
      opts.verbose = true
    end
  end
  local valid, msg = pcall(function()
    validateConfigPath(opts.configPath)
  end)
  if not valid then
    print(msg); print('')
    printUsage(); print('')
  end
  return opts
end

--- @param opts DeployCLI_Options
--- @return DeploymentConfig?
function o:LoadDeploymentConfig(opts)
  local configPath = opts.config
  if not configPath then
    printUsage(); return
  end

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

--- @param opts DeployCLI_Options
--- @return string
local function ReBuildWatchDeployerArgs(opts)
  local execArgsArr = { '-c ' .. opts.config }
  if opts.verbose then
    tinsert(execArgsArr, '-v')
  end
  if opts.quiet then
    tinsert(execArgsArr, '-q')
  end
  if opts.dry_run then
    tinsert(execArgsArr, '-n')
  end
  return tconcat(execArgsArr, ' ')
end

--- @param arg string[]
function o:run(arg)
  local m = 'run'

  local opts = cli.parse(argv)
  self.args = self:__ParseArgs(arg)
  --if opts.help then
  --  printUsage(); return
  --end

  if not opts.quiet then
    if opts.dry_run then u.pf('DryRun: %s', opts.dry_run) end
    u.pf('Script: %s', scriptPath)
    u.pf('Current-Dir: %s', lfs.currentdir())
  end

  -- order of search: rsync excludes file
  -- 1) local
  -- 2) install dir

  local rsyncExcludesFile
  if u:IsReadableFile(PROJ_RSYNC_EXCLUDES_FILE) then
    rsyncExcludesFile = PROJ_RSYNC_EXCLUDES_FILE
    if not opts.quiet then
      printf('%s:: Using project rsync excludes file: %s', m, rsyncExcludesFile)
    end
  elseif u:IsReadableFile(RSYNC_EXCLUDES_FILE) then
    rsyncExcludesFile = RSYNC_EXCLUDES_FILE
    if not opts.quiet then
      printf('%s:: Using rsync excludes file: %s', m, rsyncExcludesFile)
    end
  else
    printf('%s:: Rsync-Excludes not found: %s', m, RSYNC_EXCLUDES_FILE)
    os.exit(1)
  end
  if not opts.quiet then print() end

  local shortArgsArr = {}
  local rsyncFlagsArr = {
    '--delete', '--prune-empty-dirs',
    '--out-format=" • %n => ${dest}/%n"'
  }
  if opts.quiet then tinsert(shortArgsArr, 'q') end

  self.config = self:LoadDeploymentConfig(opts)
  if not self.config then return end
  if opts.verbose then tinsert(shortArgsArr, 'v') end

  local shortArgs = ''
  local rsyncFlags = ''
  if opts.dry_run then tinsert(rsyncFlagsArr, '--dry-run') end
  if rsyncExcludesFile then tinsert(rsyncFlagsArr, '--exclude-from="' .. rsyncExcludesFile .. '"') end

  if #shortArgsArr > 0 then
    shortArgs = tconcat(shortArgsArr)
  end
  if #rsyncFlagsArr > 0 then rsyncFlags = tconcat(rsyncFlagsArr, ' ') end

  local count = self:ForEachDeployment(function(addOn, deployment)
    local deployAs = addOn.name
    local deployDir = u:RemoveTrailingSlash(deployment.dir)

    local validDeployDir, validDeployDirErr = ValidateDeployDir(deployDir)
    if not validDeployDir then
      print(m, ('Deploy dir validation failed for addon[%s]:\n'):format(addOn.name),
        '- ' .. validDeployDirErr);
      return
    end

    -- an addon whose project dir is the main dir (single-addon)
    if addOn.name == '.' then deployAs = self.config.name end
    if not u:IsBlank(addOn.as) then deployAs = addOn.as end
    deployAs = u:RemoveTrailingSlash(deployAs)

    local src = ("%s/."):format(addOn.name)
    if addOn.name == '.' then src = "." end
    local dest = ("%s/%s/."):format(deployDir, deployAs)

    self:rsync(opts, src, dest, shortArgs, rsyncFlags, deployDir, deployment)
  end)
  if count <= 0 then
    printf('%s:: No addons were configured for deployment', m)
    return
  else
    print()
  end
  if opts.watch then self:Watch(opts) end
end

--- @param opts DeployCLI_Options
function o:Watch(opts)
  local m = 'Watch'

  local excludes = WATCH_EXCLUDES
  local execArgs = ReBuildWatchDeployerArgs(opts)
  local excludesValue = u:mergeExcludes(excludes)
  local invoker = "'$DEPLOYER_HOME/bin/deployer.lua'"
  --local cmd = ('fswatch -IE -o -l 0.2 %s .| xargs -n1 -I{} zsh -c "setopt aliases && alias w-deployer=$DEPLOYER_HOME/bin/deployer.lua; which w-deployer; eval \'%s %s\'"'):format(
  --  excludesValue, invokedAs(), execArgs
  --)
  local cmd = ('fswatch -IE -o -l 0.2 %s .| xargs -n1 -I{} zsh -c ". $DEPLOYER_HOME/deployer.zshrc && %s %s"'):format(
    excludesValue, invokedAs(), execArgs
  )
  local fswatch = u:Which('fswatch')
  printf('%s:: Running in watch mode; fswatch=%s', m, fswatch)
  printf('%s:: Command: %s', m, cmd)
  os.execute(cmd)
end

--- Example: `rsync -rt --delete --prune-empty-dirs --out-format=\ •\ %n\ =\>\ /Applications/wow/_classic_era_/Interface/AddOns/DevSuite/%n --exclude-from=./dev/rsync-excludes.txt`
--- @param opts DeployCLI_Options
--- @param dest string
--- @param shortArgs string
--- @param rsyncFlags string
--- @param deployDir string
--- @param deployment DeploymentTarget
function o:rsync(opts, src, dest, shortArgs, rsyncFlags, deployDir, deployment)
  local m = 'rsync'
  local cmd = ('rsync -rt%s %s "%s" "%s"'):format(shortArgs, rsyncFlags, src, dest)
  if not opts.quiet then
    printf('%s [%s]::\nCommand: %s\n', ts(), m, cmd)
  else
    printf('%s [%s:%s]:: %s => %s', ts(), m, deployment.name, src, deployDir)
  end
  local ok = os.execute(cmd)
  assertsafe(ok, '%s [%s]:: ERROR\nRsync command failed:\n%s\n', ts(), m, cmd)
  if not opts.quiet then
    if opts.watch then print() end
    printf('%s [%s:%s]:: Deploy complete\n  • deployDir=[ %s ]\n  • src=[ %s ]\n  • target=[ %s ]\n%s',
      ts(), m, deployment.name, deployDir, src, dest, sep)
  end
end

--[[-----------------------------------------------------------------------------
Return a new instance for thread safety
-------------------------------------------------------------------------------]]
local M = {}
function M:new() return setmetatable({}, { __index = o }) end

return M
