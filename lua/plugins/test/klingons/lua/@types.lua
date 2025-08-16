---@class KlingonDiagHookCfg
---@field debounce_ms integer

---@class KlingonFloatOpts
---@field border       string|table  -- Any valid nvim border value
---@field pad_left     integer
---@field pad_right    integer
---@field pad_top      integer
---@field pad_bottom   integer
---@field zindex       integer
---@field timeout_ms   integer       -- Auto-close timeout; 0 to disable
---@field winblend     integer       -- 0..100, transparency
---@field highlight    string        -- Window highlight group
---@field title        string|nil    -- Optional window title
---@field title_pos    "left"|"center"|"right"|nil
---@field col integer|nil        -- optional absolute column override
---@field row integer|nil        -- optional absolute row override
---@field close_on_any_key boolean|nil -- default true: close even when not focused
---@field focus_on_open boolean|nil    -- default false: set true to focus the float
---@field max_width integer|nil        -- optional clamp
---@field max_height integer|nil       -- optional clamp

---@class KlingonNotifyDispatch
---@field level integer
---@field title string
---@field message string



---@class KlingonPhrases
---@field success string  -- Success shout (e.g. "Qapla'!")
---@field error   string  -- Error shout (e.g. "Qagh!")
---@field warn    string  -- Warning shout (e.g. "yIqIm!")
---@field info    string  -- Informational shout (e.g. "De'!")

---@class KlingonIcons
---@field success string
---@field error   string
---@field warn    string
---@field info    string

---@class KlingonPhrasePack
---@field phrases KlingonPhrases
---@field icons   KlingonIcons
