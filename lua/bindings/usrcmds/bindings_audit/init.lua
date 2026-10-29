---@module 'bindings.usrcmds.bindings_audit'
---@brief `:LibBindingsAudit[Keys|Gaps|Prefixes|Naming|Checklist]`,
---`:LibKeymapConflicts` and `:BindingsRuntimeChecklist` — cross-registry
---checks over whatever this session actually loaded: keymap action vs.
---command route coverage, portable-key risk, `<Tab>`/prefix ambiguity,
---`lhs` collisions, naming-review candidates, and a Markdown runtime
---checklist written to disk.
---@description
--- Same reasoning as `bindings.usrcmds.autocmd_docs`: the underlying
--- functions live in lib.nvim (`bindings.audit`, `bindings.keymap`), and the
--- `create_usercmd()` call that turns them into typable commands belongs
--- here — tooling for whoever edits the repos, not something every plugin
--- should ship a copy of.
---
--- Both were real lib.nvim modules with **no wired command anywhere** before
--- this file existed — see
--- `$REPOS_DIR/tasks-vault/ALL/Backlog/TASKS/roadmap-tools-analysis.md`
--- (Nachtrag 2026-09-05) for `bindings.audit`'s history of exactly that gap,
--- and `$REPOS_DIR/tasks-vault/nvim-config/Backlog/TASKS/CDX-bindings-runtime-check.md`
--- for why `bindings.keymap.conflicts()` had the same problem.
---
--- **What these can and cannot see**, same caveat as autocmd_docs: a
--- lazy-loaded plugin that has not fired its trigger yet has registered
--- nothing, so a clean report this early is not evidence of anything.
--- `:LibKeymapConflicts`' own output notes how many lazy-tracked plugins are
--- loaded when the count is incomplete.
---
--- `:BindingsRuntimeChecklist` lives here rather than as a `create_usercmd`
--- sub-command in lib.nvim: it decides *where in this repo* to write, which
--- is a config choice, same reasoning `:Bindings report`'s `config.
--- report_dir()` already follows in `bindings_explorer`. It refuses to
--- overwrite an existing file without `!` — the checklist is meant to be
--- hand-edited over time (boxes ticked, findings noted), and a silent
--- regeneration would erase that.
---
--- `:BindingsRuntimeChecklistDrift` is the read-only counterpart: it compares
--- the file with what this session would generate (`drift.lua`) and lists
--- the entries that are gone (with their line in the file) and the new ones
--- in the quickfix list, so the file can be updated by hand without losing
--- ticks. Same lazy-loading caveat: `:Lazy load all` first.

local M = {}

---@return nil
function M.enable()
  require("lib.nvim.bindings.audit").create_usercmd()
  require("lib.nvim.bindings.keymap").create_usercmd()

  local usercmd = require("lib.nvim.bindings.usercmd")
  local notify = require("lib.nvim.notify").create("[bindings.audit]")

  usercmd.create("BindingsRuntimeChecklist", function(opts)
    local report_dir = require("bindings.usrcmds.bindings_explorer.config").report_dir()
    local path = vim.fs.joinpath(report_dir, "BINDINGS-RUNTIME-CHECKLIST.md")

    if vim.fn.filereadable(path) == 1 and not opts.bang then
      notify.warn(
        ("already exists: %s -- pass ! to regenerate (this resets any boxes you already ticked)"):format(
          path
        )
      )
      return
    end

    vim.fn.mkdir(report_dir, "p")
    local lines = require("lib.nvim.bindings.audit").checklist_lines()
    vim.fn.writefile(lines, path)
    notify.info(("%d lines -> %s"):format(#lines, path))
  end, {
    bang = true,
    desc = "Write the runtime checklist (lib.nvim.bindings.audit.checklist_lines) to docs/ROADMAP/Final_Checks/BINDINGS-RUNTIME-CHECKLIST.md; ! to overwrite",
  })

  -- Read-only counterpart: what regenerating would change, without resetting the ticks. A
  -- lazy-loaded plugin that has not loaded yet registered nothing, so its entries show up as
  -- gone; `:Lazy load all` first gives the full picture.
  usercmd.create("BindingsRuntimeChecklistDrift", function()
    local report_dir = require("bindings.usrcmds.bindings_explorer.config").report_dir()
    local path = vim.fs.joinpath(report_dir, "BINDINGS-RUNTIME-CHECKLIST.md")
    local ok, file_lines = pcall(vim.fn.readfile, path)
    if not ok or #file_lines == 0 then
      notify.warn(("cannot read %s -- run :BindingsRuntimeChecklist first"):format(path))
      return
    end

    local drift = require("bindings.usrcmds.bindings_audit.drift").diff(
      file_lines,
      require("lib.nvim.bindings.audit").checklist_lines()
    )
    local items = {}
    for _, e in ipairs(drift.gone) do
      items[#items + 1] = { filename = path, lnum = e.lnum, text = "gone: " .. e.text }
    end
    for _, e in ipairs(drift.new) do
      local where = e.group ~= "" and (e.section .. " / " .. e.group) or e.section
      items[#items + 1] =
        { filename = path, lnum = 0, valid = 0, text = ("new (%s): %s"):format(where, e.text) }
    end
    vim.fn.setqflist({}, " ", { title = "Bindings checklist drift", items = items })

    local msg = ("%d gone, %d new -> quickfix"):format(#drift.gone, #drift.new)
    if #items == 0 then
      notify.info("checklist matches this session")
    else
      notify.info(msg .. " (lazy plugins not loaded yet count as gone: :Lazy load all first)")
      vim.cmd("copen")
    end
  end, {
    desc = "Compare BINDINGS-RUNTIME-CHECKLIST.md with what this session would generate; gone and new entries to the quickfix list, the file is not touched",
  })
end

return M
