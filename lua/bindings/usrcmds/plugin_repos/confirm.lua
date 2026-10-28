---@module 'bindings.usrcmds.plugin_repos.confirm'
---@brief Confirm dialog for `:MyPlugins`' and `:MyNative`'s destructive confirmations.
---@description
--- `lib.nvim.ui.dialog.yesno`: the themed button dialog every plugin of the family uses ("No" is the first and
--- focused button, `n`/`y` are keys), a native question when no float can open.
---
--- Async by nature: `cb(accepted)` is called exactly once, never synchronously before this function returns.
--- Callers that used to write `if not confirm.yesno(msg) then return end` need the rest of their logic moved
--- into `cb`.

local M = {}

---@param msg string
---@param yes_label string|nil e.g. "delete" -- shown as "Yes, delete"
---@param cb fun(accepted: boolean)
function M.yesno(msg, yes_label, cb)
	require("lib.nvim.ui.dialog").yesno(msg, yes_label, cb)
end

return M
