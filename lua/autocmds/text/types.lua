---@meta
---@module 'autocmds.text.types'

---@class TextAutoCmdsTrimTrailingCfg
---@field enable boolean                 # Enable trimming of trailing whitespace on save.
---@field pattern string|string[]|nil    # Autocmd pattern(s); defaults to "*".
---@field ignore_filetypes string[]|nil  # Filetypes to skip (e.g., {"markdown","diff"}).
---@field ignore_buftypes string[]|nil   # Buftypes to skip (e.g., {"nofile","prompt"}).
---@field only_modifiable boolean|nil    # Skip if buffer is not modifiable; default true.
---@field only_normal_bufs boolean|nil   # Skip if buftype is not empty; default true.

---@class TextAutoCmdsTrimBlankCfg
---@field enable boolean                 # Enable cleanup of whitespace-only lines on save.
---@field pattern string|string[]|nil    # Autocmd pattern(s); defaults to "*".
---@field preserve_cursor boolean|nil    # Restore exact cursor after cleanup; default true.
---@field ignore_filetypes string[]|nil  # Filetypes to skip.
---@field ignore_buftypes string[]|nil   # Buftypes to skip.
---@field only_modifiable boolean|nil    # Skip if buffer is not modifiable; default true.
---@field only_normal_bufs boolean|nil   # Skip if buftype is not empty; default true.

---@class TextAutoCmdsLastLocCfg
---@field enable boolean                 # Restore last cursor position on BufReadPost.
---@field pattern string|string[]|nil    # Autocmd pattern(s); defaults to "*".
---@field exclude string[]|nil           # Filetypes to exclude (e.g., {"commit","gitrebase","xxd"}).
---@field min_line integer|nil           # Minimum target line to consider; default 1.

---@class TextAutoCmdsCfg
---@field trim_trailing TextAutoCmdsTrimTrailingCfg
---@field trim_blank TextAutoCmdsTrimBlankCfg
---@field last_loc TextAutoCmdsLastLocCfg
