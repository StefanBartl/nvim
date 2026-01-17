---@module 'custom.find_config.core'
---@description Shared utilities for cross-platform Neovim config directory resolution

local M = {}

--- Get the Neovim config directory in a portable way.
--- Uses stdpath('config') on Neovim (canonical on all platforms).
--- Provides multiple fallbacks for edge cases and classic Vim compatibility.
---@return string absolute_path_to_config_dir
function M.get_nvim_config_dir()
  -- Neovim: stdpath('config') exists and is cross-platform
  if vim.fn.has("nvim") == 1 then
    return vim.fn.stdpath("config")
  end

  -- Fallback for classic Vim running Lua providers (rare edge case)
  if vim.fn.exists("*stdpath") == 1 then
    return vim.fn.stdpath("config")
  end

  -- Last-resort fallback via $MYVIMRC environment variable
  if vim.env.MYVIMRC and vim.env.MYVIMRC ~= "" then
    -- Return parent directory of MYVIMRC
    return vim.fn.fnamemodify(vim.env.MYVIMRC, ":p:h")
  end

  -- Conservative defaults for plain Vim:
  -- Windows -> ~/vimfiles, Unix-like -> ~/.vim
  if vim.fn.has("win32") == 1 then
    return vim.fn.expand("~/vimfiles")
  else
    return vim.fn.expand("~/.vim")
  end
end

return M
