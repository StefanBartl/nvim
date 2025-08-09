---@module 'configs.noice_config'

---@class NoiceConfig
---@field [string] table
---@field debug boolean

---@type NoiceConfig
local M = {
  cmdline = {},
  lsp = {},
  messages = {},
  popupmenu = {},
  presets = {},
  routes = {},
  views = {},
  debug = false,
}

M.presets = {
  --bottom_search = true, -- use a classic bottom cmdline for search
  --command_palette = true, -- position the cmdline and popupmenu together
  long_message_to_split = true, -- long messages will be sent to a split
  inc_rename = false,           -- enables an input dialog for inc-rename.nvim
  lsp_doc_border = false,       -- add a border to hover docs and signature help
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

M.lsp = {
  -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
  override = {
    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
    ["vim.lsp.util.stylize_markdown"] = true,
    ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
  },
  signature = {
    enabled = true,
  },
  hover = {
    enabled = true,
  },
}

M.routes = {
  {
    filter = {
      event = "lsp",
      kind = "hover",
    },
    opts = {
      skip_empty = true,
    },
  },
}

return M
