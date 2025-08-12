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
  signature = { enabled = true },
  hover = { enabled = true },
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

-- Routes:
--  Strategy: Keep only "very important" messages in floating views.
--  We skip most generic ui-messages while preserving errors, warnings, and confirm prompts.
M.routes = {
  -- 1) Skip all generic msg_show kinds except errors, warnings, and confirm dialogs.
  --    This aggressively reduces noise from "echo", "written", "search_count", etc.
  {
    filter = {
      event = "msg_show",
      -- keep only when it's NOT (error OR warning OR confirm)
      ["not"] = {
        any = {
          { error = true },        -- keep errors
          { warning = true },      -- keep warnings
          { kind = "confirm" },    -- keep :confirm prompts and similar
        },
      },
    },
    opts = { skip = true },
  },

  -- 2) Hide search virtual text like "n/total" counters
  {
    filter = { event = "msg_show", kind = "search_count" },
    opts = { skip = true },
  },

  -- 3) Hide "written" messages after :w to reduce noise
  {
    filter = { event = "msg_show", kind = "", find = "written" },
    opts = { skip = true },
  },

  -- 4) Hide LSP progress notifications (they tend to be chatty)
  {
    filter = { event = "lsp", kind = "progress" },
    opts = { skip = true },
  },

  -- 5) Example: keep LSP hovers minimal (skip empty)
  {
    filter = { event = "lsp", kind = "hover" },
    opts = { skip_empty = true },
  },
}

return M
