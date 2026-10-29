---@module 'workstation-setup-reminder'
---@brief One-off reminder: run `setup-claude-code.ps1` once on the workstation.
---@description
--- Loaded from `after/plugin/zz-workstation-setup-reminder.lua`. Does nothing unless this machine is the workstation
--- (`lua/machine.lua`), nvim has a UI and was started without file arguments (not as `$EDITOR`/git editor: a terminal
--- split would keep `:wq` from ending it). On the workstation it opens a terminal split in `docs/NOTES/CDX` with the
--- command typed in but not run: press Enter. When the terminal is closed (not when nvim quits) it asks whether the
--- setup is done; `:WorkstationSetupDone` says so any time. "Done" is a marker file in `stdpath("state")`: per
--- machine and outside the repo, so the tracked files stay and the checkout stays clean. Until then it reminds again
--- on every start. Remove this file and its loader from the repo once no machine needs it any more.

local ok, machine = pcall(require, "machine")
if not ok or not machine.is("workstation") then
  return
end

local marker = vim.fn.stdpath("state") .. "/workstation-setup-reminder.done"
if vim.uv.fs_stat(marker) then
  return
end

local cdx = vim.fn.stdpath("config") .. "/docs/NOTES/CDX"
local command = "pwsh -File ./setup-claude-code.ps1"
-- Read at load time: the argument list of this start, before anything edits it.
local started_on_files = vim.fn.argc(-1) > 0

local function mark_done()
  pcall(vim.fn.mkdir, vim.fs.dirname(marker), "p")
  local written, result = pcall(vim.fn.writefile, { os.date("%Y-%m-%d %H:%M:%S") }, marker)
  if not written or result ~= 0 or not vim.uv.fs_stat(marker) then
    vim.notify(
      ("[setup] Could not write %s (%s); the reminder will come back."):format(
        marker,
        tostring(result)
      ),
      vim.log.levels.ERROR
    )
    return
  end
  pcall(vim.api.nvim_del_user_command, "WorkstationSetupDone")
  vim.notify(
    "[setup] Marked as done (" .. marker .. "); no more reminders on this machine.",
    vim.log.levels.INFO
  )
end

vim.api.nvim_create_user_command("WorkstationSetupDone", mark_done, {
  desc = "Stop the one-off workstation setup reminder on this machine",
})

local function exiting()
  return vim.v.exiting ~= vim.NIL
end

local function offer_done()
  if exiting() then
    return
  end
  vim.ui.select({ "Setup is done, stop reminding", "Remind me again next time" }, {
    prompt = "Workstation setup reminder",
  }, function(_, index)
    if index == 1 then
      mark_done()
    end
  end)
end

local function open_terminal()
  vim.cmd("botright 14new")
  vim.cmd("lcd " .. vim.fn.fnameescape(cdx))
  vim.cmd.terminal()
  local buf = vim.api.nvim_get_current_buf()
  local job = vim.b[buf].terminal_job_id
  vim.api.nvim_create_autocmd("TermClose", {
    buffer = buf,
    once = true,
    callback = function()
      -- Quitting nvim also closes the terminal; that answers nothing about the setup.
      if not exiting() then
        vim.schedule(offer_done)
      end
    end,
  })
  -- The shell needs a moment before the typed text lands on its prompt.
  vim.defer_fn(function()
    if
      not job
      or not vim.api.nvim_buf_is_valid(buf)
      or not pcall(vim.fn.chansend, job, command)
    then
      return
    end
    -- Only take over Insert mode while the terminal still has the focus; the user may have moved on.
    if vim.api.nvim_get_current_buf() == buf then
      vim.cmd("startinsert")
    end
  end, 600)
end

local function remind()
  vim.defer_fn(function()
    -- Headless runs (tools, tests, hooks that start nvim with this config) must not open a shell.
    if #vim.api.nvim_list_uis() == 0 or started_on_files then
      return
    end
    vim.notify(
      "[setup] Workstation: run `"
        .. command
        .. "` once (typed in the terminal below, press Enter). Done: :WorkstationSetupDone",
      vim.log.levels.WARN
    )
    open_terminal()
  end, 800)
end

if vim.v.vim_did_enter == 1 then
  remind()
else
  vim.api.nvim_create_autocmd("VimEnter", { once = true, callback = remind })
end
