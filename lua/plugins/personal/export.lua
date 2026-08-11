---@module 'plugins.personal.export'
--- The shared interface `:DocMapAll` (this config, see
--- `bindings.usrcmds.docmap_all`) and docmap-desktop's own spec-import
--- feature are both meant to be built against: which personal plugins are
--- enabled right now, and where each one's local checkout actually is.
---
--- Built on `plugins.personal.list` — the same drift-proof, fully-resolved
--- entry list `:MyPlugins clone`/`remove` and the statusline's own/external
--- badge already read — rather than re-deriving activation from
--- `source.lua`'s raw mode table a second time. What this file adds on top
--- is the one thing `list.lua` deliberately does not carry: a resolved
--- local directory, via the same `personal_utils.local_dev()` every other
--- consumer of "where is this repo really" already goes through.
---
--- A remote-mode entry (no local checkout on this machine) has nothing to
--- point documentation.nvim at — there is no tree on disk to scan — so it
--- is filtered out here rather than returned with a directory a caller
--- would have to remember to check for `nil`.

local personal_utils = require("plugins.personal.utils")

local M = {}

--- `name` doubles as the runtime-analysis.nvim telemetry namespace already
--- active for that plugin by default (see `config/telemetry.lua`, which
--- reads this exact same entry list) — passing it straight through as
--- documentation.nvim's `title` keeps a generated map's Telemetry panel
--- joined to real, already-collected data with no extra wiring.
---@class Plugins.Personal.Project
---@field name string Basename, e.g. "markdown.nvim".
---@field repo string Full "owner/repo", e.g. "StefanBartl/markdown.nvim".
---@field dir string Absolute local checkout path.

---Every enabled personal plugin that has a local checkout on this machine.
---@return Plugins.Personal.Project[] projects Sorted by name, so two calls in the same session agree on order.
---@return string? err Set only when the entry list itself failed to read — no local checkouts is `nil, nil`.
function M.projects()
  local entries, err = require("plugins.personal.list").read()
  if not entries then
    return {}, err
  end

  ---@type Plugins.Personal.Project[]
  local out = {}
  for _, entry in ipairs(entries) do
    local dir = personal_utils.local_dev(entry.name)
    if dir then
      out[#out + 1] = { name = entry.name, repo = entry.repo, dir = dir }
    end
  end
  table.sort(out, function(a, b)
    return a.name < b.name
  end)
  return out, nil
end

return M
