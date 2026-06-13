---@module 'usrcmds.live_grep.picker'

local config = require("usrcmds.live_grep.config")

local M = {}

---@return "telescope"|"fzf"
function M.detect()
  if config.options.picker then
    return config.options.picker
  end

  if pcall(require, "telescope") then
    return "telescope"
  end

  if pcall(require, "fzf-lua") then
    return "fzf"
  end

  error("No supported picker found")
end

return M
