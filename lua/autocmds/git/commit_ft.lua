---@module 'autocmds.git.commit_ft'
--- Tweak gitcommit buffers (spell, tw, colorcolumn, formatoptions, startinsert).

---@class AutoCmds.Git.CommitFt
local M = {}

local api = vim.api
local Autocmd = require("lib.nvim.autocmd")

---@param cfg AutoCmds.Git.CommitFtCfg
---@param _shared table
---@return nil
---@diagnostic disable-next-line: unused-local
function M.enable(cfg, _shared)
  if not (cfg and cfg.enable) then
    return
  end

  Autocmd.create("FileType", function(args)
    if cfg.spell ~= false then
      vim.opt_local.spell = true
    end
    if cfg.textwidth then
      vim.opt_local.textwidth = cfg.textwidth
    end
    if cfg.colorcolumn then
      vim.opt_local.colorcolumn = cfg.colorcolumn
    end
    if cfg.formatoptions then
      vim.opt_local.formatoptions = cfg.formatoptions
    end
    if cfg.start_in_insert then
      local buf = args.buf
      -- Re-check the commit buffer is still current: focus may have moved
      -- to a different window/buffer during the scheduled gap.
      vim.schedule(function()
        if
          vim.api.nvim_buf_is_valid(buf)
          and vim.bo[buf].filetype == "gitcommit"
          and vim.api.nvim_get_current_buf() == buf
        then
          vim.cmd("startinsert")
        end
      end)
    end
  end, {
    group = api.nvim_create_augroup("git_autocmds_commit_ft", { clear = true }),
    pattern = "gitcommit",
    desc = "Git: commit message buffer settings",
  })
end

return M
