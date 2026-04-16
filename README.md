# deployer
A local deployer application for development purpose.

# Deployer

A minimal Lua CLI for deploying World of Warcraft addons with `rsync`.

## Usage

```bash
deployer -c <config.lua> [options]
```

## Options

- `-c, --config`   Path to config file (required)
- `-n, --dry-run`  Preview changes
- `-v, --verbose`  Verbose output
- `-h, --help`     Show help

## Config

```lua
return {
  version = "1.0.0",
  name = "ActionbarPlus",
  projectDir="~/kapresoft/rel/wow-addon-actionbar-plus",
  addons = {
    ["ActionbarPlus"] = { deploy=true, as="ActionbarPlusLegacy" },
    ["ActionbarPlus-Core"] = { deploy=true },
  },
  deployments = {
    ["wow-classic"] = {
      deploy = true,
      dir = "/Applications/wow/_classic_/Interface/AddOns"
    },
    ["wow-classic-anniversary"] = {
      deploy = true,
      dir = "/Applications/wow/_anniversary_/Interface/AddOns"
    }
  }
}
```

## Notes

- Requires Lua 5.4+ and `rsync`
- Uses `rsync --delete` (test with `--dry-run`)
