---@module 'plugins.personal.list'
--- Repo list sourced directly from `plugins.personal` — the actual, fully
--- resolved lazy spec (`plugins/personal/init.lua`'s `.add({...})`, with
--- `plugins/personal/source.lua`'s per-repo mode already applied) — rather
--- than parsed out of a hand-maintained markdown doc.
---
--- Was originally the markdown doc (docs/ROADMAP/personal/MATERIALS/LIST.md).
--- Moved off it because that doc had already drifted from what lazy.nvim
--- actually loads: a "cascade,nvim" typo where the real repo is
--- "cascade.nvim", "cmdlog"/"cmdlog.nvim" naming inconsistencies, a
--- duplicated "insights.nvim" entry, a "migrate.nvim" entry with no spec at
--- all, and no way to represent "learn-cli.nvim exists but is deliberately
--- disabled" the way source.lua's mode table can. The lazy spec is the one
--- thing that cannot drift from itself — it *is* what actually gets loaded.
---
--- Requiring `plugins.personal` only builds and returns the spec table; none
--- of the individual plugins' `config()` functions run (lazy.nvim invokes
--- those itself, later, at load time) — so this is a plain, side-effect-free
--- data read, not a partial plugin bootstrap.
---
--- Lives here rather than under `usrcmds.plugin_repos` (its original home):
--- consumers now span both `usrcmds` (`:MyPluginsClone`/`:MyPluginsRemove`)
--- and `wkdnvchad.ui.statusline` (`plugin_summary`'s own/external count
--- badge), neither of which should reach into the other's namespace for
--- shared data that is really just a derived view of `plugins.personal`.

local M = {}

---@class Plugins.Personal.Entry
---@field repo string Full "owner/repo" exactly as declared in the spec, e.g. "StefanBartl/lib.nvim".
---@field name string Basename used as both the local folder name and source.lua's mode-table key, e.g. "lib.nvim" — derived the same way `plugins.control.mode` itself derives it, so a lookup here always agrees with what the spec loader decided.

---Every repo the personal spec declares, filtered to what's actually meant
---to be present on disk. A spec the resolver marked `enabled = false` —
---source.lua's "disabled" mode, e.g. `learn-cli.nvim` — is excluded: those
---are "neither local nor remote" by explicit choice, not an oversight, so
---`:MyPluginsClone` should not fetch them and `:MyPluginsRemove` should not
---report on repos that were never supposed to be cloned in the first place.
---@return Plugins.Personal.Entry[]|nil entries
---@return string|nil err
function M.read()
  local ok, specs = pcall(require, "plugins.personal")
  if not ok then
    return nil, "cannot load plugins.personal: " .. tostring(specs)
  end
  if type(specs) ~= "table" then
    return nil, "plugins.personal did not return a spec table"
  end

  ---@type Plugins.Personal.Entry[]
  local entries = {}
  for _, spec in ipairs(specs) do
    local repo = spec[1]
    if type(repo) == "string" and spec.enabled ~= false then
      entries[#entries + 1] = { repo = repo, name = vim.fn.fnamemodify(repo, ":t") }
    end
  end

  if #entries == 0 then
    return nil, "plugins.personal returned no enabled repos"
  end
  return entries, nil
end

return M
