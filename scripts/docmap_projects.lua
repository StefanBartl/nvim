-- scripts/docmap_projects.lua — headless JSON export of every personal
-- plugin documentation.nvim can map on this machine.
--
--   nvim --headless -c "luafile scripts/docmap_projects.lua" -c "qa"
--
-- **Must be `-c "luafile ..."`, not `-l`.** Measured, not assumed: plain
-- `nvim --headless -l scripts/docmap_projects.lua` fails to even find
-- `lib.nvim` (`module 'lib.nvim.notify' not found`), because `-l` is a
-- bare Lua-script runner that does not load the user's `init.lua` or run
-- lazy.nvim's bootstrap at all — the exact reason documentation.nvim's own
-- `-l` scripts (`scripts/gen_map.lua`, `scripts/mcp_server.lua`) manually
-- search for and prepend `lib.nvim` to the runtimepath themselves, rather
-- than assuming any plugin manager has run. This script has no such
-- workaround because there is nothing simple to work around *to* — it
-- needs this config's real, fully-resolved plugin policy (source.lua's
-- mode table, machine detection, the whole personal spec), and that only
-- exists after a real startup has actually run. `-c "luafile ..." -c
-- "qa"` goes through the normal startup sequence first (confirmed:
-- `lib.nvim.notify` resolves, `require("machine")` resolves, the full
-- 27-project list comes back correct); `-l` alone never gets there.
--
-- The shared interface `:DocMapAll` (this config's own
-- `bindings.usrcmds.docmap_all`) and docmap-desktop's own spec-import
-- feature are both meant to be built against, instead of the app guessing
-- at `plugins/personal/source.lua`'s policy table by parsing Lua from
-- Rust — brittle in a way neither side should have to maintain. See
-- docmap-desktop's own docs/HANDOVER.md for the decision this answers.
--
-- stdout carries only the JSON array, one line, no pretty-printing, so a
-- subprocess reading it does not have to skip banner text or guess where
-- JSON starts. Anything that goes wrong is reported on stderr and the
-- process exits non-zero — the shape a subprocess caller can check on
-- `.code` without parsing stdout at all in the failure case.

local ok, projects_mod = pcall(require, "plugins.personal.export")
if not ok then
  io.stderr:write(
    "docmap_projects: cannot load plugins.personal.export: " .. tostring(projects_mod) .. "\n"
  )
  os.exit(1)
end

local projects, err = projects_mod.projects()
if err then
  io.stderr:write("docmap_projects: " .. err .. "\n")
  os.exit(1)
end

io.stdout:write(vim.json.encode(projects) .. "\n")
os.exit(0)
