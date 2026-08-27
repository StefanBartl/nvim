---@module 'config.noice'
--- noice.nvim's own opts table (cmdline/lsp/messages/popupmenu/presets/
--- routes/views/notify), assembled here rather than inline in the plugin
--- spec.

local M = {
  cmdline = {},
  lsp = {},
  messages = {},
  popupmenu = {},
  presets = {},
  routes = {},
  views = {},
  notify = {},
  debug = false,
}

M.presets = {
  bottom_search = true, -- use a classic bottom cmdline (also affects / and ?)
  -- command_palette = true,     -- keep disabled unless both cmdline & popupmenu should be stacked
  long_message_to_split = true, -- long messages go to a split
  inc_rename = true,
  lsp_doc_border = false,
}

M.views = {
  split = {
    enter = false,
  },
  cmdline_popup = {
    enter = false,
    border = {
      style = "none",
      padding = { 2, 3 },
    },
    filter_options = {},
    win_options = {
      winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder",
    },
    messages = { reverse = true },
    cmdline_output = { reverse = true },
  },

  -- popupmenu below the cmdline area (classic)
  popupmenu = {
    relative = "editor",
    position = {
      row = (vim.o.lines / 2) + 4,
      col = "50%",
    },
    size = { width = 60, height = 10 },
    border = { style = "none", padding = { 0, 0 } },
    win_options = {
      winhighlight = { Normal = "Normal", FloatBorder = "DiagnosticInfo" },
    },
  },
}

M.lsp = {
  override = {
    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
    ["vim.lsp.util.stylize_markdown"] = true,
    ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
  },
  hover = {
    enabled = true,
    silent = false, -- set to true to not show a message if hover is not available
    view = nil, -- when nil, use defaults from documentation
  },
  signature = {
    enabled = false,
    auto_open = {
      enabled = false,
    },
    view = nil, -- when nil, use defaults from documentation
  },
}

M.cmdline = {
  enabled = true,
  view = "cmdline", -- classic bottom cmdline (not a floating popup)
  format = {
    search_down = { view = "cmdline" },
    search_up = { view = "cmdline" },
  },
}

--- all normal `:echo`, `:echomsg` or system-side messages
M.messages = {
  enabled = true,
  view = "mini",
  view_search = false,
}

-- all notifications triggered via vim.notify()
M.notify = {
  enabled = true, -- ensure vim.notify is captured by Noice
  view = "popup",
  merge = true, -- coalesce repeated messages
}

M.views.mini = {
  timeout = 4000,
  reverse = true,
}

M.views.notify = {
  timeout = 4000,
}

M.routes = {
  {
    filter = { event = "notify" },
    view = "mini",
  },

  {
    view = "mini",
    filter = { event = "msg_showmode" },
  },
  {
    filter = { event = "msg_show", kind = "emsg", find = "E162" },
    view = "mini",
  },

  -- Compact view for several common, uncritical messages.
  {
    filter = {
      event = "msg_show",
      any = {
        --{ find = "; after #%d+" },
        --{ find = "; before #%d+" },
        --{ find = "fewer lines" },
        { find = "written" },
        { find = "Conflict %[%d+" },
        --  { find = "Col %d+" },
      },
    },
    view = "mini",
  },
  -- or
  { filter = { event = "msg_show" }, view = "mini" },

  -- Hide noisy search boundary messages.
  { filter = { event = "msg_show", find = "search hit BOTTOM" }, opts = { skip = true } },
  { filter = { event = "msg_show", find = "search hit TOP" }, opts = { skip = true } },

  -- Hide specific Vim error messages (use correct event/kind for emsg).
  { filter = { event = "msg_show", kind = "emsg", find = "E23" }, opts = { skip = true } },
  { filter = { event = "msg_show", kind = "emsg", find = "E20" }, opts = { skip = true } },
  { filter = { event = "msg_show", kind = "emsg", find = "E37" }, opts = { skip = true } },
  { filter = { event = "msg_show", kind = "emsg", find = "E31" }, opts = { skip = true } },
  { filter = { event = "msg_show", kind = "emsg", find = "E37" }, opts = { skip = true } },
  { filter = { event = "msg_show", kind = "emsg", find = "E351" }, opts = { skip = true } },
  { filter = { event = "msg_show", kind = "emsg", find = "E418" }, opts = { skip = true } },

  -- Hide specific generic texts (no explicit event → matches across sources where applicable).
  { filter = { find = "No signature help" }, opts = { skip = true } },
  {
    filter = { find = "Error detected while processing BufReadPost Autocommands for" },
    opts = { skip = true },
  },

  -- Keep LSP hover minimal (avoid empty popups)
  { filter = { event = "lsp", kind = "hover" }, opts = { skip_empty = true } },

  -- Reduce LSP progress noise
  { filter = { event = "lsp", kind = "progress" }, opts = { skip = true } },

  -- Hide the transient "n/total" search counter in cmdline area.
  { filter = { event = "msg_show", kind = "search_count" }, opts = { skip = true } },

  -- Filter für "Buffer is not modifiable" Warnungen
  {
    filter = {
      event = "notify",
      kind = "warn",
      find = "Buffer is not modifiable",
    },
    opts = { skip = true },
  },
}

return M
