---@module 'autocmds.git.blame_on_hold'
--- Show inline blame via gitsigns when the cursor rests (non-intrusive).

---@class AutoCmds.Git.BlameOnHold
local M = {}

local api = vim.api

---@param cfg AutoCmds.Git.BlameOnHoldCfg
---@param shared table
---@return nil
function M.enable(cfg, shared)
  if not (cfg and cfg.enable) then
    return
  end

  api.nvim_create_autocmd("CursorHold", {
    group = shared.augroup("blame_on_hold"),
    callback = function()
      local bt = vim.bo.buftype
      if cfg.ignore_buftypes and vim.tbl_contains(cfg.ignore_buftypes, bt) then
        return
      end
      local ok, gs = pcall(require, "gitsigns")
      if not ok or not gs.blame_line then
        return
      end

      local function run()
        pcall(gs.blame_line, {
          full = false,
          ignore_whitespace = true,
          virt_text = (cfg.virt ~= false),
        })
      end

      local delay = tonumber(cfg.delay or 0) or 0
      if delay > 0 then
        vim.defer_fn(run, delay)
      else
        run()
      end
    end,
    desc = "Git: inline blame on CursorHold (gitsigns)",
  })
end

return M
