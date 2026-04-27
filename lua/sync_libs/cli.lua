local argparse = require("argparse")
local u = require('util')
local i, e = u.i, u.e
local o = {}

function o.parse(argv)
  local cmd_name = invokedAs()
  if not cmd_name then
    e('sync_libs/cli:: Could not detect command name (invokedAs() not set)')
    os.exit(1)
  end
  local parser = argparse(cmd_name, "Pull required libraries into your WoW addon project")
  parser:option("-v --version", "Build for a specific version."):argname("VERSION")
  parser:flag("-c --clean", "Clean before building")
  parser:flag("--verbose", "Run in verbose mode")

  --- @class SyncLibs_CLI_Options
  --- @field version string
  --- @field clean? boolean
  --- @field verbose? boolean
  local opts = parser:parse(argv)

  if opts.version then
    local build = tonumber(opts.version)
    if build > 2 then
      e('Unsupported Version:', build)
      parser:error("unsupported version: " .. build)
    end
    i(("Building for version: %s"):format(build))
  end

  return opts
end

return o
