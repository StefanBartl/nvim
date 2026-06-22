---@module 'plugins.ai.anthropic.@types'

-- NEU: Typ für die API-spezifischen Parameter
---@class AvanteRequestBody
---@field temperature number
---@field max_tokens integer

---@class AvanteAnthropicProvider
---@field endpoint string
---@field model string
---@field timeout integer
---@field extra_request_body AvanteRequestBody -- HIER HINZUGESFÜGT

---@class AvanteBehaviourConfig
---@field auto_suggestions boolean
---@field auto_set_highlight_group boolean
---@field auto_set_keymaps boolean
---@field auto_apply_diff_after_generation boolean
---@field support_paste_from_clipboard boolean

---@class AvanteSidebarHeaderConfig
---@field enabled boolean
---@field rounded boolean

---@class AvanteWindowsConfig
---@field position '"left"'|'"right"'
---@field width integer
---@field wrap boolean
---@field sidebar_header AvanteSidebarHeaderConfig

---@class AvanteDiffConfig
---@field autojump boolean
---@field list_opener string

---@class AvanteMappingsConfig
---@field ask string
---@field edit string
---@field refresh string
---@field focus string
---@field stop string

---@class AvanteAnthropicConfig
---@field provider string
---@field providers table<string, AvanteAnthropicProvider>
---@field behaviour AvanteBehaviourConfig
---@field windows AvanteWindowsConfig
---@field diff AvanteDiffConfig
---@field mappings AvanteMappingsConfig

return {}
