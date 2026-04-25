local lfs = require("lfs")

--- @class IOUtil
local o = {}

--- @return boolean
function o:file_exists(path)
    local attr = lfs.attributes(path)
    return attr and attr.mode == "file"
end

--- @return boolean
function o:dir_exists(path)
    local attr = lfs.attributes(path)
    return attr and attr.mode == "directory"
end

--- Check and remove
--- @return boolean
function o:remove_dir(path)
    local attr = lfs.attributes(path)
    if attr and attr.mode == "directory" then
        -- Recursively remove contents
        for file in lfs.dir(path) do
            if file ~= "." and file ~= ".." then
                local f = path .. "/" .. file
                local fa = lfs.attributes(f)
                if fa.mode == "directory" then
                    self:remove_dir(f)
                else
                    os.remove(f)
                end
            end
        end
        -- Remove the now-empty directory
        return lfs.rmdir(path)
    end
    return false
end

--- @param cmd string @A system/shell command
--- @return boolean @Success flag
--- @return string  @Error message or blank
--- @return number?  @Error code
function o.execute(cmd)
    local handle = io.popen(cmd .. " 2>&1; echo $?")
    if not handle then return -1, "" end
    local output = handle:read("*a"):gsub("\n$", "")
    local exit_code = tonumber(output:match("(%d+)$")) or nil
    local msg = output:gsub("\n?%d+$", "")
    handle:close()
    return exit_code == 0, msg, exit_code
end

return o
