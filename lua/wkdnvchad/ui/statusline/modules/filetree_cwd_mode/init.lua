---@module 'wkdnvchad.ui.statusline.modules.filetree_cwd_mode'
--- filetree.nvim's cwd_mode badge (PROJECT/PKG/LOCK/MANUAL/TREE), read via
--- its external-statusline API rather than filetree's own tree-window badge.
---
--- Requires `features.cwd_mode.indicator.enabled = false` in the filetree
--- setup() call (see lua/plugins/personal/init.lua) — otherwise the mode
--- shows twice: once here, once bottom-left in the tree window.
---
--- No manual refresh wiring needed: cwd_mode fires a scheduled `:redrawstatus`
--- itself whenever the badge text/highlight would change (see its
--- `User FiletreeCwdModeChanged` autocmd), and NvChad's statusline re-evaluates
--- this function on every redraw regardless.

return function()
  local ok, ft = pcall(require, "filetree")
  if not ok then return "" end

  local cwd_mode = ft.feature("cwd_mode")
  if not cwd_mode then return "" end

  local badge = cwd_mode.badge()
  if badge.text == "" then return "" end

  -- badge.hl is a real, always-defined Neovim group (DiagnosticWarn/Info/…),
  -- picked per mode by cwd_mode itself — no local St_* group to keep in sync.
  -- Falls back to "Comment" only if a custom cwd_mode.indicator.hl table omits
  -- an entry for the active mode.
  return " %#" .. (badge.hl or "Comment") .. "#" .. badge.text .. " "
end
