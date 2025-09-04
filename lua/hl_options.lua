---@module 'hl_options'
--- Enhanced, window-scoped cursor highlighting and related Neovim options.
--- Drop this into lua/options.lua (or equivalent) and require it early in your config.

---@class CursorHighlightColors
---@field CursorLine  table  -- { bg = "#RRGGBB", ... }
---@field CursorLineNr table -- { fg = "#RRGGBB", bold = boolean, ... }
---@field CursorColumn table -- { bg = "#RRGGBB", ... }
---@field Cursor      table  -- { bg = "#RRGGBB", fg = "#RRGGBB", ... }

---@class CursorHighlightConfig
---@field enable_line boolean          -- highlight current line
---@field enable_column boolean        -- highlight current column (can be slower on huge files)
---@field color_persist boolean        -- reapply HL after :colorscheme via ColorScheme autocmd
---@field map_cursor_to_hl boolean     -- bind guicursor to "Cursor" HL for visible in-buffer cursor
---@field colors CursorHighlightColors -- highlight definitions
---@field min_colored_file_kb integer  -- disable column highlight for files bigger than this

---@type CursorHighlightConfig
local cfg = {
  enable_line = true,
  enable_column = true,            -- set true if a vertical guide helps you
  color_persist = true,
  map_cursor_to_hl = true,
  min_colored_file_kb = 4096,       -- skip cursorcolumn on very large files
  colors = {
    CursorLine   = { bg = "#2a2e36" },
    CursorLineNr = { fg = "#ffd75f", bold = true },
    CursorColumn = { bg = "#2a2e36" },
    Cursor       = { bg = "#ff5f87", fg = "#1e1e1e" },
  },
}

--- Apply highlight groups safely.
---@return nil
local function apply_highlights()
  for name, spec in pairs(cfg.colors) do
    -- Use 0 (global) so it's independent from the current window
    vim.api.nvim_set_hl(0, name, spec)
  end
end

--- Decide whether to enable cursorcolumn for the current buffer based on file size.
---@return boolean
local function should_enable_column()
  if not cfg.enable_column then return false end
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" then return true end
  local stat_ok, stat = pcall((vim.uv or vim.loop).fs_stat, name)
  if not stat_ok or not stat or not stat.size then return true end
  local kb = math.floor(stat.size / 1024)
  return kb <= cfg.min_colored_file_kb
end

--- Activate strong cursor highlight in the current window.
---@return nil
local function activate_window_hl()
  if cfg.enable_line then
    vim.wo.cursorline = true
    -- both = line background + CursorLineNr highlight
    vim.wo.cursorlineopt = "both"
    -- Pin window-local mappings of HL names for predictable visuals
    local wh = "CursorLine:CursorLine,CursorLineNr:CursorLineNr"
    if should_enable_column() then
      vim.wo.cursorcolumn = true
      wh = wh .. ",CursorColumn:CursorColumn"
    else
      vim.wo.cursorcolumn = false
    end
    vim.wo.winhighlight = wh
  else
    vim.wo.cursorline = false
    vim.wo.cursorcolumn = false
    vim.wo.winhighlight = ""
  end
end

--- Deactivate or dim highlight in windows that lose focus.
---@return nil
local function deactivate_window_hl()
  vim.wo.cursorline = false
  vim.wo.cursorcolumn = false
  -- Map to neutral groups so inactive splits are not distracting
  vim.wo.winhighlight = "CursorLine:Normal,CursorLineNr:LineNr,CursorColumn:Normal"
end

-- Core options (global defaults)
vim.opt.cursorline = cfg.enable_line
vim.opt.cursorlineopt = "both"
vim.opt.cursorcolumn = cfg.enable_column

-- Make the “Cursor” HL visible for the terminal/GUI cursor (where supported)
if cfg.map_cursor_to_hl then
  vim.opt.guicursor = table.concat({
    "n-v-c:block-Cursor",
    "i-ci-ve:ver25-Cursor",
    "r-cr:hor20-Cursor",
    "o:hor50-Cursor",
  }, ",")
end

-- Apply initial colors; keep them persistent across colorscheme changes
apply_highlights()
if cfg.color_persist then
  local grp = vim.api.nvim_create_augroup("cfg_ColorPersist", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = grp,
    callback = apply_highlights,
    desc = "Reapply cursor highlight groups after colorscheme changes",
  })
end

-- Window-scoped behavior: only highlight strongly in the active window
local grp_win = vim.api.nvim_create_augroup("cfg_PerWindow", { clear = true })
vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
  group = grp_win,
  callback = activate_window_hl,
  desc = "Activate cursorline/column and window-local highlights for the active window",
})
vim.api.nvim_create_autocmd({ "WinLeave" }, {
  group = grp_win,
  callback = deactivate_window_hl,
  desc = "Dim or disable cursor highlights for inactive windows",
})

-- Also re-evaluate column highlight after large file detection or file reads
vim.api.nvim_create_autocmd({ "BufReadPost", "TextChanged", "TextChangedI" }, {
  group = grp_win,
  callback = function()
    if vim.wo.cursorline then
      activate_window_hl()
    end
  end,
  desc = "Re-check column highlight for large files and update winhighlight",
})
