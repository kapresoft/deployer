local argparse = require("argparse")
local u = require('util')
local i, e = u.i, u.e
local o = {}

function o.parse(argv)
  local cmd_name = invokedAs()
  if not cmd_name then
    e('deployer/cli:: Could not detect command name (invokedAs() not set)')
    os.exit(1)
  end
  local parser = argparse(cmd_name, "Pull required libraries into your WoW addon project")
  parser:option("-c --config --conf", "Build for a specific version."):argname("CONFIG")
  parser:flag("-w --watch", "Deploy and watch for changes")
  parser:flag("-q --quiet", "Run in quiet mode")
  parser:flag("-n --dry-run", "Dry run mode (simulate deployment)")
  parser:flag("-v --verbose", "Run in verbose mode")

  --- @class DeployCLI_Options
  --- @field config string    @The path to the deployer config file
  --- @field quiet boolean?   @Run in quiet mode
  --- @field watch boolean?   @Deploy and watch for changes
  --- @field verbose? boolean @Run with more details
  --- @field dry_run? boolean  @Dry run mode (simulate deployment)
  local opts = parser:parse(argv)

  u.pf('opts= %s', u.fmt(opts))

  return opts
end

return o
