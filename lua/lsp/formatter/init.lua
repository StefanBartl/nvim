---@module 'lsp.formatter.init'
---@class FormatterOptions
---@field format_on_save boolean
---@field timeout_ms integer
---@class FormatterApi
---@field format fun(bufnr?:integer):boolean

local M = {}

---@param opts FormatterOptions
---@return FormatterApi
function M.build(opts)
  opts = opts or { format_on_save = true, timeout_ms = 1500 }
  local ok_conform, conform = pcall(require, "conform")
  local util_ok, util = pcall(require, "lsp.core.util")

  ---@param bufnr integer?
  ---@return boolean
  local function can_lsp_format(bufnr)
    if not util_ok or type(util.any_client_can_format) ~= "function" then
      return false
    end
    return util.any_client_can_format(bufnr or 0)
  end

  ---@param bufnr integer?
  ---@return boolean
  local function format(bufnr)
    bufnr = bufnr or 0
    if ok_conform and type(conform.format) == "function" then
      local ok_run = pcall(conform.format, {
        bufnr = bufnr,
        timeout_ms = opts.timeout_ms,
        lsp_fallback = can_lsp_format(bufnr),
      })
      if ok_run then return true end
    end
    if can_lsp_format(bufnr) then
      return pcall(vim.lsp.buf.format, { bufnr = bufnr, timeout_ms = opts.timeout_ms }) == true
    end
    return false
  end

  if opts.format_on_save then
    local grp = vim.api.nvim_create_augroup("LspFormatOnSave", { clear = true })
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = grp,
      callback = function(ev)
        if vim.bo[ev.buf].buftype ~= "" then return end
        format(ev.buf)
      end,
    })
  end

  return { format = format }
end

return M
