--BUG:

---@module 'usrcmds.mymessages'
--- Capture, persist, copy, and re-display the output of :messages.

---@class MyMessages
---@field run fun(): nil

local M = {}

-- Trim trailing whitespace/newlines for nicer files/clipboard.
---@param s string
---@return string
local function rstrip(s)
  return (s:gsub("%s*$", ""))
end

-- Write string to file, creating parent dir if needed.
---@param path string
---@param content string
---@return boolean, string|nil
local function write_file(path, content)
  local dir = vim.fn.fnamemodify(path, ":h")
  if dir == "" then
    return false, "Invalid directory for path: " .. path
  end
  local ok_mkdir, err_mkdir = pcall(vim.fn.mkdir, dir, "p")
  if not ok_mkdir then
    return false, "Could not create directory: " .. tostring(err_mkdir)
  end
  local file, err = io.open(path, "w")
  if not file then
    return false, "Could not open file: " .. (err or path)
  end
  if content ~= "" and not content:match("\n$") then
    content = content .. "\n"
  end
  file:write(content)
  file:close()
  return true, nil
end

-- Robustly capture :messages via :redir into a global variable.
---@return string
local function capture_messages_redir()
  -- Clear previous capture
  vim.g.__mymessages_capture = nil

  -- Use :redir to capture exactly what :messages prints
  -- No :silent here; we want the full text in the redir buffer.
  vim.api.nvim_exec2([[
    try
      redir => g:__mymessages_capture
      messages
    finally
      redir END
    endtry
  ]], { output = false })

  local s = vim.g.__mymessages_capture
  if type(s) ~= "string" then
    return ""
  end
  return s
end

--- Execute the export: capture, write file, copy to +, then show messages.
---@return nil
function M.run()
  -- 1) Capture
  local messages = rstrip(capture_messages_redir())

  -- 2) Persist
  local log_path = vim.fn.expand("~/temp/mymessages_nvim.log")
  local ok_write, err = write_file(log_path, messages)
  if not ok_write then
    vim.notify("MyMessages: failed to write log: " .. (err or ""), vim.log.levels.ERROR)
  end

  -- 3) Copy to system clipboard register '+'
  -- Hinweis: Unter Linux benötigt man einen Clipboard-Provider (Wayland: wl-clipboard, X11: xclip/xsel).
  local ok_reg, reg_err = pcall(vim.fn.setreg, "+", messages)
  if not ok_reg then
    vim.notify("MyMessages: failed to set + register: " .. tostring(reg_err), vim.log.levels.WARN)
  end

  -- 4) Display again (for the on-screen view)
  vim.cmd("messages")
end

-- :MyMessages user command
vim.api.nvim_create_user_command("MyMessages", function()
  M.run()
end, {
  desc = "Capture :messages, save to file, and copy to clipboard",
})

return M
