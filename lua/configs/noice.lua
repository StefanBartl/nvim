---@module 'configs.noice'

---@class NoiceConfig
---@field lsp table
---@field presets table
---@field cmdline table
---@field views table
---@field messages table
---@field popupmenu table

---@type NoiceConfig
local M = {
  lsp = {},
  presets = {},
  cmdline = {},
  views = {},
  messages = {},
  popupmenu = {},
}


M.lsp = {
  override = {
    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
    ["vim.lsp.util.stylize_markdown"] = true,
    ["cmp.entry.get_documentation"] = true,
  },
}

M.presets = {
  bottom_search = false,
  command_palette = false,
  long_message_to_split = true,
  inc_rename = false,
  lsp_doc_border = false,
}

M.cmdline = {
  enabled = true,
  view = "cmdline_popup",
}

M.views = {
  cmdline_popup = {
    position = {
      row = vim.o.lines - vim.o.cmdheight - 2,
      col = "0%",
    },
    size = {
      width = vim.o.columns - 4,
      height = "auto",
    },
    border = {
      style = "single", -- none | single | rounded | double | solid | shadow
    },
  },
}

M.messages = {
  enabled = true,
  view = "notify",
}

M.popupmenu = {
  enabled = true,
  backend = "nui",
}

return M
