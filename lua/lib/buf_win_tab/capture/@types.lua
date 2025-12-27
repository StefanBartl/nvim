---@module 'lib.buf_win_tab.capture.@types'

---@class BufWinCapture.Tag
---@field buf string|nil  -- Persistent buffer-local tag
---@field win string|nil  -- Ephemeral window-local tag

---@class BufWinCapture.Results
---@field bufs integer[]  -- Newly detected buffers
---@field wins integer[]  -- Newly detected windows

---@class BufWinCapture.Opts
---@field tag BufWinCapture.Tag|nil
---@field timeout integer|nil      -- Timeout in milliseconds
---@field interval integer|nil     -- Polling interval in milliseconds
---@field emit_event boolean|nil   -- Emit User event after capture

return {}
