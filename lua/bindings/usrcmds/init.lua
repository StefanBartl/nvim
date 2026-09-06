---@module 'bindings.usrcmds'

local usercmd = require("lib.nvim.bindings.usercmd")
local notify = require("lib.nvim.notify").create("[bindings.usrcmds]")

-- casedesk is a plugin now (StefanBartl/casedesk.nvim, spec in
-- plugins/personal/init.lua, local checkout under $REPOS_DIR). The tree under
-- usrcmds/case/ is frozen and kept only as a fallback: uncomment the line
-- below and comment out the spec entry to go back. Exactly one of the two may
-- ever be active -- both would register :Case twice, and which code ran would
-- be anyone's guess. See docs/ROADMAP/casedesk/PLUGIN.md section 3.8.
-- require("bindings.usrcmds.case").enable()
require("bindings.usrcmds.bindings_explorer").enable()
require("bindings.usrcmds.context_open").enable()
require("bindings.usrcmds.telemetry_nvim_config").enable()
require("bindings.usrcmds.autocmd_docs").enable()

usercmd.create("CopyLocation", function()
  -- Absolute path of the current file
  local path = vim.fn.expand("%:p")

  -- The buffer has no file on disk yet
  if path == "" then
    notify.warn("No file loaded / no path available")
    return
  end

  -- Cursor position (line is 1-based, column is 0-based)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1]
  local col = cursor[2] + 1 -- make 1-based

  -- Format as path:line:col
  local result = string.format("%s:%d:%d", path, line, col)

  -- Copy into the "+ register (system clipboard)
  vim.fn.setreg("+", result)

  notify.info("Copied: " .. result)
end, {
  desc = "Copy the absolute path, line and column to the clipboard",
})

-- `:BindingsPath` used to live here. It copied
-- `<stdpath('config')>/docs/NOTES/BINDINGS` -- a directory that has never
-- existed. The corpus has two roots, `docs/NOTES/PersonelPlugins/BINDINGS`
-- and `docs/NOTES/ExternPlugins/Bindings`, and `:Bindings path
-- [personal|extern]` copies them, knows both, and is where the explorer's
-- own module doc has pointed all along. The command carried a `TEMP` marker
-- from the day it was written; telemetry says the keymap below is pressed
-- often, so the key stays and only its target is corrected.
--
-- lib.nvim.bindings.keymap directly, like everywhere else. There used to be a
-- `vim.g.__map_helper` handle to reach for here; it is gone, and it never
-- worked -- `vim.g` strips a table's metatable on the way through, so the
-- callable module came back as a plain table and the first `map(...)` raised
-- "attempt to call a table value".
require("lib.nvim.bindings.keymap")(
  "n",
  "<leader>BI",
  "<cmd>Bindings path<CR>",
  nil,
  "Copy BINDINGS roots to the clipboard"
)

--- CDX: works, but a neo-tree/nvim-tree/netrw reload needs to be triggered
--- for it to pick up the new cwd.
usercmd.create("CwdHere", function()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname ~= "" then
    local dir = vim.fn.fnamemodify(bufname, ":p:h")
    vim.cmd("lcd " .. vim.fn.fnameescape(dir))
  end
end, { force = true })

usercmd.create("PowershellProfile", function()
  if vim.fn.executable("powershell") ~= 1 then
    notify.error("Error: powershell is not available on this system.")
    return
  end
  -- argv array instead of io.popen with an embedded shell string
  local res = vim
    .system({ "powershell", "-NoProfile", "-Command", "[Console]::Write($PROFILE)" }, { text = true })
    :wait()
  local profile_path = res.code == 0 and res.stdout or nil

  if profile_path and profile_path ~= "" then
    vim.cmd("edit " .. vim.fn.fnameescape(profile_path))
    return
  end
  notify.error("Error: could not determine the PowerShell profile path.")
end, { desc = "Open the current PowerShell profile", force = true })
