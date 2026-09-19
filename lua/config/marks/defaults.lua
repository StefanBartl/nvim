---@module 'config.marks.defaults'
--- The files that are one keypress away in every project: the default mark
--- list, as path specs. Each entry is a list of segments whose first may be
--- `$REPOS_DIR`, `$HOME` or `$NVIM_HOME` (the config directory), resolved by
--- the consumer on the machine it runs on.
---
--- One table, two consumers, for as long as the harpoon -> sessions.nvim
--- switch runs in parallel: harpoon's `config.harpoon.persist_paths` seeds
--- its bucket from it, and sessions.nvim's `marks.defaults` seeds its store
--- from it. It used to be a local inside the harpoon spec in
--- `plugins/misc.lua`; the second consumer is why it is a module.
---
--- The workstation set is prepended, not appended: on that machine the case
--- workflow files are what gets opened most, and slot 1..5 is where a
--- numbered jump is cheapest.

local machine = require("machine")

---@type (string|string[])[]
local personal = {
  { "$NVIM_HOME", "lua", "plugins", "personal", "init.lua" },
  { "$NVIM_HOME", "docs", "ROADMAP", "ROADMAP.md" },
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
---@type (string|string[])[]
local workstation = {
  { "$REPOS_DIR", "WKDBook-Tricentis", "Cases", "Workflow", "Workflow.md" },
  { "$REPOS_DIR", "WKDBook-Tricentis", "Cases", "Workflow", "Templates", "FirstResponse_Rick.md" },
  {
    "$REPOS_DIR",
    "WKDBook-Tricentis",
    "Cases",
    "Workflow",
    "Templates",
    "SAP_TBox_RequestInfos.md",
  },
  { "$REPOS_DIR", "WKDBook-Tricentis", "Cases", "Workflow", "Templates", "RequestMoreInfo.md" },
  { "$REPOS_DIR", "WKDBook-Tricentis", "ToDo-Collection", "SAP_Support_ToDo.md" },
  personal[1],
  personal[2],
  personal[3],
}

return workstation
