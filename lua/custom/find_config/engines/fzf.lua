---@module 'custom.find_config.engines.fzf'
---@description fzf-lua engine implementation for find_config

local notify = require("lib.nvim.notify").create("[find_config:fzf]")
local core = require("custom.find_config.core")

local M = {}

--- Open fzf-lua file picker rooted at config directory.
--- Uses case-insensitive fuzzy matching by default.
---@param opts table|nil Extra options passed to fzf-lua.files
---@return nil
function M.find_in_config(opts)
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok or not fzf or type(fzf.files) ~= "function" then
    notify.error("fzf-lua not found or missing 'files' function")
    return
  end

  local cwd = core.get_nvim_config_dir()

  -- Default fzf options for case-insensitive matching
  local default_fzf_opts = {
    ["-i"] = "",  -- case-insensitive
  }

  -- Merge user options with defaults
  local merged = vim.tbl_extend("force", {
    cwd = cwd,
    prompt = "Config Files❯ ",
    fzf_opts = default_fzf_opts,
  }, opts or {})

  -- If user provided custom fzf_opts, merge them
  if opts and opts.fzf_opts then
    merged.fzf_opts = vim.tbl_extend("force", default_fzf_opts, opts.fzf_opts)
  end

  -- Execute fzf-lua.files with defensive error handling
  local ok_call, err = pcall(function()
    fzf.files(merged)
  end)
  if not ok_call then
    notify.error("fzf-lua.files failed: " .. tostring(err))
  end
end

--- Run live grep rooted at config directory.
--- Uses fzf-lua.live_grep for interactive search.
---@param opts table|nil Extra options passed to fzf-lua.live_grep
---@return nil
function M.grep_in_config(opts)
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok or not fzf or type(fzf.live_grep) ~= "function" then
    notify.error("fzf-lua not found or missing 'live_grep' function")
    return
  end

  local cwd = core.get_nvim_config_dir()

  -- Default fzf options for case-insensitive matching
  local default_fzf_opts = {
    ["-i"] = "",
  }

  -- Merge user options with defaults
  local merged = vim.tbl_extend("force", {
    cwd = cwd,
    prompt = "Grep Config❯ ",
    fzf_opts = default_fzf_opts,
  }, opts or {})

  -- If user provided custom fzf_opts, merge them
  if opts and opts.fzf_opts then
    merged.fzf_opts = vim.tbl_extend("force", default_fzf_opts, opts.fzf_opts)
  end

  -- Execute fzf-lua.live_grep with defensive error handling
  local ok_call, err = pcall(function()
    fzf.live_grep(merged)
  end)
  if not ok_call then
    notify.error("fzf-lua.live_grep failed: " .. tostring(err))
  end
end

return M
