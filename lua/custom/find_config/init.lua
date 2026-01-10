---@module 'custom.find_config'
--- Cross-platform "find in Neovim config" using fzf-lua.
--- Uses stdpath('config') so it works on Linux/macOS/Windows without branching.
---@alias FindConfigOptions table|nil

---@async
---@class FindConfig
---@field find_in_config fun(opts:FindConfigOptions)
---@field grep_in_config fun(opts:FindConfigOptions)
---@field enable fun(cfg: table)

local notify = require("lib.notify").create("")

local M = {}

--- Get the Neovim config directory in a portable way.
--- For Neovim, stdpath('config') is canonical on all platforms.
--- This function tries multiple fallbacks to be robust in edge cases.
---@return string absolute_path_to_config_dir
local function get_nvim_config_dir()
  -- Neovim: stdpath('config') exists and is cross-platform
  if vim.fn.has("nvim") == 1 then
    return vim.fn.stdpath("config")
  end

  -- Fallback for classic Vim running Lua providers (very rare)
  if vim.fn.exists("*stdpath") == 1 then
    return vim.fn.stdpath("config")
  end

  -- Last-resort fallback via $MYVIMRC environment variable
  if vim.env.MYVIMRC and vim.env.MYVIMRC ~= "" then
    -- return parent dir of MYVIMRC
    return vim.fn.fnamemodify(vim.env.MYVIMRC, ":p:h")
  end

  -- Conservative defaults for plain Vim:
  -- - Windows -> ~/vimfiles
  -- - Unix-like -> ~/.vim
  if vim.fn.has("win32") == 1 then
    return vim.fn.expand("~/vimfiles")
  else
    return vim.fn.expand("~/.vim")
  end
end

--- Open fzf-lua file picker rooted at the config dir.
--- Uses fzf-lua.files under the hood and merges `opts` with sensible defaults.
--- Features:
---   - Case-insensitive matching (finds "INIT" and "init" equally)
---   - Fuzzy substring matching (finds "arl" in "barl")
---@param opts FindConfigOptions extra options passed to fzf-lua.files
---@return nil
local function Find_in_config(opts)
  ---@diagnostic disable-next-line: different-requires
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok or not fzf or type(fzf.files) ~= "function" then
    notify.error("fzf-lua not found or does not expose 'files' function")
    return
  end

  local cwd = get_nvim_config_dir()

  -- Default fzf options for better path matching
  local default_fzf_opts = {
    -- ["--case-insensitive"] = "",  -- ignore case (finds INIT and init) FIX: Error  06:35:20 msg_show.echoerr [Fzf-lua] fzf error 2: unknown option: --case-insensitive
    -- fzf's fuzzy matching already does substring matching by default
  }

  -- Merge provided opts on top of sensible defaults
  local merged = vim.tbl_extend("force", {
    cwd = cwd,
    prompt = "Config Files❯ ",
    fzf_opts = default_fzf_opts,
  }, opts or {})

  -- If user provided custom fzf_opts, merge them too
  if opts and opts.fzf_opts then
    merged.fzf_opts = vim.tbl_extend("force", default_fzf_opts, opts.fzf_opts)
  end

  -- Call fzf-lua.files with defensive error handling
  local ok_call, err = pcall(function()
    fzf.files(merged)
  end)
  if not ok_call then
    notify.error("fzf-lua.files failed: " .. tostring(err))
  end
end

--- Run a live grep / ripgrep rooted at the config dir.
--- Uses fzf-lua.live_grep for an interactive search experience.
---@param opts FindConfigOptions extra options passed to fzf-lua.live_grep
---@return nil
local function Grep_in_config(opts)
  ---@diagnostic disable-next-line: different-requires
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok or not fzf or type(fzf.live_grep) ~= "function" then
    notify.error("fzf-lua not found or does not expose 'live_grep' function")
    return
  end

  local cwd = get_nvim_config_dir()
  -- Merge provided opts on top of sensible defaults
  local merged = vim.tbl_extend("force", {
    cwd = cwd, -- run ripgrep from the config directory
    prompt = "Grep Config❯ ", -- clearer prompt for grepping
    -- additional sensible defaults could be placed here
  }, opts or {})

  -- Call fzf-lua.live_grep with defensive error handling
  local ok_call, err = pcall(function()
    fzf.live_grep(merged)
  end)
  if not ok_call then
    notify.error("fzf-lua.live_grep failed: " .. tostring(err))
  end
end

--- Setup keymaps for find & grep in config.
--- <leader>fc : search files in config dir (Find_in_config)
--- <leader>gc : live grep within config dir (Grep_in_config)
---@return nil
local function Enable_keymaps()
  -- Find files in config
  vim.keymap.set("n", "<leader>fc", function()
    Find_in_config()
  end, { desc = "Find file in Neovim config" })

  -- Grep in config
  vim.keymap.set("n", "<leader>gc", function()
    Grep_in_config()
  end, { desc = "Grep in Neovim config (live_grep)" })
end

--- Setup user-commands for find & grep in config.
--- :FindConfig [query]   => opens fzf file picker, optional query passed to fzf as --query
--- :GrepConfig  [query]  => opens live_grep, optional query passed to fzf as --query
---@return nil
local function Enable_usercmds()
  vim.api.nvim_create_user_command("FindConfig", function(params)
    if params.args ~= "" then
      -- pass initial query to fzf via fzf_opts --query
      Find_in_config({ fzf_opts = { ["--query"] = params.args } })
    else
      Find_in_config()
    end
  end, {
    nargs = "?",
    desc = "Search files in Neovim config directory (fzf-lua)",
  })

  vim.api.nvim_create_user_command("GrepConfig", function(params)
    if params.args ~= "" then
      Grep_in_config({ fzf_opts = { ["--query"] = params.args } })
    else
      Grep_in_config()
    end
  end, {
    nargs = "?",
    desc = "Live grep in Neovim config directory (fzf-lua)",
  })
end

--- Setup both mappings and usercommands from find_config
--- The cfg table controls whether keymaps and/or usercommands are enabled.
--- Expected shape:
--- {
---   keymaps = true|false,
---   usercmds = true|false,
--- }
---@param cfg table|nil configuration toggles
---@return nil
function M.enable(cfg)
  if not cfg then
    return
  end
  -- If keymaps requested, enable both find and grep keymaps
  if cfg.keymaps then
    Enable_keymaps()
  end
  -- If usercommands requested, enable both FindConfig and GrepConfig
  if cfg.usercmds then
    Enable_usercmds()
  end
end

-- Expose helpers for advanced usage
M.Find_in_config = Find_in_config
M.Grep_in_config = Grep_in_config

return M ---@type FindConfig
