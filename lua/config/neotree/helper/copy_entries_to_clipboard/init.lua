---@module 'config.neotree.helper.copy_entries_to_clipboard'
-- Copy a sequence of entries to the system clipboard with optional transformation.
--
-- Options:
--   - relative_to_cwd (boolean): if true, convert each entry to path relative to cwd before normalizing.
--   - preview_limit (number): how many items to include in the notification preview (default: 20)

local normalize_os_sep = require("lib.normalize.os_sep")

return function (entries, opts)
  opts = opts or {}
  local relative = opts.relative_to_cwd or false
  local N = opts.preview_limit and math.max(1, tonumber(opts.preview_limit) or 20) or 20

  -- transform and normalize entries in-place
  for i = 1, #entries do
    local p = entries[i]
    if relative and p ~= "" then
      p = vim.fn.fnamemodify(p, ":~:.") -- convert to relative-ish path (home + relative)
    end
    entries[i] = normalize_os_sep(p)
  end

  -- set clipboard (system + unnamed) with newline-separated list
  vim.fn.setreg("+", table.concat(entries, "\n"), "c")
  vim.fn.setreg('"', table.concat(entries, "\n"), "c")

  -- build preview for notification
  local preview = {}
  for i = 1, math.min(#entries, N) do
    table.insert(preview, entries[i])
  end
  local more = ""
  if #entries > N then
    more = ("\n... and %d more files"):format(#entries - N)
  end

  -- choose message depending on relative flag
  local msg
  if relative then
    msg = ("Copied %d files to clipboard (relative to cwd):\n%s%s"):format(#entries, table.concat(preview, "\n"), more)
  else
    msg = ("Copied %d files to clipboard:\n%s%s"):format(#entries, table.concat(preview, "\n"), more)
  end

  vim.notify(msg, vim.log.levels.INFO)
end

