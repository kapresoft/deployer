# deployer
CLI tools for WoW addon devs: build, sync, and deploy.

## CLI Tools
### deployer.lua (w-deploy)

Deploy addons to your local WoW install with watch mode —
automatically detects changes and redeploys instantly.

### sync-libs.lua (w-sync-libs)
Pull external libraries and dependencies into your WoW addon project.

Reads dev/setup.yaml to fetch required libs from repos and syncs
them into your local project directory. Must be run from the project root.

## Prerequisites
You’ll need the following to run this tool:

- Bash or Zsh shell
- Lua 5.3+
- rsync (macOS; Homebrew version not tested)
- fswatch (macOS)

## Installation

Pull down this repository from github
Can also execute the following command for instructions
```shell
./profile-helper

## Output:
Add this line to your ~/.zshrc file:

eval $(/path/to/deployer/profile-helper.sh -t macos -s)

Then restart your shell or run:
  source ~/.zshrc
```

Edit your ~/.zshrc
Add this line (anywhere)

```shell
eval $(/path/to/deployer/profile-helper.sh -t macos -s)
```
Type `w-helpme`
Output:
```shell
~> w-helpme
Available WoW Scripts:
  w-deployer      -> local wow deployer
  w-sync-libs     -> pull local libs to a wow project
~>
```

## Usage: Deployer

Run this from the project folder containing your addon (single or multi-addon).

A minimal Lua CLI for deploying World of Warcraft addons with `rsync`.

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

