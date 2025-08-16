---@module 'mappings.colorscheme_picker'
--- Keymaps to pick and apply colorschemes on the fly.
--- Works with Telescope (live preview) or fzf-lua as a fallback.
--- Intended for NvChad or any Neovim setup.
--- Place this file under: lua/mappings/colorscheme_picker.lua
--- Then require it from your main mappings file.

local M = { _desc = "Colorscheme picker with Telescope or fzf-lua" }

--- Shorthand for keymap creation with sane defaults.
--- Uses buffer-agnostic normal mode mappings and silent=true.
---@param lhs string  -- key sequence
---@param rhs fun()|string  -- callable or command
---@param desc string  -- human-readable description
local function map(lhs, rhs, desc)
  ---@type vim.keymap.set.Opts
  local opts = { noremap = true, silent = true, desc = desc }
  vim.keymap.set("n", lhs, rhs, opts)
end

--- Open Telescope colorscheme picker with live preview.
--- Falls back to a warning if Telescope is not available.
local function telescope_colors()
  local ok, builtin = pcall(require, "telescope.builtin")
  if not ok then
    vim.notify("[colorscheme] telescope.builtin not found", vim.log.levels.WARN)
    return
  end
  -- enable_preview: applies colorscheme as one moves through the list
  builtin.colorscheme({
    enable_preview = true,
  })
end

--- Open fzf-lua colorscheme picker.
--- Applies the colorscheme on selection/confirm.
local function fzf_colors()
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify("[colorscheme] fzf-lua not found", vim.log.levels.WARN)
    return
  end
  -- fzf-lua applies on confirm; additional opts can be passed if desired
  fzf.colorschemes({})
end

--- Auto-detect picker: prefer Telescope (live preview), else use fzf-lua.
local function auto_colors()
  if pcall(require, "telescope.builtin") then
    telescope_colors()
    return
  end
  if pcall(require, "fzf-lua") then
    fzf_colors()
    return
  end
  vim.notify("[colorscheme] No picker found (install telescope.nvim or fzf-lua)", vim.log.levels.WARN)
end

--- Public setup: installs three keymaps.
--- <leader>sc  -> auto (Telescope preferred, else fzf-lua)
--- <leader>sT  -> Telescope colorscheme (live preview)
--- <leader>sF  -> fzf-lua colorscheme
---@return nil
function M.setup()
  map("<leader>pl", auto_colors, "Colorscheme: pick (auto)")
  map("<leader>pT", telescope_colors, "Colorscheme: Telescope")
  map("<leader>pF", fzf_colors, "Colorscheme: fzf-lua")
end

-- Auto-execute on require; comment out if manual control is preferred.
M.setup()

-- Register user commands
vim.api.nvim_create_user_command("ColorschemePick", auto_colors, { desc = "Pick colorscheme (auto)" })
vim.api.nvim_create_user_command("ColorschemeTelescope", telescope_colors, { desc = "Pick colorscheme via Telescope" })
vim.api.nvim_create_user_command("ColorschemeFzf", fzf_colors, { desc = "Pick colorscheme via fzf-lua" })

return M

