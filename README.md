# deployer
A local deployer application for development purpose.

# Deployer

A minimal Lua CLI for deploying World of Warcraft addons with `rsync`.

## Prerequisites
You’ll need the following to run this tool:

- Bash or Zsh shell
- Lua 5.1+
- rsync (macOS; Homebrew version not tested)
- fswatch (macOS)

## Usage

Run this from the project folder containing your addon (single or multi-addon).

```shell
$ deployer -c|--config <config.lua> [options]
```

### Examples

Use the following examples to get started with deployer:

#### Basic deploy

```shell
$ deployer -c ./dev/deployer-config.lua
$ deployer --config ./dev/deployer-config.lua
```

#### Run in verbose mode and watch folder

```shell
$ deployer -c ./dev/deployer-config.lua -v -w
```

#### Run quiet mode and watch folder

```shell
# quiet mode and watch folder
$ deployer -c ./dev/deployer-config.lua -q -w
```

### Options
Command-line options:

- `-w, --watch`    Run once, then watch the current folder for changes
- `-n, --dry-run`  Preview changes using rsync’s `--dry-run`
- `-v, --verbose`  Enable verbose output
- `-q, --quiet`    Minimize output
- `-h, --help`     Show help

## Config Example: Single AddOn
Use this configuration when your project contains only one addon, rather than multiple addons.

### See Also
- [deployer-annotations.lua](deployer-annotations.lua)
- [user-env.lua](user-env.lua)

```lua

-- a utility that setups up the wow installs
local env = require('user-env')

--- @type DeploymentConfig
local c = {
  version = "1.0.0",
  name = "DevSuite",
  --- @type table<string, ProjectAddOnInfo>
  addons = {
    ["."] = { deploy=true },
  },
  --- @type table<string, DeploymentTarget>
  deployments = {
    ["classic-era"] = {
      deploy = false, dir=env.wow.classic_era.addOnDir
    },
    ["classic"] = {
      deploy = false, dir=env.wow.classic.addOnDir
    },
    ["classic-anniversary"] = {
      deploy = true, dir=env.wow.classic_anniversary.addOnDir,
    },
    ["retail"] = { deploy = false,
      dir=env.wow.retail.addOnDir,
    },
    ["test"] = { 
        deploy = false, dir=path("%s/Desktop/deployer/wow/", env.home)
    },
  }
}
return c
```

## Config Example: Multi-AddOn Project
This configuration is for a project with multiple addons in the project directory.

```lua
local env = require('user-env')

--- @type DeploymentConfig
local c = {
  version = "1.0.0",
  name = "ActionbarPlus",
  --- @type table<string, ProjectAddOnInfo>
  addons = {
    ["ActionbarPlus"] = {
      deploy=true, as="ActionbarPlusLegacy"
    },
    ["ActionbarPlus-Core"]      = { deploy=true },
    ["ActionbarPlus-BarsUI"]    = { deploy=true },
    ["ActionbarPlus-OptionsUI"] = { deploy=false },
  },
  --- @type table<string, DeploymentTarget>
  deployments = {
    ["test"] = {
      deploy = false,
      dir=path("%s/Desktop/deployer/wow/", env.home)
    },
    ["classic-era"] = {
      deploy = true,
      dir=env.wow.classic_era.addOnDir
    },
    ["classic"] = {
      deploy = true,
      dir=env.wow.classic.addOnDir
    },
    ["classic-anniversary"] = {
      deploy = true,
      dir=env.wow.classic_anniversary.addOnDir,
    },
    ["retail"] = {
      deploy = false,
      dir=env.wow.retail.addOnDir,
    }
  }
}
return c
```
### Property: ProjectAddOnInfo.as

The `as` property tells the deployer to deploy the addon under a different name at the destination.

Example:
```
--- @type table<string, ProjectAddOnInfo>
addons = {
  ["ActionbarPlus"] = {
    deploy=true, as="ActionbarPlusLegacy"
  }
}
```
### Properties: deploy
The deployer will only deploy enabled addons to enabled deployments.

SEE: `ProjectAddOnInfo.deploy` and `DeploymentTarget.deploy`

Example:
```
--- @type table<string, ProjectAddOnInfo>
addons = {
  ["ActionbarPlus"] = {
    deploy=true,
  }
},
deployments = {
  ["classic-era"] = {
    deploy = true,
  }
}
```

