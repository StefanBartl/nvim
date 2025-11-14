---@module 'lsp.servers.lua_ls.rootresolver'
-- Utilities to resolve a project's root directory from a filename or buffer.
-- This module exposes:
--  - strict_root_from(fname) : determine a strict project root from a filename or CWD
--  - make_root_dir_resolver() : return a polymorphic resolver usable by LSP configs

local is_subpath = require("lib.filesystem.is_subpath")

--- Determine a strict root directory from a filename or use sensible fallbacks.
--- Steps:
--- 1. Determine a starting directory: directory of fname or CWD.
--- 2. If the start dir is under Neovim's stdpath("config"), return that config path.
--- 3. If a VCS root (git/hg/svn) is found upward, return it.
--- 4. If certain Lua/tool config markers are found upward, return the marker's dirname.
--- 5. Otherwise return the start dir itself.
--- @param fname string|nil filename or filepath; can be empty string
--- @return string|nil root directory or nil when no directory could be determined
local function strict_root_from(fname)
  -- starte an der Verzeichnis-Komponente der Datei; Fallback: CWD
  local dir = (type(fname) == "string" and fname ~= "" and vim.fs.dirname(vim.fs.normalize(fname)))
    or ((vim.uv or vim.loop).cwd and (vim.uv or vim.loop).cwd())
    or vim.fn.getcw()

	local stdconfig = vim.fn.stdpath("config")
	if is_subpath(dir, stdconfig) then
		return stdconfig
	end

	if not dir or dir == "" then
		return nil
	end

	local vcs_root = vim.fs.root(dir, { ".git", ".hg", ".svn" })
  if vcs_root then
    return vcs_root
  end

  local lua_markers = vim.fs.find(
    { ".luarc.json", ".neoconf.json", "selene.toml", "stylua.toml" },
    { path = dir, upward = true }
  )
  if lua_markers and lua_markers[1] then
    return vim.fs.dirname(lua_markers[1])
  end

  return dir
end

--- Create a polymorphic root-directory resolver.
--- The returned function accepts either:
--- - (bufnr: number, cb: function?) OR
--- - (fname: string, cb: function?)
--- If a buffer number is given, the buffer's filename is used as input.
--- If a callback `cb` is provided, it is invoked with the resolved root.
--- The resolved root is returned synchronously.
return function(arg, cb)
  local fname = ""
  if type(arg) == "number" then
    fname = vim.api.nvim_buf_get_name(arg) or ""
  elseif type(arg) == "string" then
    fname = arg
  end

  local root_dir = strict_root_from(fname)
  if cb and type(cb) == "function" then
    pcall(cb, root_dir)
  end
  return root_dir
end
