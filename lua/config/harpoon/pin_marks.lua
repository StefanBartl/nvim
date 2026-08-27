---@module 'config.harpoon.pin_marks'
--- Visually flag persistent default paths (config.harpoon.persist_paths pins)
--- inside Harpoon's quick menu, so it is obvious which lines are "protected"
--- defaults before you reorder or `dd` them.
---
--- Harpoon v2's default quick menu renders each item's full absolute path
--- (config.display = list_item.value) into a scratch buffer with
--- `filetype=harpoon` (see harpoon/buffer.lua). We match each visible line
--- against the pin set and hang an eol virtual-text marker on the pinned ones.
--- Re-applied on TextChanged so the markers follow the user's live reordering
--- and deletions inside the menu.

local M = {}

local normkey = require("lib.nvim.fs.normkey")
local Autocmd = require("lib.nvim.bindings.autocmd")

local NS = vim.api.nvim_create_namespace("HarpoonPinMarks")
local HL = "HarpoonPinMark"
local ICON = "  📌 pin"

local function ensure_highlight()
  -- Link to a warn-ish group so it reads as "careful" without hardcoding a
  -- color; only define it if the user/theme has not already set it.
  if vim.fn.hlexists(HL) == 0 then
    vim.api.nvim_set_hl(0, HL, { link = "DiagnosticVirtualTextWarn", default = true })
  end
end

---Re-mark all pinned lines in the given harpoon menu buffer.
---@param bufnr integer
local function mark(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  vim.api.nvim_buf_clear_namespace(bufnr, NS, 0, -1)

  local pinned = require("config.harpoon.persist_paths").pinned_set()
  if not next(pinned) then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i, line in ipairs(lines) do
    local path = vim.trim(line)
    if path ~= "" and pinned[normkey(path, { realpath = true })] then
      pcall(vim.api.nvim_buf_set_extmark, bufnr, NS, i - 1, 0, {
        virt_text = { { ICON, HL } },
        virt_text_pos = "eol",
        hl_mode = "combine",
      })
    end
  end
end

---@return nil
function M.setup()
  ensure_highlight()

  local grp = Autocmd.group("HarpoonPinMarks", true)

  -- The quick-menu buffer is created fresh each open with filetype=harpoon.
  Autocmd.create("FileType", function(ev)
    local bufnr = ev.buf
    mark(bufnr)
    -- Keep markers aligned with live reordering / deletions inside the menu.
    -- Buffer-local (lib.nvim.bindings.autocmd.create does not forward `buffer`, so use
    -- the native API here); auto-cleaned when the scratch buffer is wiped.
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
      group = grp,
      buffer = bufnr,
      callback = function()
        mark(bufnr)
      end,
    })
  end, {
    group = grp,
    pattern = "harpoon",
  })
end

return M
