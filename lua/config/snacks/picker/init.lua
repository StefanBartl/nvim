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

--- Empty entry-actions skeleton, used when pickers.nvim is not (yet) on the
--- runtimepath. Mirrors pickers_win()'s degrade pattern below so a load-order
--- slip silently yields "no extra actions" instead of an error in Snacks'
--- opts(), which would otherwise drop the entire picker config (including
--- unrelated keys like preview scroll).
---@return { get_keys: fun(): table, get_input_keys: fun(): table, get_actions: fun(): table }
local function empty_entry_actions()
  return {
    get_keys = function() return {} end,
    get_input_keys = function() return {} end,
    get_actions = function() return {} end,
  }
end

-- Deferred (not a module-top-level require): this module is required eagerly
-- from plugins/snacks.lua's spec top level. plugins/snacks.lua declares an
-- explicit `dependencies = { "StefanBartl/pickers.nvim" }` to guarantee load
-- order, but this pcall stays as a second line of defense (e.g. plugin
-- renamed/removed) rather than hard-failing Snacks.setup().
---@return { get_keys: fun(): table, get_input_keys: fun(): table, get_actions: fun(): table }
local function entry_actions()
  local ok, mod = pcall(require, "pickers.entry_actions.adapters.snacks")
  if not ok then
    return empty_entry_actions()
  end
  return mod
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
  if not ok then
    return empty_win()
  end
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
  local ea = entry_actions()

  -- entry_actions (create_file / open_background) bind on BOTH windows: a
  -- picker opens with focus in the input prompt, so a list-only binding is
  -- unreachable while typing and the key falls through to plain `confirm`.
  local list_keys = vim.tbl_extend("force", win.list.keys, ea.get_keys())
  local input_keys = vim.tbl_extend("force", win.input.keys, ea.get_input_keys())

  return {
    enabled = true,
    actions = ea.get_actions(),
    win = {
      input = { keys = input_keys },
      list = { keys = list_keys },
      -- Disable line wrapping by default (like Telescope). This belongs on the
      -- preview WINDOW's `wo`, not on `picker.preview` — the latter is the
      -- previewer itself (function or name), so a table there is resolved as a
      -- previewer and then called: "attempt to call a table value".
      preview = { keys = win.preview.keys, wo = { wrap = false } },
    },
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
  local ea = entry_actions()
  return {
    input = vim.tbl_extend("force", win.input.keys, ea.get_input_keys()),
    list = vim.tbl_extend("force", win.list.keys, ea.get_keys()),
    preview = win.preview.keys,
  }
end

return M
