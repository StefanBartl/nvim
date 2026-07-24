---@module 'config.ai.anthropic'
---
--- Anthropic provider configuration for Avante.

---@type AvanteAnthropicConfig
local M = {

  ----------------------------------------------------------------------------
  -- Provider Selection
  ----------------------------------------------------------------------------
  provider = "claude",

  ----------------------------------------------------------------------------
  -- Provider Definitions
  ----------------------------------------------------------------------------
  providers = {
    claude = {
      endpoint = "https://api.anthropic.com",
      model = "claude-sonnet-4",
      timeout = 30000,

      extra_request_body = {
        temperature = 0,
        max_tokens = 8192,
      },
    },
  },

  ----------------------------------------------------------------------------
  -- Behaviour
  ----------------------------------------------------------------------------
  behaviour = {
    auto_suggestions = false,
    auto_set_highlight_group = true,
    auto_set_keymaps = false,
    auto_apply_diff_after_generation = false,
    support_paste_from_clipboard = true,
  },

  ----------------------------------------------------------------------------
  -- Windows
  ----------------------------------------------------------------------------
  windows = {
    position = "right",
    width = 40,
    wrap = true,
    sidebar_header = {
      enabled = true,
      rounded = true,
    },
  },

  ----------------------------------------------------------------------------
  -- Diff
  ----------------------------------------------------------------------------
  diff = {
    autojump = true,
    list_opener = "copen",
  },

  ----------------------------------------------------------------------------
  -- Key Mappings
  ----------------------------------------------------------------------------
  mappings = {
    ask = "<leader>aa",
    edit = "<leader>ae",
    refresh = "<leader>ar",
    focus = "<leader>af",
    stop = "<leader>as",
  },
}

return M
