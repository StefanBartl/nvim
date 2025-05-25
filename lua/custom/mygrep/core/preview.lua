---@module 'custom.mygrep.core.preview'
---@class PreviewCountManager
---@brief Shows result count for a given query using ripgrep
---@description
--- This module executes a safe ripgrep call in the background to count matches
--- for a given search term. The result is shown as a floating notification.
--- It is used to preview the potential effectiveness of a search term without
--- launching a full grep operation. This is used in the `<C-h>` mapping inside
--- the memory picker.
---
---@field show fun(query: string): nil Triggers a match count and displays it as a floating message

local M = {}

--- Shows a match count preview using `rg --count` for a given query.
---@param query string The search term to count matches for
---@return nil
function M.show(query)
  if type(query) ~= "string" or query == "" then
    vim.notify("[preview] Invalid query input", vim.log.levels.WARN)
    return
  end

  -- Escape safely for shell
  local cmd = { "rg", "--count", "--no-heading", "--color=never", query }

  local function on_stdout(_, data, _)
    if not data or vim.tbl_isempty(data) then
      vim.notify("No matches found for: " .. query, vim.log.levels.INFO)
      return
    end

    -- Sum all counts
    local total = 0
    for _, line in ipairs(data) do
      local num = tonumber(line)
      if num then
        total = total + num
      end
    end

    vim.notify(("Found %d matches for: \"%s\""):format(total, query), vim.log.levels.INFO)
  end

  local function on_stderr(_, data, _)
    if data and #data > 0 then
      vim.notify("[preview] ripgrep error: " .. table.concat(data, " "), vim.log.levels.ERROR)
    end
  end

  local ok = pcall(function()
    vim.fn.jobstart(cmd, {
      stdout_buffered = true,
      stderr_buffered = true,
      on_stdout = on_stdout,
      on_stderr = on_stderr,
    })
  end)

  if not ok then
    vim.notify("[preview] Failed to start ripgrep process", vim.log.levels.ERROR)
  end
end

return M