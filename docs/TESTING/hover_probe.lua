-- docs/TESTING/hover_probe.lua — measure where a hover image is actually drawn.
--
--   :luafile %                (with this file open)
--   :luafile docs/TESTING/hover_probe.lua
--
-- Then hover an image (rest the cursor on an image link or a bare image path)
-- and run `:messages`. Every draw prints one block: the float's reported
-- geometry, what images.anchor computed from it, and the cell coordinates
-- that went to the terminal.
--
-- Nothing is stubbed — the image still draws normally. This only observes.
-- Load it again to re-arm after a `:source $MYVIMRC`; loading twice does not
-- stack wrappers (the original is remembered on the module).

local ok_term, term = pcall(require, "images.terminal")
if not ok_term then
  vim.notify("[hover_probe] images.nvim not loaded — open an image buffer first", vim.log.levels.ERROR)
  return
end

-- Idempotent: keep the untouched function on the module so a second load
-- wraps the original rather than the previous wrapper.
term.__probe_original_draw = term.__probe_original_draw or term.draw

---@type integer|nil
local watched_win = nil

-- The float is opened by lib.nvim.hover.float; catching WinNew is the least
-- invasive way to learn its handle without patching that module.
vim.api.nvim_create_autocmd("WinNew", {
  group = vim.api.nvim_create_augroup("HoverProbeWin", { clear = true }),
  callback = function()
    vim.schedule(function()
      local w = vim.api.nvim_get_current_win()
      local ok, cfg = pcall(vim.api.nvim_win_get_config, w)
      if ok and cfg.relative and cfg.relative ~= "" then watched_win = w end
    end)
  end,
})

term.draw = function(file, row, col, cols, rows)
  local lines = {
    "── hover_probe ─────────────────────────────",
    ("screen        : columns=%d lines=%d"):format(vim.o.columns, vim.o.lines),
    ("SENT to term  : row=%s col=%s cols=%s rows=%s"):format(row, col, cols, rows),
    ("file          : %s"):format(vim.fn.fnamemodify(tostring(file), ":t")),
  }

  -- Report every floating window that currently exists: the hover's own, and
  -- any other float that might be sitting where the image landed.
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    local ok_cfg, wcfg = pcall(vim.api.nvim_win_get_config, w)
    if ok_cfg and wcfg.relative and wcfg.relative ~= "" then
      local pos = vim.api.nvim_win_get_position(w)
      local width, height = vim.api.nvim_win_get_width(w), vim.api.nvim_win_get_height(w)
      local border = (type(wcfg.border) == "table") and 1 or 0
      local extent_c, extent_r = width + border * 2, height + border * 2
      lines[#lines + 1] = ("float %s%-4d: reported row=%d col=%d  content=%dx%d  extent=%dx%d  fits_h=%s")
        :format(
          w == watched_win and "*" or " ",
          w,
          pos[1],
          pos[2],
          width,
          height,
          extent_c,
          extent_r,
          tostring(pos[2] + extent_c <= vim.o.columns)
        )
      -- What the image's top-left cell should be if this float owns it.
      lines[#lines + 1] = ("             expected content origin: row=%d col=%d")
        :format(pos[1] + border + 1, pos[2] + border + 1)
    end
  end

  local cfg = require("images.config").get().display
  lines[#lines + 1] = ("config        : draw_inset=%s terminal_padding={row=%s,col=%s} cell_aspect=%s")
    :format(
      tostring(cfg.draw_inset),
      tostring((cfg.terminal_padding or {}).row),
      tostring((cfg.terminal_padding or {}).col),
      tostring(cfg.cell_aspect)
    )
  lines[#lines + 1] = ("scale.CELL_ASPECT in effect: %s"):format(tostring(require("images.scale").CELL_ASPECT))

  -- One message, so `:messages` keeps the block together.
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)

  return term.__probe_original_draw(file, row, col, cols, rows)
end

vim.notify("[hover_probe] armed — hover an image, then run :messages", vim.log.levels.INFO)
