---@module 'custom.markdown.handler.file'
--- Open local file under cursor

local M = {}

--- Detect if line contains a file link
---@param line string
---@return boolean
function M.is_file_line(line)
    local target = line:match("%[.-%]%((.-)%)")
    return target and not target:match("^https?://") and not line:match("!%b[]%(.+%)")
end

--- Open file under cursor
---@param line string
---@return boolean
function M.open(line)
    local target = line:match("%[.-%]%((.-)%)")
    if not target then return false end

    local current_file = vim.api.nvim_buf_get_name(0)
    local current_dir = vim.fn.fnamemodify(current_file, ":h")
    local full_path = vim.fn.resolve(current_dir .. "/" .. target)

    local sysname = vim.loop.os_uname().sysname or ""
    local ok
    if sysname:match("Windows") or sysname:match("windows") then
        ok = vim.fn.jobstart({ "cmd", "/C", "start", "", full_path }, { detach = true }) ~= 0
    elseif sysname == "Darwin" then
        ok = vim.fn.jobstart({ "open", full_path }, { detach = true }) ~= 0
    else
        ok = vim.fn.jobstart({ "xdg-open", full_path }, { detach = true }) ~= 0
    end

    if ok then
        vim.notify("[Custom.Markdown] Opening file: " .. full_path, vim.log.levels.INFO)
    else
        vim.notify("[Custom.Markdown] Failed to open file: " .. full_path, vim.log.levels.ERROR)
    end
    return ok
end

return M

