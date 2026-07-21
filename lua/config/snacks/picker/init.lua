---@module 'config.snacks.picker'
---@brief Snacks.picker configuration — delegates in-picker keys to pickers.nvim.
---@description
--- Thin adapter that assembles the `Snacks.picker` options from pickers.nvim so
--- the in-picker UX is unified across every engine (telescope / fzf-lua / snacks):
---
---   - Preview scroll + history keys  → require("pickers.keys").snacks_win()
---     (input + list + preview windows, insert & normal where it applies)
---   - create_file / open_background  → pickers.entry_actions.adapters.snacks
---     (named actions + their list-window keys)
---
--- Both sides come from pickers.nvim config, so changing a binding there changes
--- it for all pickers at once — no snacks-only copy to keep in sync.
---
--- Usage:
---   require("snacks").setup({ picker = require("config.snacks.picker").get_config() })

local M = {}

-- Deferred (not a module-top-level require): this module is required eagerly
-- from plugins/snacks.lua's spec top level, before lazy=false plugins like
-- pickers.nvim have been loaded onto the path.
---@return table
local function entry_actions()
  return require("pickers.entry_actions.adapters.snacks")
end

--- Empty win skeleton, used when pickers.nvim is not (yet) on the runtimepath.
---@return { input: { keys: table }, list: { keys: table }, preview: { keys: table } }
local function empty_win()
  return { input = { keys = {} }, list = { keys = {} }, preview = { keys = {} } }
end

--- Resolve pickers.nvim's snacks win-keys (preview scroll + history), degrading
--- to an empty skeleton if the plugin isn't available yet.
---@return { input: { keys: table }, list: { keys: table }, preview: { keys: table } }
local function pickers_win()
  local ok, keys = pcall(require, "pickers.keys")
  if not ok then return empty_win() end
  local win = keys.snacks_win()
  -- Defensive: guarantee all three window buckets exist.
  win.input = win.input or { keys = {} }
  win.list = win.list or { keys = {} }
  win.preview = win.preview or { keys = {} }
  return win
end

---Get complete picker configuration.
---@return table config Snacks picker configuration
function M.get_config()
  local win = pickers_win()

  -- entry_actions (create_file / open_background) bind on the list window.
  local list_keys = vim.tbl_extend("force", win.list.keys, entry_actions().get_keys())

  return {
    enabled = true,
    actions = entry_actions().get_actions(),
    win = {
      input = { keys = win.input.keys },
      list = { keys = list_keys },
      preview = { keys = win.preview.keys },
    },
    -- Disable line wrapping by default (like Telescope).
    preview = { wrap = false },
  }
end

---Setup and merge with existing opts.
---@param opts? table Existing snacks picker options
---@return table config Merged configuration
function M.setup(opts)
  return vim.tbl_deep_extend("force", M.get_config(), opts or {})
end

---Get only actions (for manual integration).
---@return table<string, function> actions
function M.get_actions()
  return entry_actions().get_actions()
end

---Get only keymaps (for manual integration).
---@return { input: table, list: table, preview: table } keymaps
function M.get_keymaps()
  local win = pickers_win()
  return {
    input = win.input.keys,
    list = vim.tbl_extend("force", win.list.keys, entry_actions().get_keys()),
    preview = win.preview.keys,
  }
end

return M
