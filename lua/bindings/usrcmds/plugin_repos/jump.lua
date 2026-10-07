---@module 'bindings.usrcmds.plugin_repos.jump'
---@brief `:MyPlugins jumpTo <name>` -- open the install spec of a personal plugin.
---@description
--- Scans the per-category spec files in `lua/plugins/personal/specs/` for the
--- line that declares `"<owner>/<name>"` as the first element of a lazy spec
--- (`{ "owner/name", ... }` or a bare `"owner/name",` line) and opens that file
--- with the cursor on it. Plain text scan, no spec evaluation: the spec files
--- are the source of truth and the line is what the user wants to edit.

local M = {}

---Directory holding the per-category spec files.
---@return string
local function specs_dir()
  return vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "plugins", "personal", "specs")
end

---Whether a source line declares the given plugin as a spec head: either
---`{ "owner/name", ...` or a bare `"owner/name",` line right after a lone `{`.
---A bare string inside `dependencies = { ... }` is not preceded by a lone `{`.
---@param line string
---@param prev string Previous non-comment, non-blank line
---@param name string Plugin basename, e.g. "sessions.nvim"
---@return boolean
local function is_spec_head(line, prev, name)
  local inline, repo = line:match("^%s*({?)%s*[\"']([%w_.%-]+/[%w_.%-]+)[\"']")
  if not repo or repo:lower():match("/(.+)$") ~= name:lower() then
    return false
  end
  return inline == "{" or prev:match("^%s*{%s*$") ~= nil
end

---Locate the spec declaration of a plugin.
---@param name string
---@return { file: string, lnum: integer, col: integer }|nil
function M.find(name)
  local dir = specs_dir()
  for _, fname in ipairs(vim.fn.sort(vim.fn.readdir(dir))) do
    if fname:match("%.lua$") then
      local file = vim.fs.joinpath(dir, fname)
      local ok, lines = pcall(vim.fn.readfile, file)
      if ok then
        local prev = ""
        for lnum, line in ipairs(lines) do
          if is_spec_head(line, prev, name) then
            local col = line:find("[\"']") or 1
            return { file = file, lnum = lnum, col = col }
          end
          if line:match("%S") and not line:match("^%s*%-%-") then
            prev = line
          end
        end
      end
    end
  end
  return nil
end

---Open the spec file of `name` at its declaration.
---@param name string
---@return boolean ok
function M.jump(name)
  local notify = require("lib.nvim.notify").create("[usrcmds.plugin_repos]")
  local hit = M.find(name)
  if not hit then
    notify.warn(("No install spec for '%s' found in plugins/personal/specs"):format(name))
    return false
  end
  vim.cmd("edit " .. vim.fn.fnameescape(hit.file))
  vim.api.nvim_win_set_cursor(0, { hit.lnum, hit.col - 1 })
  vim.cmd("normal! zz")
  return true
end

return M
