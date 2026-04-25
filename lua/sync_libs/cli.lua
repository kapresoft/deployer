local argparse = require("argparse")
local u = require('util')
local i, e = u.i, u.e
local o = {}

function o.parse(argv)

  local parser = argparse("wow-sync-libs", "Pull required libraries into your WoW addon project")
  parser:option("-v --version", "Build for a specific version."):argname("VERSION")
  parser:flag("-c --clean", "Clean before building")

  --- @class SyncLibs_CLI_Options
  --- @field version string
  --- @field clean boolean
  local opts = parser:parse(argv)

  --print('args.help=', args.help, 'version=', args.version, 'clean=', args.clean)

  local build_version = opts.version

  if build_version then
    local build = tonumber(build_version)
    if build > 2 then
      e('Unsupported Version:', build)
      parser:error("unsupported version: " .. build)
    end
    i(("Building for version: %s"):format(build))
  end

  return opts
end

return o


