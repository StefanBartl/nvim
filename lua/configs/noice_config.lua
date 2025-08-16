---@module 'configs.noice_config'
--- Noice.nvim UI configuration tuned for a bottom cmdline and minimal noisy messages.
--- This module moves the cmdline away from the centered popup to the classic bottom position.
--- It also filters messages aggressively so that only important ones (errors/warnings/confirm)
--- are shown in floating windows, while common noise (search count, "written", LSP progress) is skipped.

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

-- Presets:
--  * bottom_search=true: classic bottom cmdline for search
--  * long_message_to_split=true: send long output to a split for readability
--  * lsp_doc_border=false: keep hover/signature help borderless (can be toggled)
M.presets = {
  bottom_search = true,          -- use a classic bottom cmdline (also affects / and ?)
  -- command_palette = true,     -- keep disabled unless both cmdline & popupmenu should be stacked
  long_message_to_split = true,  -- long messages go to a split
  inc_rename = false,
  lsp_doc_border = false,
}

-- Views:
--  * cmdline_popup is left intact, but we won't use it for the primary cmdline anymore.
--  * popupmenu stays as before.
M.views = {
  -- kept for completeness; not used as default for cmdline anymore
  cmdline_popup = {
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
      -- placing near the bottom works well with bottom cmdline
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

-- LSP integration:
--  * Keep Treesitter-backed markdown rendering.
--  * Keep hover/signature help enabled.
M.lsp = {
  override = {
    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
    ["vim.lsp.util.stylize_markdown"] = true,
    ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
  },
  signature = { enabled = false},
  hover = { enabled = false },
}
-- Cmdline:
--  * Force the classic bottom cmdline instead of the centered popup.
--  * Ensure search cmdline (/, ?) also uses the bottom cmdline explicitly.
M.cmdline = {
  ---@diagnostic disable-next-line: assign-type-mismatch
  view = "cmdline", -- classic bottom cmdline (not a floating popup)
  format = {
    -- Make sure search uses the bottom cmdline too (useful even with the preset)
    search_down = { view = "cmdline" },
    search_up = { view = "cmdline" },
  },
}

M.routes = {
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

  -- Hide noisy search boundary messages.
  { filter = { event = "msg_show", find = "search hit BOTTOM" }, opts = { skip = true } },
  { filter = { event = "msg_show", find = "search hit TOP" },    opts = { skip = true } },

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
  { filter = { find = "Error detected while processing BufReadPost Autocommands for" }, opts = { skip = true } },

  -- Keep LSP hover minimal (avoid empty popups).
  { filter = { event = "lsp", kind = "hover" }, opts = { skip_empty = true } },

  -- Reduce LSP progress noise (optional but commonly desired).
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

  -- Conservative global noise filter:
  -- Skip generic msg_show unless it's an error, warning, or confirm dialog.
  -- Comment out if this is too aggressive for a setup.
  -- {
  --   filter = {
  --     event = "msg_show",
  --     ["not"] = {
  --       any = {
  --         { error = true },       -- keep errors
  --         { warning = true },     -- keep warnings
  --         { kind = "confirm" },   -- keep confirm prompts
  --       },
  --     },
  --   },
  --   opts = { skip = true },
  -- },
}

vim.api.nvim_create_user_command("Nall", function()
   require("noice").cmd("All")
end, { desc = "" })


vim.api.nvim_create_user_command("Nerr", function()
   require("noice").cmd("Error")
end, { desc = "" })

return M
