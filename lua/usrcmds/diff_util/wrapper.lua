---@module 'usrcmds.wrapper'
--- Cross-platform wrapper for diff executable
--- Automatically uses diff.exe on Windows and diff on Unix/macOS
--- Integrates with ENV computed by system.env

local M = {}
local env = require("system.env")

-- Determine the platform-specific diff command
---@return string
function M.get_diff_cmd()
    local e = env.get()
    if e.is_windows then
        return "diff.exe" -- Ensure it points to GNU diff in PATH
    else
        return "diff"
    end
end

-- Build a full diff shell command
---@param source string
---@param target string|nil
---@param opts table
---@return string
function M.build_diff_command(source, target, opts)
    local diff_cmd = M.get_diff_cmd()
    local flags = {}

    if opts.context then table.insert(flags, "-c") end
    if opts.unified then table.insert(flags, "-u") end
    if opts.recursive then table.insert(flags, "-r") end

    local flag_str = table.concat(flags, " ")

    -- Escape paths for shell
    local function escape_path(path)
        if not path then return "" end
        return path:gsub("([%s%$`\\])", "\\%1")
    end

    local src = escape_path(source)
    local tgt = target and escape_path(target) or ""

    return string.format("%s %s %s %s", diff_cmd, flag_str, tgt, src)
end

return M
