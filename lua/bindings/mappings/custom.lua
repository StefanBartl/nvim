---@module 'bindings.mappings.custom'

local M = {}

function M.setup()
  local map = vim.g.__map_helper

  map("n", "<leader>cp", function()
    vim.fn.setreg("+", vim.fn.expand("%:p"))
    print("Copied path to clipboard")
  end, { desc = "[General] Copy file path" })

  -- casedesk SESSIONS.md §5: save under the case number when the current
  -- buffer belongs to one, otherwise sessions.nvim's own auto-resolve
  -- (project/branch-aware) — not a hardcoded "last", see docs/ROADMAP/
  -- casedesk/SESSIONS.md for why. Deliberately explicit-only: no autosave
  -- hook overwrites a case session on exit (§8's "wrong layout" risk).
  map("n", "<leader>cs", function()
    local ok_sessions, sessions = pcall(require, "sessions")
    if not ok_sessions then
      vim.notify("[casedesk] sessions.nvim not available", vim.log.levels.WARN)
      return
    end
    local ok_resolve, resolve = pcall(require, "bindings.usrcmds.case.resolve")
    local entry = ok_resolve and resolve.sync(nil) or nil
    sessions.save(entry and entry.short or nil)
  end, { desc = "[casedesk] Save session (case-aware)" })

  -- Moved from bindings.mappings.snacks — that file is never required from
  -- bindings.mappings.init.setup(), so anything added there is dead: the
  -- keys silently fall through to native Nvim commands instead (this exact
  -- mapping did, which is how "<leader>UN" turned into plain "U" + "N" and
  -- threw E486 off a stale search register).
  map("n", "<leader>UN", function()
    require("snacks").picker.undo()
  end, { desc = "[snacks] Undo History" })

end

return M
