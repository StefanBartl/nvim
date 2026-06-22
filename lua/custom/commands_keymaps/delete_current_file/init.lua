---@module 'custom.commands_keymaps.delete_current_file'
---Delete current buffer and remove the file from disk
---
--- Normal workflow without user command or mapping:
---
--- 1. Delete the file on disk:
---    :!rm %
---
--- 2. Close the buffer:
---    :bd
---
--- or combined in one Ex command:
---    :!rm % | bd
---
--- The user command and keymap below provide a safe, reusable abstraction
--- with validation and clear error handling.
---
--- Supported platforms:
--- - Linux / macOS: uses `rm`
--- - Windows: uses `del` via cmd.exe

--FIX: insert enable() und attach()

local notify = require("lib.nvim.notify").create("[custom.commands_keymaps.delete_current_file]")

local api = vim.api
local fn = vim.fn

---Delete the current buffer's file from disk and close the buffer
---@return nil
local function delete_current_file()
  local bufnr = api.nvim_get_current_buf()

  -- Get absolute file path
  local filepath = api.nvim_buf_get_name(bufnr)

  -- Validate buffer state
  if filepath == "" then
    notify.warn("Current buffer has no associated file.")
    return
  end

  -- Check file existence
  if fn.filereadable(filepath) ~= 1 then
    notify.error("File does not exist on disk: " .. filepath)
    return
  end

  -- Delete file depending on platform
  if fn.has("win32") == 1 then
    -- Windows requires cmd.exe for file deletion
    fn.system({ "cmd.exe", "/C", "del", "/F", "/Q", filepath })
  else
    -- POSIX systems
    fn.system({ "rm", "-f", filepath })
  end

  -- Close buffer without forcing
  api.nvim_buf_delete(bufnr, { force = false })

  notify.info("Deleted file and closed buffer:\n" .. filepath)
end

-- User command: :DeleteCurrentFile
api.nvim_create_user_command(
  "DeleteCurrentFile",
  delete_current_file,
  {
    desc = "Delete current buffer and remove file from disk",
  }
)

-- Keymap: <leader>fd
-- Deletes the current file and closes the buffer
vim.keymap.set(
  "n",
  "<leader>dcf",
  delete_current_file,
  {
    desc = "[custom.commands&keymaps] Delete current file and buffer",
    silent = true,
  }
)
