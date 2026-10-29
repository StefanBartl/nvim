---@module 'workstation-setup-reminder'
---@brief One-off reminder: run `setup-claude-code.ps1` once on the workstation.
---@description
--- Loaded from `after/plugin/zz-workstation-setup-reminder.lua`. Does nothing unless this machine is the workstation
--- (`lua/machine.lua`). On the workstation it opens a terminal split in `docs/NOTES/CDX` with the command typed in but
--- not run: press Enter. When the terminal closes it offers to delete itself; `:WorkstationSetupDone` deletes it any
--- time. Until it is deleted it reminds again on every start. Delete this file and the loader when it is no longer wanted.

local ok, machine = pcall(require, "machine")
if not ok or not machine.is("workstation") then
  return
end

local config = vim.fn.stdpath("config")
local cdx = config .. "/docs/NOTES/CDX"
local command = "pwsh -File ./setup-claude-code.ps1"
local files = {
  config .. "/workstation-setup-reminder.lua",
  config .. "/after/plugin/zz-workstation-setup-reminder.lua",
}

local function remove_self()
  for _, file in ipairs(files) do
    vim.fn.delete(file)
  end
  pcall(vim.api.nvim_del_user_command, "WorkstationSetupDone")
  vim.notify("[setup] Reminder deleted, it will not come back.", vim.log.levels.INFO)
end

vim.api.nvim_create_user_command("WorkstationSetupDone", remove_self, {
  desc = "Delete the one-off workstation setup reminder",
})

local function offer_delete()
  vim.ui.select({ "Setup is done, delete the reminder", "Remind me again next time" }, {
    prompt = "Workstation setup reminder",
  }, function(_, index)
    if index == 1 then
      remove_self()
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
      vim.schedule(offer_delete)
    end,
  })
  -- The shell needs a moment before the typed text lands on its prompt.
  vim.defer_fn(function()
    if job and vim.api.nvim_buf_is_valid(buf) and pcall(vim.fn.chansend, job, command) then
      vim.cmd("startinsert")
    end
  end, 600)
end

local function remind()
  vim.defer_fn(function()
    -- Headless runs (tools, tests, hooks that start nvim with this config) must not open a shell.
    if #vim.api.nvim_list_uis() == 0 then
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
