---@module 'bindings.usrcmds.docmap_all'
---@brief Generate documentation.nvim's map for every enabled personal plugin.
---@description
--- Registers `:DocMapAll`. Runs `require("documentation").generate({root =
--- ..., luals = true, title = <plugin name>})` for every entry
--- `plugins.personal.export.projects()` returns — every personal plugin
--- that is enabled (source.lua's mode is not "disabled") and has a local
--- checkout on this machine. Sequential, not parallel, for the same reason
--- `:MyReposUpdate` and docmap-desktop's own "Generate all" button both
--- are: each run is a real CPU-bound process (documentation.nvim's own
--- LuaLS enrichment pass, `full` mode), and a dozen at once would not
--- finish sooner while making the editor genuinely unresponsive rather
--- than just slow.
---
--- `title` is set to the plugin's own short name on purpose rather than
--- left to documentation.nvim's own default — that name is also the exact
--- runtime-analysis.nvim telemetry namespace `config/telemetry.lua`
--- already writes to for every one of these plugins (deep instrumentation,
--- on by default, reading this same entry list), so a generated map's
--- Telemetry panel is joined to real, already-collected data with no
--- extra wiring on either side.
---
--- One project failing (a scan error, a LuaLS timeout) does not abort the
--- rest; the closing report names every one that failed once the whole
--- batch finishes — same posture as `:MyReposUpdate`.
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
  ---@type string[]
  local failed = {}

  -- A plain synchronous loop, not update_repos's own async run_next()
  -- chain: that pattern exists there because vim.system's callback is the
  -- only shape available at that layer. documentation.generate() is
  -- already a blocking-but-event-loop-friendly call one level up (its own
  -- LuaLS subprocess uses spawn_capture + vim.wait internally, the same
  -- fix this session's own documentation.nvim work already applied for
  -- exactly this reason — plain :wait() does not drain scheduled
  -- callbacks, vim.wait does), so nothing here needs to re-solve that.
  for i, project in ipairs(projects) do
    if prog then
      prog:update({ text = project.name, current = i, total = total })
    end

    local ok_gen, gen_err = pcall(docmap.generate, {
      root = project.dir,
      title = project.name,
      luals = true,
    })
    if not ok_gen then
      failed[#failed + 1] = project.name .. ": " .. tostring(gen_err)
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
end

---Register :DocMapAll.
function M.enable()
  usercmd.create("DocMapAll", generate_all, {
    desc = "[usrcmds.docmap_all] Generate documentation.nvim's map for every enabled personal plugin",
  })
end

return M
