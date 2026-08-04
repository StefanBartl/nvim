---@module 'wkdnvchad.ui.statusline.modules.casedesk'
--- Statusline segment: current case's short number + company + how many
--- files sit in its Replies/ folder — empty string whenever the focused
--- buffer isn't inside a known case (ROADMAP.md v7's "Statusline-Badge").
---
--- `bindings.usrcmds.case.resolve.sync` is the same buffer -> case lookup
--- `:Case`'s routes use (registry membership, not a marker file), just
--- called for its synchronous half only — no kit.select fallback, a
--- statusline redraw can't prompt.
---
--- Cached by buffer name, same "recompute only when the cheap key changes"
--- shape as the sibling `plugin_summary` module: a redraw happens on nearly
--- every keystroke, but the buffer you're in changes far less often, so the
--- `.case.json` read + a directory scan only have to happen once per buffer
--- switch, not once per redraw.

local uv = vim.uv or vim.loop

---@type string|nil bufname the cached text was last derived from
local cached_bufname = nil
local cached_text = ""

---@param dir string
---@return integer
local function count_files(dir)
  local n = 0
  local fd = uv.fs_scandir(dir)
  if fd then
    while true do
      local name, typ = uv.fs_scandir_next(fd)
      if not name then
        break
      end
      if typ == "file" then
        n = n + 1
      end
    end
  end
  return n
end

---@param entry Lib.Case.RegistryEntry
---@return string
local function compute(entry)
  local meta = require("bindings.usrcmds.case.meta")
  local m = meta.read(entry.dir)

  local label = (m and m.company) and (entry.short .. " " .. m.company) or entry.short
  local count = count_files(entry.dir .. "/Replies")
  local reply_word = count == 1 and "reply" or "replies"

  -- Same highlight convention as the `lsp` segment (custom.lua) — no new
  -- theme color, this reuses an existing group.
  return " %#St_Lsp#" .. label .. " · " .. count .. " " .. reply_word .. " "
end

return function()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname == cached_bufname then
    return cached_text
  end
  cached_bufname = bufname

  local ok_resolve, resolve = pcall(require, "bindings.usrcmds.case.resolve")
  if not ok_resolve then
    cached_text = ""
    return cached_text
  end

  local ok_entry, entry = pcall(resolve.sync, nil)
  if not ok_entry or not entry then
    cached_text = ""
    return cached_text
  end

  cached_text = compute(entry)
  return cached_text
end
