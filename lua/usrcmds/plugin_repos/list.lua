---@module 'usrcmds.plugin_repos.list'
--- Parses the canonical plugin list out of the "## Pluginlist" section of
--- docs/ROADMAP/personal/MATERIALS/LIST.md — the single source of truth
--- `:PluginsClone`/`:PluginsRemove` operate on.
---
--- Deliberately not the bash/PowerShell one-liners further down that same
--- file: those two have drifted from the canonical list (a "cascade,nvim"
--- typo — the real repo is "cascade.nvim" — "cmdlog"/"cmdlog.nvim" where the
--- real repo is "nvim-cmdlog", and a duplicated "insights.nvim" entry), so
--- they are a worse source, not an equivalent one. Names are read exactly as
--- written rather than silently "corrected": a typo'd name just fails to
--- clone (harmless 404) or fails to match anything to remove (skipped, not
--- deleted) — guessing at the intended fix risks acting on the wrong repo,
--- which matters a great deal more for :PluginsRemove than getting a report
--- of "0 found" ever could.

local M = {}

---@return string
local function list_path()
  return vim.fs.normalize(vim.fn.stdpath("config") .. "/docs/ROADMAP/personal/MATERIALS/LIST.md")
end

---Repo names from the "## Pluginlist" section, in file order, leading "/"
---stripped. Does not deduplicate — a repeated entry in the source file is
---itself worth surfacing, not silently hidden.
---@return string[]|nil names
---@return string|nil err
function M.read()
  local path = list_path()
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or vim.tbl_isempty(lines) then
    return nil, "cannot read " .. path
  end

  local in_section = false
  local names = {}
  for _, line in ipairs(lines) do
    if line:match("^##%s+Pluginlist%s*$") then
      in_section = true
    elseif in_section and line:match("^##%s") then
      break
    elseif in_section then
      local name = line:match("^`/?([^`]+)`%s*$")
      if name then
        names[#names + 1] = name
      end
    end
  end

  if #names == 0 then
    return nil, "no plugin entries found under '## Pluginlist' in " .. path
  end
  return names, nil
end

return M
