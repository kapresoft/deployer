-- lua/sync_libs/init.lua
local o = {}
local u = require('util')
local cli = require("sync_libs.cli")
local iou = require('io-util')
local p, i = u.p, u.i

local DEPLOYER_HOME = os.getenv('DEPLOYER_HOME')
local INVOKED_AS = os.getenv('INVOKED_AS')

--[[-----------------------------------------------------------------------------
Local Vars
-------------------------------------------------------------------------------]]
local RELEASE_SCRIPT      = './dev/release.sh'
local RELEASE_SCRIPT_ARGS = '-dz'
local BUILD_DIR           = './.release'

local PKGMETA_NAME        = "setup"
local TOC_FILE            = ("%s.toc"):format(PKGMETA_NAME)
local SETUP_TOC           = ("%s/misc/%s.toc"):format(DEPLOYER_HOME, PKGMETA_NAME)
local PKGMETA_FILE        = ("%s.yml"):format(PKGMETA_NAME)
local TEMP_TOC            = "_" .. TOC_FILE
local TEMP_PKGMETA        = "_" .. PKGMETA_FILE

--[[-----------------------------------------------------------------------------
Main
-------------------------------------------------------------------------------]]
function o:run(argv)
  -- parse args, call copier/config helpers, etc.
  local opts = cli.parse(argv)

  if opts.verbose then
    p('DEPLOYER_HOME=', DEPLOYER_HOME)
    p('INVOKED_AS=', INVOKED_AS)
  end

  if opts.clean then
    local relDir = './.release'
    if iou:dir_exists(relDir) then
      i('Cleaning Release Dir:', relDir)
      local rm_success = iou:remove_dir(relDir)
      if rm_success then
        i('Cleaning Release Dir: SUCCESS')
      end
    end
  end

  self:cpTocFile()
  self:cpPkgmeta(opts)
  self:runPackager()
  self:cleanup()
end

function o:runPackager()
  local cmd = ("%s %s -r %q -m %q"):format(
    RELEASE_SCRIPT,
    RELEASE_SCRIPT_ARGS,
    BUILD_DIR,
    TEMP_PKGMETA
  )
  i('Executing:', cmd)

  if not os.execute(cmd) then
    u.e('Failed:', cmd)
    os.exit(1)
  end
  i('Done:', cmd)
end

--- Copy dev pkgmeta file to temp _setup file
--- @param opts SyncLibs_CLI_Options
function o:cpPkgmeta(opts)
  local pkgmeta = PKGMETA_FILE
  if opts.version == "2" then
    pkgmeta = ('%sV%s.yml'):format(PKGMETA_NAME, opts.version)
  end
  local pkgmeta_path = ("./dev/%s"):format(pkgmeta)
  if iou:file_exists(pkgmeta_path) then
    i('pkgmeta file is:', pkgmeta_path)
  else
    u.e('pkgmeta file not found:', pkgmeta_path)
    os.exit(1)
  end

  -- ./_setup
  local cpCmd = ('cp %q %q'):format(pkgmeta_path, TEMP_PKGMETA)
  i('Executing:', cpCmd)

  local success, msg = iou.execute(cpCmd)
  if not success then
    u.e('Failed:', msg)
    os.exit(1)
  end

  if not iou:file_exists(TEMP_PKGMETA) then
    u.e('Missing:', TEMP_PKGMETA)
    os.exit(1)
  end
end

function o:cpTocFile()
  local srcToc = './dev/' .. TOC_FILE

  if not iou:file_exists(srcToc) then
    if iou:file_exists(SETUP_TOC) then
      srcToc = SETUP_TOC
    end
  end
  if not iou:file_exists(srcToc) then
    u.e('Could not find an available setup.toc file')
    os.exit(1)
  end
  i('Using toc:', srcToc)

  local cpCmd = ('cp %q %q'):format(srcToc, TEMP_TOC)
  i('Executing:', cpCmd)
  local success, msg = iou.execute(cpCmd)
  if not success then
    u.e('Failed:', msg)
  end
  if not iou:file_exists(TEMP_TOC) then
    u.e('Failed to copy:', TEMP_TOC)
    os.exit(1)
  end
end

function o:cleanup()
  local files = { TEMP_TOC, TEMP_PKGMETA }
  i('Scrubbing Temp Files:', table.concat(files, ', '))
  for _, f in ipairs(files) do
    if iou:file_exists(f) then
      local success, msg = iou.execute('rm ' .. f)
      if not success then
        u.e('Failed:', f)
        os.exit(1)
      end
    end
  end
  i('Scrubbed:', table.concat(files, ', '))
end

--[[-----------------------------------------------------------------------------
Return a new instance for thread safety
-------------------------------------------------------------------------------]]
local M = {}
function M:new() return setmetatable({}, { __index = o }) end
return M
