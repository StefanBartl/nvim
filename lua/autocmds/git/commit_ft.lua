---@module 'autocmds.git.commit_ft'
--- Tweak gitcommit buffers (spell, tw, colorcolumn, formatoptions, startinsert).

---@class GitAutoCmdsCommitFt
local M = {}

local api = vim.api

---@param cfg GitAutoCmdsCommitFtCfg
---@param _shared table
---@return nil
---@diagnostic disable-next-line: unused-local
function M.enable(cfg, _shared)
  if not (cfg and cfg.enable) then
    return
  end

  api.nvim_create_autocmd("FileType", {
    group = api.nvim_create_augroup("git_autocmds_commit_ft", { clear = true }),
    pattern = "gitcommit",
    callback = function()
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
        vim.schedule(function()
          if vim.bo.filetype == "gitcommit" then
            vim.cmd("startinsert")
          end
        end)
      end
    end,
    desc = "Git: commit message buffer settings",
  })
end

return M
