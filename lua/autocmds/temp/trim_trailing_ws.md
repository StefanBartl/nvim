Kurzbeschreibung

* Bei Eintritt in den Normal-Mode werden im aktuellen Buffer alle Zeilen von nachgestellten Leerzeichen befreit.
* Schonend implementiert: überspringt nicht-modifizierbare/spezielle Buffer, erhält Cursor-Position, Jumplist und Suchmuster.
* Zusatz: ein User-Command zum manuellen Auslösen.

```lua
---@module 'autocmds.trim_trailing_ws'
--- Remove trailing whitespace when entering Normal mode, with safeguards.

---@class TrimTrailingWsOpts
---@field skip_filetypes string[]|nil  -- optional list of filetypes to skip (e.g., { "markdown", "diff" })

local M = {}

--- Trim trailing whitespace in a given buffer safely.
--- Preserves view (cursor/scroll), jumps and search register.
--- Skips unlisted/special/readonly/unmodifiable buffers.
---@param buf integer
---@param opts TrimTrailingWsOpts|nil
---@return boolean trimmed  -- true if a change was made
function M.trim_buffer(buf, opts)
  opts = opts or {}

  -- Skip if buffer is not loaded
  if not vim.api.nvim_buf_is_loaded(buf) then
    return false
  end

  -- Skip special buffers and non-modifiable/readonly
  local bo = vim.bo[buf]
  if bo.buftype ~= "" or bo.readonly or not bo.modifiable then
    return false
  end

  -- Optional: skip certain filetypes
  if opts.skip_filetypes and vim.tbl_contains(opts.skip_filetypes, bo.filetype) then
    return false
  end

  -- Only proceed if there is any trailing whitespace
  local has_ws = vim.fn.search([[\\s\\+$]], "nw") ~= 0
  if not has_ws then
    return false
  end

  -- Save view and search register
  local view = vim.fn.winsaveview()
  local last_search = vim.fn.getreg("/")
  local last_search_type = vim.fn.getregtype("/")

  -- Run substitution without touching jumps/search history and without messages
  -- %s/\s\+$//e  -> remove trailing whitespace; 'e' suppresses errors if no match
  vim.cmd([[silent keepjumps keeppatterns %s/\s\+$//e]])

  -- Restore search register and view
  vim.fn.setreg("/", last_search, last_search_type)
  vim.fn.winrestview(view)

  return true
end

--- Setup autocmd and a manual user command.
---@param opts TrimTrailingWsOpts|nil
function M.setup(opts)
  opts = opts or {}

  local grp = vim.api.nvim_create_augroup("TrimTrailingWhitespaceOnNormal", { clear = true })

  -- Trigger on entering Normal mode
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = grp,
    pattern = "*:n",
    desc = "Trim trailing whitespace on entering Normal mode",
    callback = function()
      M.trim_buffer(0, opts)
    end,
  })

  -- Manual command to trim on demand
  vim.api.nvim_create_user_command("TrimTrailingWhitespaceNow", function()
    local changed = M.trim_buffer(0, opts)
    if changed then
      vim.notify("Trailing whitespace trimmed", vim.log.levels.INFO, { title = "Trim" })
    else
      vim.notify("No trailing whitespace found", vim.log.levels.INFO, { title = "Trim" })
    end
  end, { desc = "Remove trailing whitespace in current buffer" })
end

return M
```

Einbindung

* Datei ablegen unter `lua/autocmds/trim_trailing_ws.lua`.
* In der Startkonfiguration initialisieren:

```lua
require("autocmds.trim_trailing_ws").setup({
  -- optionally skip some filetypes:
  -- skip_filetypes = { "markdown", "diff" },
})
```

Optionaler Keymap-Komfort

```lua
vim.keymap.set("n", "<leader>tw", "<cmd>TrimTrailingWhitespaceNow<CR>", {
  desc = "[Edit] Trim trailing whitespace now",
  noremap = true,
  silent = true,
})
```

