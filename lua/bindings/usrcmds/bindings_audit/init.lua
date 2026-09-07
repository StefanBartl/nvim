---@module 'bindings.usrcmds.bindings_audit'
---@brief `:LibBindingsAudit[Keys|Gaps|Prefixes]` and `:LibKeymapConflicts` —
---cross-registry checks over whatever this session actually loaded: keymap
---action vs. command route coverage, portable-key risk, `<Tab>`/prefix
---ambiguity between live command names, and `lhs` values claimed by more
---than one registration.
---@description
--- Same reasoning as `bindings.usrcmds.autocmd_docs`: the underlying
--- functions live in lib.nvim (`bindings.audit`, `bindings.keymap`), and the
--- `create_usercmd()` call that turns them into typable commands belongs
--- here — tooling for whoever edits the repos, not something every plugin
--- should ship a copy of.
---
--- Both were real lib.nvim modules with **no wired command anywhere** before
--- this file existed — see
--- `docs/ROADMAP/personal/All/FINISH/ERLEDIGT/roadmap-tools-analysis.md`
--- (Nachtrag 2026-09-05) for `bindings.audit`'s history of exactly that gap,
--- and `docs/ROADMAP/handovers/CDX-bindings-runtime-check.md` for why
--- `bindings.keymap.conflicts()` had the same problem.
---
--- **What these can and cannot see**, same caveat as autocmd_docs: a
--- lazy-loaded plugin that has not fired its trigger yet has registered
--- nothing, so a clean report this early is not evidence of anything.
--- `:LibKeymapConflicts`' own output notes how many lazy-tracked plugins are
--- loaded when the count is incomplete.

local M = {}

---@return nil
function M.enable()
  require("lib.nvim.bindings.audit").create_usercmd()
  require("lib.nvim.bindings.keymap").create_usercmd()
end

return M
