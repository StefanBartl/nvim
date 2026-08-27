---@module 'bindings.mappings.custom'
--- The two one-off keymaps that fit no other group: `<leader>cp` copies the
--- current file path, `<leader>cs` saves a casedesk session.

local M = {}

local notify = require("lib.nvim.notify").create("[casedesk]")

function M.setup()
  local map = require("lib.nvim.bindings.keymap")

  map("n", "<leader>cp", function()
    vim.fn.setreg("+", vim.fn.expand("%:p"))
    notify.info("Copied path to clipboard")
  end, { desc = "[General] Copy file path" })

  -- casedesk SESSIONS.md §5: save under the case number when the current
  -- buffer belongs to one, otherwise sessions.nvim's own auto-resolve
  -- (project/branch-aware) — not a hardcoded "last", see docs/ROADMAP/
  -- casedesk/SESSIONS.md for why. Deliberately explicit-only: no autosave
  -- hook overwrites a case session on exit (§8's "wrong layout" risk).
  map("n", "<leader>cs", function()
    local ok_sessions, sessions = pcall(require, "sessions")
    if not ok_sessions then
      notify.warn("sessions.nvim not available")
      return
    end
    local ok_resolve, resolve = pcall(require, "bindings.usrcmds.case.resolve")
    local entry = ok_resolve and resolve.sync(nil) or nil
    sessions.save(entry and entry.short or nil)
  end, { desc = "[casedesk] Save session (case-aware)" })

end

return M
