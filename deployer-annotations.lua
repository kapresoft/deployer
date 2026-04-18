--- @alias FilePath string
--
--

--- @class ProjectAddOnInfo
--- @field name string?       @The addon name (a folder in the project) This `"."` for a single-target addon or the addon folder for a multi-addon module.
--- @field as string?         @Deploy addon as this name
--- @field deploy boolean?
--
--

--- @class DeploymentTarget
--- @field name string?       @The deployment name (usually the wow common name)
--- @field deploy boolean?
--- @field dir string
--
--

--- @class DeploymentConfig
--- @field name string
--- @field version string
--- @field deployments table<string, DeploymentTarget>
--- @field addons table<string, ProjectAddOnInfo>
--
--
