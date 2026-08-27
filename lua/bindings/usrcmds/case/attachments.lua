---@module 'bindings.usrcmds.case.attachments'
--- `:Case new`'s attachment-ingestion step (ROADMAP.md): a native Windows
--- file-open dialog rooted at Downloads, multi-select, chosen files MOVED
--- (not copied) into the new case's `assets/initial/`. Windows-only — there
--- is no cross-platform equivalent of `System.Windows.Forms.OpenFileDialog`
--- in this codebase, and every caller here degrades to "do nothing" rather
--- than erroring on another OS.

local config = require("bindings.usrcmds.case.config")
local mkdirp = require("lib.nvim.fs.mkdirp")
local env = require("lib.nvim.system.env")

local M = {}

---@param path string
---@return string  `path` with every `'` doubled, safe to drop into a
--- PowerShell single-quoted string literal.
local function ps_quote(path)
  return (path:gsub("'", "''"))
end

--- Ask Windows for a batch of files via a native `OpenFileDialog`
--- (Multiselect, initial directory = the user's Downloads folder) and hand
--- the chosen absolute paths to `on_done`. Always calls `on_done` exactly
--- once — `{}` on cancel, on a non-Windows host, or if `powershell.exe`
--- itself can't be spawned; this never errors the caller.
---
--- `powershell.exe` (Windows PowerShell), not `pwsh` (PowerShell Core):
--- the former defaults to an STA thread, which `OpenFileDialog` requires,
--- the latter does not and would need an extra `-sta` flag most installs
--- don't carry — see `lib.nvim.system.env`'s `is_pwsh` doc comment for why
--- the two are tracked separately.
---@param on_done fun(paths: string[])
function M.pick_from_downloads(on_done)
  if not env.get().is_windows then
    on_done({})
    return
  end

  local downloads = env.get().home .. "/Downloads"
  local script = table.concat({
    "Add-Type -AssemblyName System.Windows.Forms",
    "$dlg = New-Object System.Windows.Forms.OpenFileDialog",
    ("$dlg.InitialDirectory = '%s'"):format(ps_quote(downloads)),
    "$dlg.Multiselect = $true",
    "$dlg.Filter = 'All files (*.*)|*.*'",
    "$dlg.Title = 'Select attachments to move into the case'",
    "if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {",
    "  $dlg.FileNames | ForEach-Object { Write-Output $_ }",
    "}",
  }, "\n")

  local spawn_capture = require("lib.nvim.cross.uv.spawn_capture")
  spawn_capture({
    "powershell.exe",
    "-NoProfile",
    "-NonInteractive",
    "-WindowStyle",
    "Hidden",
    "-Command",
    script,
  }, {}, function(result)
    if not result.ok or not result.stdout or vim.trim(result.stdout) == "" then
      on_done({})
      return
    end
    local paths = {}
    for _, line in ipairs(vim.split(result.stdout, "\r?\n", { trimempty = true })) do
      if vim.trim(line) ~= "" then
        paths[#paths + 1] = vim.trim(line)
      end
    end
    on_done(paths)
  end)
end

---@class Lib.Case.AttachmentsIngestResult
---@field ok integer  How many files were moved successfully.
---@field errors string[]  One entry per failed move, `"<path>: <err>"`.

--- Move (never copy) every path in `paths` into `<entry.dir>/<assets_dirname>/initial/`
--- — the batch a customer sent with the ticket, kept apart from anything
--- placed into `assets/` afterward by hand (`:Case copy`, `:Case ki import`).
--- Uses the same Windows-lock-retry-safe rename primitive `do_move`/
--- `normalize.lua` already do their moves through.
---@param entry Lib.Case.RegistryEntry
---@param paths string[]
---@return Lib.Case.AttachmentsIngestResult
function M.ingest(entry, paths)
  local dest_dir = entry.dir .. "/" .. config.assets_dirname .. "/initial"
  local result = { ok = 0, errors = {} }
  if #paths == 0 then
    return result
  end
  mkdirp(dest_dir)
  local mutate = require("lib.nvim.cross.fs.mutate")
  for _, src in ipairs(paths) do
    local dest = dest_dir .. "/" .. vim.fn.fnamemodify(src, ":t")
    local ok, err = mutate.rename_file(src, dest)
    if ok then
      result.ok = result.ok + 1
    else
      result.errors[#result.errors + 1] = ("%s: %s"):format(src, tostring(err))
    end
  end
  return result
end

return M
