---@module 'uv_doc'
--- libuv doc fetcher with robust index parsing, fuzzy list UI, and "insert here".
--- This module targets https://docs.libuv.org/en/v1.x/ and extracts symbols by the
--- sphinx anchor ids (#c.uv_*), not by link labels. it provides:
---   :uvdoc [name]      -- exact or fuzzy (e.g., "loop", "timer", "fs_event_cb")
---   :uvdoclist [q]     -- line-based picker with cursorline; <cr> opens
---   :uvdochere [name]  -- insert only the c signature (or type stub) at cursor
---   :uvdoccacheclear   -- clear in-session caches
---
--- notes:
---   - some sphinx builds split the general index across multiple pages
---     (genindex-a.html, genindex-b.html, ...) or provide genindex-all.html.
---     this module aggregates all genindex pages to include functions and typedefs
---     such as uv_close_cb, uv_err_name_r, uv_fs_event_stop, etc.
---
--- requirements:
---   - curl in path (linux/macos; windows not covered by default)
---   - neovim ≥ 0.9 (vim.system)

local M = {}

-- Lazy require helper
---@generic T
---@param module_path string
---@return T|nil
local function safe_require(module_path)
  local ok, mod = pcall(require, module_path)
  if not ok then
    local notify_ok, notify = pcall(require, "lib.notify")
    if notify_ok and notify and type(notify.create) == "function" then
      local n = notify.create("uv_doc")
      n("Failed to load module: " .. module_path .. " - " .. tostring(mod), vim.log.levels.ERROR)
    else
      notify.error("[uv_doc] Failed to load: " .. module_path)
    end
    return nil
  end
  return mod
end

--- Shows documentation for exact or fuzzy symbol
---@param name string|nil
function M.doc(name)
  local ui = safe_require("usrcmds.uv_doc.ui")
  if not ui then
    return
  end

  ui.show_doc(name)
end

--- Opens interactive symbol list
---@param query string|nil
function M.list(query)
  local ui = safe_require("usrcmds.uv_doc.ui")
  if not ui then
    return
  end

  ui.show_list(query)
end

--- Inserts signature at cursor
---@param name string|nil
function M.here(name)
  local insert = safe_require("usrcmds.uv_doc.insert")
  if not insert then
    return
  end

  insert.insert_signature(name)
end

--- Clears all caches
function M.cache_clear()
  local cache = safe_require("usrcmds.uv_doc.cache")
  if not cache then
    return
  end

  cache.clear_all()
end

--- Provides command-line completion
---@param arglead string
---@param cmdline string|nil
---@param cursorpos integer|nil
---@return string[]
function M.complete(arglead, cmdline, cursorpos)
  local completion = safe_require("usrcmds.uv_doc.completion")
  if not completion then
    return {}
  end

  return completion.complete(arglead, cmdline, cursorpos)
end

--- Registers user commands
function M.enable_usercmd()
  vim.api.nvim_create_user_command("UVDoc", function(cmd)
    M.doc(#cmd.args > 0 and cmd.args or nil)
  end, {
    nargs = "?",
    desc = "Show libuv documentation (exact or fuzzy)",
    complete = M.complete,
  })

  vim.api.nvim_create_user_command("UVDocList", function(cmd)
    M.list(#cmd.args > 0 and cmd.args or nil)
  end, {
    nargs = "?",
    desc = "Interactive libuv symbol picker",
    complete = M.complete,
  })

  vim.api.nvim_create_user_command("UVDocHere", function(cmd)
    M.here(#cmd.args > 0 and cmd.args or nil)
  end, {
    nargs = "?",
    desc = "Insert libuv signature at cursor",
    complete = M.complete,
  })

  vim.api.nvim_create_user_command("UVDocCacheClear", function()
    M.cache_clear()
  end, { desc = "Clear uvdoc caches" })
end

return M
