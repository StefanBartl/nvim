---@module 'custom.markdown.handler.url'
--- Open URL under cursor in default browser

local M = {}

--- Detect if line contains URL
---@param line string
---@return boolean
function M.is_url_line(line)
    local target = line:match("%[.-%]%((.-)%)")
    return target and target:match("^https?://") ~= nil
end

--- Open URL under cursor
---@param line string
---@return boolean
function M.open(line)
    local target = line:match("%[.-%]%((.-)%)")
    if not target then return false end

    local sysname = vim.loop.os_uname().sysname or ""
    local ok
    if sysname:match("Windows") or sysname:match("windows") then
        ok = vim.fn.jobstart({ "cmd", "/C", "start", "", target }, { detach = true }) ~= 0
    elseif sysname == "Darwin" then
        ok = vim.fn.jobstart({ "open", target }, { detach = true }) ~= 0
    else
        ok = vim.fn.jobstart({ "xdg-open", target }, { detach = true }) ~= 0
    end

    if ok then
        vim.notify("[Custom.Markdown] Opening URL: " .. target, vim.log.levels.INFO)
    else
        vim.notify("[Custom.Markdown] Failed to open URL: " .. target, vim.log.levels.ERROR)
    end
    return ok
end

return M
