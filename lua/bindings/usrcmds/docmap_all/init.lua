---@module 'bindings.usrcmds.docmap_all'
---@brief Generate documentation.nvim's map for every enabled personal plugin.
---@description
--- Registers `:DocMapAll`. A thin wrapper over `documentation.nvim`'s own
--- `require("documentation").generate_all()` (added there specifically for
--- this use case — see `lua/documentation/editor/generate_all.lua`'s own
--- header): this file supplies the one thing only this config can know
--- (`plugins.personal.export.projects()`, the enabled personal plugins
--- with a local checkout on this machine) and the UI (statusline
--- progress, a closing notification); `generate_all()` supplies the
--- actual orchestration — one real headless Neovim subprocess per
--- project, chained sequentially, never blocking this session.
---
--- **Not this file's own async loop any more.** It used to hand-roll the
--- same `vim.system()`-per-project chaining `generate_all()` now does —
--- built here first because the bug that motivated it (`documentation.
--- generate()` in a plain synchronous loop freezing the file explorer for
--- the length of a multi-project run) was found and fixed here first.
--- Moved once the fix proved out, so every documentation.nvim consumer
--- gets it, not just this config — the logic had no dependency on
--- anything personal-config-shaped to begin with.
---
--- `title` is set to the plugin's own short name on purpose rather than
--- left to documentation.nvim's own default — that name is also the exact
--- runtime-analysis.nvim telemetry namespace `config/telemetry.lua`
--- already writes to for every one of these plugins (deep instrumentation,
--- on by default, reading this same entry list), so a generated map's
--- Telemetry panel is joined to real, already-collected data with no
--- extra wiring on either side.
---
--- One project failing (a scan error, a LuaLS timeout, a non-zero exit)
--- does not abort the rest; the closing report names every one that
--- failed once the whole batch finishes — same posture as
--- `:MyReposUpdate`.
---
--- Deliberately never fires on its own. Generation writes into `docs/map`
--- *inside* each project's own repository, and running that unasked
--- across two dozen repos on every plugin update or config reload would
--- be exactly the kind of uninvited, hard-to-notice git-diff-producing
--- side effect the desktop app's own auto-generate logic was built to
--- avoid (`docmap-desktop`, `autoGenerate()`: only fires when a project
--- has no map yet, never re-fires on one that does). `:DocMapAll` is the
--- explicit request that path deliberately declines to infer.

local notify = require("lib.nvim.notify").create("[usrcmds.docmap_all]")
local usercmd = require("lib.nvim.usercmd")

local M = {}

-- "statusline" reports into the shared lib.nvim.progress registry, same
-- convention as plugin_repos/update_repos — see
-- lua/wkdnvchad/ui/statusline/modules/plugin_progress/init.lua.
local ok_progress, progress_mod = pcall(require, "lib.nvim.progress")
local function new_progress()
  if not ok_progress then
    return nil
  end
  return progress_mod.create({ title = "[usrcmds.docmap_all]", style = "statusline" })
end

local function generate_all()
  local ok_export, export_mod = pcall(require, "plugins.personal.export")
  if not ok_export then
    notify.error("cannot load plugins.personal.export: " .. tostring(export_mod))
    return
  end

  local projects, err = export_mod.projects()
  if err then
    notify.error(err)
    return
  end
  if #projects == 0 then
    notify.info("No personal plugin has a local checkout to map on this machine")
    return
  end

  local ok_docmap, docmap = pcall(require, "documentation")
  if not ok_docmap then
    notify.error("documentation.nvim is not available: " .. tostring(docmap))
    return
  end

  local total = #projects
  local prog = new_progress()

  -- generate_all() wants {root, title}; export_mod.projects() hands back
  -- {name, repo, dir} — one field rename, done here rather than teaching
  -- documentation.nvim this config's own project shape.
  local gen_projects = {}
  for _, p in ipairs(projects) do
    gen_projects[#gen_projects + 1] = { root = p.dir, title = p.name }
  end

  notify.info("Generating maps asynchronously...")
  docmap.generate_all.run(gen_projects, {
    on_progress = function(index, index_total, project)
      if prog then
        prog:update({ text = project.title, current = index, total = index_total })
      end
    end,
    on_done = function(results)
      ---@type string[]
      local failed = {}
      for _, r in ipairs(results) do
        if not r.ok then
          failed[#failed + 1] = r.project.title .. ": " .. tostring(r.err)
        end
      end

      if prog then
        prog:finish(("%d/%d generated"):format(total - #failed, total))
      end

      if #failed > 0 then
        notify.error("Finished with errors:\n\n" .. table.concat(failed, "\n\n"))
      else
        notify.info(("All %d project map(s) generated"):format(total))
      end
    end,
  })
end

---Register :DocMapAll.
function M.enable()
  usercmd.create("DocMapAll", generate_all, {
    desc = "[usrcmds.docmap_all] Generate documentation.nvim's map for every enabled personal plugin",
  })
end

return M
