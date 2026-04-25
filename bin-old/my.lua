#!/usr/bin/env lua

local function get_absolute_path(path)
  -- Exhaustive list of fallback methods
  -- Each method is a function that takes a path and returns the result or nil
  local methods = {
    -- Linux/GNU (most common)
    function(p)
      print('xx trying from readlink')
      return os_execute("xxreadlink -f '" .. p:gsub("'", "'\\''") .. "' 2>/dev/null")
    end,
    -- GNU coreutils
    function(p)
      print('xx trying from realpath')
      return os_execute("realpath '" .. p:gsub("'", "'\\''") .. "' 2>/dev/null")
    end,
    -- Python 3
    function(p)
      return os_execute("python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' '" ..
      p:gsub("'", "'\\''") .. "' 2>/dev/null")
    end,
    -- Python 2
    function(p)
      return os_execute("python -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' '" ..
      p:gsub("'", "'\\''") .. "' 2>/dev/null")
    end,
    -- Perl
    function(p)
      return os_execute("perl -MCwd=realpath -e 'print realpath(shift)' '" .. p:gsub("'", "'\\''") .. "' 2>/dev/null")
    end,
  }

  for _, method in ipairs(methods) do
    local result = method(path)
      print('xxx result from=', method, 'result=', result)
    if result and result ~= "" then
      return result
    end
  end

  -- Ultimate fallback: just return the original path
  return path
end

-- Helper function to execute commands and get output
function os_execute(cmd)
  local handle = io.popen(cmd)
  if not handle then return nil end

  local result = handle:read("*a"):gsub("^%s+", ""):gsub("%s+$", "")
  local success, exit_type, exit_code = handle:close()

  -- close() returns true on success, nil + "exit" + code on failure
  if success and result ~= "" then
    return result
  end
  return nil
end

-- Usage
local function get_script_dir()
  local source = debug.getinfo(1, "S").source:match("^@(.*)") or "."
  local resolved = get_absolute_path(source)
  return resolved:match("(.*)/") or "."
end

local script_dir = get_script_dir()
print("Resolved script directory: " .. script_dir)


print('script:', arg and arg[0])
local path = get_absolute_path(arg[0])
print('script-loc:', path)
