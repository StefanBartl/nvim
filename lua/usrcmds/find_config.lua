---@module 'plugins.find_config'
--- Cross-platform "find in Neovim config" using fzf-lua.
--- Uses stdpath('config') so it works on Linux/macOS/Windows without branching.

---@class FindConfig
local M = {}

--- Get the Neovim config directory in a portable way.
--- For Neovim, stdpath('config') is canonical on all platforms.
---@return string -- absolute path to the config directory
local function get_nvim_config_dir()
  -- Neovim: stdpath('config') exists and is cross-platform
  if vim.fn.has("nvim") == 1 then
    return vim.fn.stdpath("config")
  end
  -- Fallback for classic Vim running Lua providers (rare):
  if vim.fn.exists("*stdpath") == 1 then
    return vim.fn.stdpath("config")
  end
  -- Last-resort fallback via $MYVIMRC:
  if vim.env.MYVIMRC and vim.env.MYVIMRC ~= "" then
    return vim.fn.fnamemodify(vim.env.MYVIMRC, ":p:h")
  end
  -- Conservative defaults (Vim): Linux/macOS -> ~/.vim, Windows -> ~/vimfiles
  if vim.fn.has("win32") == 1 then
    return vim.fn.expand("~/vimfiles")
  else
    return vim.fn.expand("~/.vim")
  end
end

--- Open fzf-lua file picker rooted at the config dir.
---@param opts table|nil -- extra options passed to fzf-lua.files
---@return nil
function M.find_in_config(opts)
  ---@diagnostic disable-next-line: different-requires
  local fzf = require("fzf-lua")
  local cwd = get_nvim_config_dir()
  fzf.files(vim.tbl_extend("force", {
    cwd = cwd,                  -- root search at the config directory
    prompt = "Config Files❯ ",  -- clearer prompt
  }, opts or {}))
end

--- Setup mappings and user-commands.
---@return nil
(function ()
  -- <leader>fc : search files in config dir
  vim.keymap.set("n", "<leader>fc", function()
    M.find_in_config()
  end, { desc = "Find file in Neovim config" })

  -- :FindConfig : same as <leader>fc
  vim.api.nvim_create_user_command("FindConfig", function(params)
    -- Allow optional extra args for power-users (e.g., filtering)
    if params.args ~= "" then
      M.find_in_config({ fzf_opts = { ["--query"] = params.args } })
    else
      M.find_in_config()
    end
  end, {
    nargs = "?",
    desc = "Search files in Neovim config directory (fzf-lua)",
  })
end)()
return M
