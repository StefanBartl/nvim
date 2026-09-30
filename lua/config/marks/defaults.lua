---@module 'config.marks.defaults'
--- The files that are one keypress away in every project: the default mark
--- list, as path specs. Each entry is a list of segments whose first may be
--- `$REPOS_DIR`, `$HOME` or `$NVIM_HOME` (the config directory), resolved by
--- the consumer on the machine it runs on.
---
--- Consumed by sessions.nvim's `marks.defaults` (plugins/personal/init.lua).
--- Used to be a local inside harpoon's spec in `plugins/misc.lua`, and briefly
--- fed both harpoon and sessions.nvim while the two ran in parallel; harpoon
--- is gone since 2026-09-19 (external-plugins report, 7.4), and this stayed
--- a module rather than moving back into the spec since a second consumer
--- can always show up again.
---
--- The workstation set is prepended, not appended: on that machine the case
--- workflow files are what gets opened most, and slot 1..5 is where a
--- numbered jump is cheapest.

local machine = require("machine")

---@type (string|string[])[]
local personal = {
  { "$NVIM_HOME", "lua", "plugins", "personal", "init.lua" },
  { "$NVIM_HOME", "docs", "ROADMAP", "00_ROADMAP.md" },
  { "$REPOS_DIR", "WKDBooks", "Spickzettel", "spickzettel.md" },
  { "$REPOS_DIR", "WKDBooks", "Development", "wkdbook-Lua", "Notes", "LuaNotes.md" },
  {
    "$REPOS_DIR",
    "WKDBooks",
    "Development",
    "wkdbook-Neovim",
    "Referenz_Notes",
    "98_cheatsheets",
    "tastaturkuerzel-konsolidiert.md",
  },
}

if not machine.is("workstation") then
  return personal
end

-- Work-specific targets: only exist, and only matter, on the workstation.
-- `Cases/Workflow/...` used to be where these Templates lived; the repo
-- moved them up to `Workflow/Templates/...` directly, which is why the old
-- entries here silently resolved to nothing.
---@type (string|string[])[]
local workstation = {
  { "$REPOS_DIR", "WKDBook-Tricentis", "ToDo-Collection", "SAP_Support_ToDo.md" },
  { "$REPOS_DIR", "WKDBook-Tricentis", "Workflow", "Templates", "FirstResponse_Rick.md" },
  { "$REPOS_DIR", "WKDBook-Tricentis", "Workflow", "Templates", "Solution.md" },
  { "$REPOS_DIR", "WKDBooks", "Spickzettel", "support_spickzettel.md" },
  personal[2],
}

return workstation
