---@module 'autocmds.general.helpers'
--- Shared helpers for the general autocmds group: `augroup`/pattern-normalize
--- wrappers, and `no_name_guard_sweep` (closes stray unnamed empty buffers).
---
--- Kitty-terminal detection and padding/margin control used to live here --
--- removed 2026-09-12, duplicate of autocmds.terminals' own kitty feature
--- (same events, same underlying `kitty @ set-spacing` command). That module
--- is the one owner now; see its own doc comment.

local M = {}

local api = vim.api

--- Create/clear a namespaced augroup.
--- @param name string
--- @return integer
function M.augroup(name)
  return api.nvim_create_augroup("general_autocmds_" .. name, { clear = true })
end

--------------------------------------------------------------------------------
-- no_name_guard
--------------------------------------------------------------------------------

--- True for a buffer that is exactly the shape of a stray, freshly-spawned
--- [No Name] buffer: normal buftype, unnamed, listed, unmodified, empty.
--- Deliberately state-based rather than tag-based, so it only ever matches
--- the shape Neovim itself creates as a fallback -- a buffer a plugin creates
--- on purpose for scratch/temp input almost always sets `buftype` (e.g.
--- "nofile", "acwrite") or `nobuflisted`, so it never matches here.
--- @param buf integer
--- @return boolean
local function is_stray_no_name(buf)
  if not api.nvim_buf_is_valid(buf) then
    return false
  end
  if vim.bo[buf].buftype ~= "" then
    return false
  end
  if not vim.bo[buf].buflisted then
    return false
  end
  if vim.bo[buf].modified then
    return false
  end
  if api.nvim_buf_get_name(buf) ~= "" then
    return false
  end
  if api.nvim_buf_line_count(buf) > 1 then
    return false
  end
  return (api.nvim_buf_get_lines(buf, 0, 1, false)[1] or "") == ""
end

--- Find a real (named, listed, loaded, normal-buftype) buffer to redirect a
--- stray [No Name] window to. Prefers the alternate buffer (`#`) so the
--- window lands on "the next file", per the same policy filetree.nvim's
--- `close_for_path` uses. Deliberately only ever returns a *named* buffer --
--- swapping one blank buffer for another blank one would defeat the point.
--- @param exclude table<integer, true>  Buffer numbers to skip (e.g. the one just deleted).
--- @return integer?
local function find_named_buffer(exclude)
  local function usable(b)
    return b
      and b > 0
      and not exclude[b]
      and api.nvim_buf_is_valid(b)
      and api.nvim_buf_is_loaded(b)
      and vim.bo[b].buflisted
      and vim.bo[b].buftype == ""
      and api.nvim_buf_get_name(b) ~= ""
  end
  local alt = vim.fn.bufnr("#")
  if usable(alt) then
    return alt
  end
  for _, b in ipairs(api.nvim_list_bufs()) do
    if usable(b) then
      return b
    end
  end
  return nil
end

--- Scan every normal (non-floating) window; any showing a stray [No Name]
--- buffer gets redirected to a real buffer, if one exists. Deferred one tick
--- (`vim.schedule`) so it runs after Neovim has finished picking whatever
--- fallback buffer it was going to show for the window that just lost its
--- buffer/closed.
--- @param exclude table<integer, true>  Buffer numbers ineligible as a replacement.
function M.no_name_guard_sweep(exclude)
  vim.schedule(function()
    for _, win in ipairs(api.nvim_list_wins()) do
      if api.nvim_win_is_valid(win) and api.nvim_win_get_config(win).relative == "" then
        local buf = api.nvim_win_get_buf(win)
        if is_stray_no_name(buf) then
          local repl = find_named_buffer(exclude)
          if repl and repl ~= buf then
            pcall(api.nvim_win_set_buf, win, repl)
          end
          -- else: no real buffer to switch to -- this IS the legitimate case
          -- (e.g. the last file buffer just closed, or a tree plugin is the
          -- only window left with `close_if_last_window = false`). Leave the
          -- [No Name] buffer exactly as Neovim created it.
        end
      end
    end
  end)
end

return M
