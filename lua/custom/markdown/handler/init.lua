---@module 'custom.markdown.handler.init'
--- Central handler for context-sensitive Markdown actions.
--- Dispatches to image, url, or file modules based on the line under cursor.

local M = {}

local api = vim.api
local image = require("custom.markdown.handler.image")
local url   = require("custom.markdown.handler.url")
local file  = require("custom.markdown.handler.file")

--- Handle action under cursor
---@return nil
function M.handle_cursor_action()
    local line = api.nvim_get_current_line()

    if image.is_image_line(line) then
        image.open(line)
        return
    end

    if url.is_url_line(line) then
        url.open(line)
        return
    end

    if file.is_file_line(line) then
        file.open(line)
        return
    end

    vim.notify("[Custom.Markdown] Handler: No recognized target under cursor", vim.log.levels.INFO)
end

return M
