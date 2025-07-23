---@module 'configs.noice'

---@class NoiceConfig
---@field [string] table

---@type NoiceConfig
local M = {
  cmdline = {},
  lsp = {},
  messages = {},
  popupmenu = {},
  presets = {},
  routes = {},
  views = {},
}

M.presets = {
  long_message_to_split = true,
  lsp_doc_border = false,
}

M.views = {
  cmdline_popup = {
    border = {
      style = "none",
      padding = { 2, 3 },
    },
    filter_options = {},
    win_options = {
      winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder",
    },
    messages = {
      reverse = true,
    },
    cmdline_output = {
      reverse = true,
    }
  },
  popupmenu = {
      relative = "editor",
      position = {
        row = (vim.o.lines / 2) + 4,
        col = "50%",
      },
      size = {
        width = 60,
        height = 10,
      },
      border = {
        style = "none",
        padding = { 0, 0 },
      },
      win_options = {
        winhighlight = { Normal = "Normal", FloatBorder = "DiagnosticInfo" },
      },
    },
}

return M
