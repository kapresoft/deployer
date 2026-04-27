local sformat, srep = string.format, string.rep
local tinsert, tconcat = table.insert, table.concat
local lfs = require("lfs")

local PREFIX_CHAR_WIDTH = 15
--[[-----------------------------------------------------------------------------
Support Functions
-------------------------------------------------------------------------------]]
--- Used for log prefixes
--- @return string @The function name of the caller
local function get_caller3()
  local info = debug.getinfo(3, "Sn") -- Level 3 = caller of this function
  local name = info.name or ""
  local file = info.source:match("([^/]+)%.lua$") or "?"
  local ret = file .. ":" .. name
  local size = PREFIX_CHAR_WIDTH
  if #ret > size then
    ret = ret:sub(1, size - 3) .. "..."
  end
  return ret
end


--[[-----------------------------------------------------------------------------
Global Functions
-------------------------------------------------------------------------------]]
--- @param pathSpec string  @The string format
--- @param ... string       @The args to a string format
function path(pathSpec, ...)
  if type(pathSpec) == 'string' and select('#', ...) > 0 then
    return pathSpec:format(...);
  end
  return nil
end

--- @param cond boolean
--- @param msgStringOrFunction string|fun():string  @The string message, the message format string, or function
--- @param ... any                                  @The args to a string format
function assertsafe(cond, msgStringOrFunction, ...)
  if cond then return end
  local error = msgStringOrFunction or "non-fatal assertion failed";
  if type(msgStringOrFunction) == 'string' and select('#', ...) > 0 then
    error = msgStringOrFunction:format(...);
  elseif type(msgStringOrFunction) == 'function' then
    error = msgStringOrFunction(...);
  end
  assert(cond, error)
end

--- @param stringOrFormat string  @The string or string format
--- @param ... any                @The args to a string format
function printf(stringOrFormat, ...)
  assertsafe(type(stringOrFormat) == 'string', 'printf(msgStringOrFunction, ...): <stringOrFormat> must be a string')
  local msg = stringOrFormat or "non-fatal assertion failed";
  if type(stringOrFormat) == 'string' and select('#', ...) > 0 then
    msg = stringOrFormat:format(...);
  end
  print(msg)
end

--[[-----------------------------------------------------------------------------
Utility Methods
-------------------------------------------------------------------------------]]
--- @class DeployerUtil
local o = {}

--- Used for log prefixes
--- @param level? number @Caller Level 1 or above
--- @return string @The function name of the caller
function o.caller(level)
  if level then
    assert(type(level) == 'number', 'o.caller(level): {level} must be a number')
    assert(level >= 1, 'o.caller(level): {level} must be 1 level or above')
  end
  local info = debug.getinfo(level, "Sn") -- Level N = caller of this function
  local name = info.name or ""
  local file = info.source:match("([^/]+)%.lua$") or "?"
  local ret = file .. ":" .. name
  local size = PREFIX_CHAR_WIDTH
  if #ret > size then
    ret = ret:sub(1, size - 3) .. "..."
  end
  return ret
end

--- Formats a value into a single-line string.
--- @param t any
--- @return string
function o.fmt(t)
  local tt = type(t)

  if tt ~= "table" then
    if tt == "function" then
      return "function[]: " .. tostring(t)
    end
    return tostring(t)
  end

  local parts = {}
  for k, v in pairs(t) do
    local vt = type(v)
    if vt == "function" then
      tinsert(parts, k .. "=function[]: " .. tostring(v))
    else
      tinsert(parts, k .. "=" .. tostring(v))
    end
  end

  return tconcat(parts, ", ")
end

function o.dump(t, indent)
  indent = indent or 0
  local pad = srep("  ", indent)

  for k, v in pairs(t) do
    if type(v) == "table" then
      print(pad .. k .. " = {")
      o.dump(v, indent + 1)
      print(pad .. "}")
    else
      print(pad .. k .. " = " .. tostring(v))
    end
  end
end

--- @return string
function o.ts()
  local sec = os.time()
  local ms = math.floor((os.clock() % 1) * 1000)
  --return os.date("%Y-%m-%d %H:%M:%S", sec) .. sformat(".%03d", ms)
  return os.date("%H:%M:%S", sec) .. sformat(".%03d", ms)
end

function echo(...)
  local args = {}
  for i = 1, select("#", ...) do
    args[i] = tostring(select(i, ...))
  end
  print(tconcat(args, " "))
end

function o.p(...)
  echo("[" .. o.ts() .. "]", ...)
end

--- @param stringOrFormat string  @The string or string format
--- @param ... any                @The args to a string format
function o.pf(stringOrFormat, ...)
  assertsafe(type(stringOrFormat) == 'string', 'pf(stringOrFormat, ...): <stringOrFormat> must be a string')
  local msg = stringOrFormat or "non-fatal assertion failed";
  if type(stringOrFormat) == 'string' and select('#', ...) > 0 then
    msg = stringOrFormat:format(...);
  end
  local marginFmt = '%-' .. PREFIX_CHAR_WIDTH .. 's'
  print(sformat('[%s] ' .. marginFmt .. ' %s', o.ts(), get_caller3(), msg))
end

--- @param callerLvl string @The name of the caller
--- @param stringOrFormat string  @The string or string format
--- @param ... any                @The args to a string format
function o.pff(callerLvl, stringOrFormat, ...)
  assertsafe(type(stringOrFormat) == 'string', 'pf(stringOrFormat, ...): <stringOrFormat> must be a string')
  local msg = stringOrFormat or "non-fatal assertion failed";
  if type(stringOrFormat) == 'string' and select('#', ...) > 0 then
    msg = stringOrFormat:format(...);
  end
  local c = o.caller(callerLvl)
  local marginFmt = '%-' .. PREFIX_CHAR_WIDTH .. 's'
  print(sformat('[%s] ' .. marginFmt .. ' %s', o.ts(), c, msg))
end

function o.i(...)
  local prefix = get_caller3()
  local msg = ""
  if select("#", ...) > 0 then
    local args = {}
    for i = 1, select("#", ...) do
      args[i] = tostring(select(i, ...))
    end
    msg = tconcat(args, " ")
  end
  local marginFmt = '%-' .. PREFIX_CHAR_WIDTH .. 's'
  echo(sformat('[%s] ' .. marginFmt .. ' %s', o.ts(), prefix, msg))
end

function o.e(...)
  local prefix = get_caller3()
  local msg = ""
  if select("#", ...) > 0 then
    local args = {}
    for i = 1, select("#", ...) do
      args[i] = tostring(select(i, ...))
    end
    msg = tconcat(args, " ")
  end
  local marginFmt = '%-' .. PREFIX_CHAR_WIDTH .. 's'
  echo(sformat('[%s] ' .. marginFmt .. ' [ERROR] %s', o.ts(), prefix, msg))
end

--- @return UserProperties
--- @return path @The path to the file
function o.try_require_user_props()
  local path = deployerHome() .. "/user-properties.lua"
  local f = io.open(path)
  if f then
    f:close()
    return dofile(path), path
  end
  return nil   -- optional file not found
end

--function o.i3(prefix, ...)
--  echo("[" .. o.ts() .. "] " .. prefix .. "::", ...)
--end
--
--function o.e2(...)
--  echo("[" .. o.ts() .. "] ERROR", ...)
--end

--- Merges exclude patterns for fswatch
--- @param excludes string[]
--- @return string
function o:mergeExcludes(excludes)
  assertsafe(self:isArray(excludes), "mergeExcludes(excludes): <excludes> should be a string[]")
  if excludes[1] == nil then return "" end

  local parts = {}
  for _, e in ipairs(excludes) do
    if not self:IsBlank(e) then
      parts[#parts + 1] = ('-e "%s"'):format(e)
    end
  end

  return tconcat(parts, " ")
end

function o:isArray(t)
  if type(t) ~= "table" then return false end
  local n = 0
  for k, _ in pairs(t) do
    if type(k) ~= "number" then return false end
    n = n + 1
  end
  return n == #t
end

--- Checks if a string is nil or only whitespace
--- @param str string?
--- @return boolean
function o:IsBlank(str)
  if str == nil then return true end
  if type(str) ~= "string" then return false end
  return str:match("^%s*$") ~= nil
end

--- Checks if a string starts with a prefix (case-insensitive).
--- @param str string
--- @param match string
--- @return boolean
function o:StartsWith(str, match)
  if type(str) ~= "string" or type(match) ~= "string" then return false end
  return str:sub(1, #match):lower() == match:lower()
end

--- Removes a trailing slash from a string (if present)
--- @param str string?
--- @return string?
function o:RemoveTrailingSlash(str)
  if type(str) ~= "string" then return str end
  return (str:gsub("/+$", ""))
end

--- @param path string
--- @return boolean, string?
function o:IsReadableFile(path)
  assert(type(path) == 'string', 'isReadableFile(path): <path> should be a string.')
  local f, err = io.open(path, "r")
  if not f then return false, err end
  f:close()
  return true
end

--- @param path string
--- @return boolean, string?
function o:FileExists(path) return self:IsReadableFile(path) end

--- @param path string
--- @return boolean
function o:DirExists(path)
  local attr = lfs.attributes(path)
  return attr ~= nil and attr.mode == "directory"
end

--- @param path string  @A file path
--- @return string      @The directory name
function o:Dirname(path)
  local f = io.popen(('dirname "%s"'):format(path))
  local result = f:read("*l")
  f:close()
  return result
end

--- @param executable string  @A file path
--- @return string?      @The value
function o:Which(executable)
  local f = io.popen(('command -v "%s" 2>/dev/null'):format(executable))
  local result = f:read("*l")
  f:close()
  return result
end

--- Checks if a path is a directory
--- @param dir string
--- @return boolean, string?
function o:IsDir(dir)
  if type(dir) ~= "string" then return false, 'IsDir(dir): <dir> should be a string' end
  return pcall(lfs.dir, dir)
end

--- @param dirPath string
--- @return boolean       @true if the dir can be locked
--- @return string?       @The error message
function o:CanLockDir(dirPath)
  local lock, err = lfs.lock_dir(dirPath)
  if not lock then
    return false, err
  else
    lock:free()

    lock, err = lfs.lock_dir(dirPath)
    if not lock then return false, err end
    lock:free()
  end
  return true
end

--- @param _dirPath string
--- @return boolean, string?
function o:IsWriteableDir(_dirPath)
  if type(_dirPath) ~= "string" then return false, "IsWriteableDir(dirPath): <dirPath> should be a string" end

  local dirPath = self:RemoveTrailingSlash(_dirPath)
  local isDir, isDirErr = self:IsDir(dirPath)
  if not isDir then
    return false, ('Invalid path: %s (must be a directory); err=[%s]'):format(dirPath, isDirErr)
  end

  -- try and lock
  local canLock, err = self:CanLockDir(dirPath)
  if not canLock then
    return false, err
  end
  return true
end

--- @generic T
--- @param configPath string @The path to the lua config file
--- @return table|T      @The loaded config
function o:LoadConfig(configPath)
  assertsafe(type(configPath) == 'string', 'Util:LoadConfig(configPath): <configPath> should be a string, but was=%s',
    tostring(configPath))

  local chunk, err = loadfile(configPath)
  if not chunk then
    printf("[ERROR]: Failed to load config\n  •%s", err); return nil
  end

  --- @type boolean, DeploymentConfig
  local ok, config = pcall(chunk)
  if not ok then
    printf("[ERROR]: Unexpected error executing config\n  •%s", config); return nil
  end

  return config
end

return o
