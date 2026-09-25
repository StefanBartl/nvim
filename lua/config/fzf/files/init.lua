---@module 'config.fzf.files'
---File picker (fd) configuration and entry formatting

local path_shorten = require("lib.nvim.fs.path_shorten")

local M = {}

---fd options for the files picker. The exclude list itself comes from
---pickers.nvim (`find.ignore_list`, patched onto fzf-lua's `files.fd_opts`).
---@return string
local function build_fd_opts()
  return "--type f --hidden"
end

---@return integer
local function adapt_max_len()
  return math.max(20, math.floor((vim.o.columns or 80) * 0.6))
end

---PDF preview for the files picker, if pdfport.nvim is on the runtime path
---(pcall-guarded: this config's personal plugins are optional/mode-switched,
---see plugins.personal.source). Requiring it here does pull pdfport.nvim in
---as soon as this fzf-lua files picker opens, same trade-off pdfport's own
---integrations doc accepts — the point of this hook is a preview on every
---files run, not a lazy one.
---@return fun(fzf_cb: fun(text: string|nil), entry: table)|nil
local function pdf_preview()
  local ok, pdfport_fzf = pcall(require, "pdfport.integrations.fzf")
  if not ok then
    return nil
  end
  return pdfport_fzf.preview_fn({ max_pages = 3 })
end

---@return table
function M.get()
  return {
    fd_opts = build_fd_opts(),
    preview = pdf_preview(),
    entry_maker = function(entry)
      local max_len = adapt_max_len()
      entry.path = path_shorten(entry.path or entry, max_len)
      return entry
    end,
  }
end

return M
