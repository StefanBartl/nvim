---@module 'usrcmds.mymessages'

---@class MyMessages
---@brief Custom handler for duplicating the :messages output
---@description
--- This module defines a custom Ex command `:MyMessages` that performs the following:
--- 1. Calls the built-in `:messages` command and captures its output.
--- 2. Writes the captured messages to a file at `~/temp/nvimmessages.log`, overwriting previous content.
--- 3. Copies the message output to the system clipboard register `+`.
--- 4. Then invokes `:messages` to display the output again normally
---@field run fun(): nil
local M = {}

--- Executes the custom message export logic.
--- This includes capturing Neovim's `:messages`, saving them to a file, and copying to clipboard.
---@return nil
function M.run()
  local res = vim.api.nvim_exec2("silent messages", { output = true })
  local messages = res.output or ""
  local log_path = vim.fn.expand("~/temp/mymessages_nvim.log")
  local ok, err = pcall(function()
    -- Ensure the parent directory exists, create it if necessary (mode "p" means parents)
    vim.fn.mkdir(vim.fn.fnamemodify(log_path, ":h"), "p")

    local file = io.open(log_path, "w")
    if file then
      file:write(messages)
      file:close()
    else
      error("Could not open file: " .. log_path)
    end
  end)

  if not ok then
    vim.notify("Failed to write messages log: " .. err, vim.log.levels.ERROR)
  end

  -- Copy the captured messages to the system clipboard (register "+")
  vim.fn.setreg("+", messages)
  vim.cmd("messages")
end

-- Define a custom user command `:MyMessages` that calls M.run()
vim.api.nvim_create_user_command("MyMessages", function()
  M.run()
end, {
  desc = "Print :messages, save to file, and copy to clipboard",
})

return M
