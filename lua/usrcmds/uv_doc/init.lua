
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

-- Lazy-loaded submodules (loaded on first use)
local http = nil
local parser = nil
local cache = nil
local ui = nil
local completion = nil

--- Ensures submodule is loaded
---@param module_name string
---@return table
local function ensure_loaded(module_name)
  local modules = {
    http = function()
      return require("usrcmds.uv_doc.http")
    end,
    parser = function()
      return require("usrcmds.uv_doc.parser")
    end,
    cache = function()
      return require("usrcmds.uv_doc.cache")
    end,
    ui = function()
      return require("usrcmds.uv_doc.ui")
    end,
    completion = function()
      return require("usrcmds.uv_doc.completion")
    end,
  }

  local loader = modules[module_name]
  if not loader then
    error("Unknown submodule: " .. module_name)
  end

  return loader()
end

--- Shows documentation for exact or fuzzy symbol
---@param name string|nil
function M.doc(name)
  http = http or ensure_loaded("http")
  parser = parser or ensure_loaded("parser")
  cache = cache or ensure_loaded("cache")
  ui = ui or ensure_loaded("ui")

  ui.show_doc(name)
end

--- Opens interactive symbol list
---@param query string|nil
function M.list(query)
  cache = cache or ensure_loaded("cache")
  ui = ui or ensure_loaded("ui")

  ui.show_list(query)
end

--- Inserts signature at cursor
---@param name string|nil
function M.here(name)
  http = http or ensure_loaded("http")
  parser = parser or ensure_loaded("parser")
  cache = cache or ensure_loaded("cache")

  local insert = require("usrcmds.uv_doc.insert")
  insert.insert_signature(name)
end

--- Clears all caches
function M.cache_clear()
  cache = cache or ensure_loaded("cache")
  cache.clear_all()
end

--- Provides command-line completion
---@param arglead string
---@param cmdline string|nil
---@param cursorpos integer|nil
---@return string[]
function M.complete(arglead, cmdline, cursorpos)
  completion = completion or ensure_loaded("completion")
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

