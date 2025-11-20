---@module 'custom.repo_pickers.select.router'
--- Selector router that chooses the repository selection UI based on config and engine hints.

local sel_vim = require("custom.repo_pickers.select.vim_select")
local sel_tel = require("custom.repo_pickers.select.telescope")
local sel_fzf = require("custom.repo_pickers.select.fzf")

local M = {}

--- Build a selector function from cfg.selector and the desired engine.
--- Rules:
---   • "vim_select": always use vim.ui.select
---   • "telescope":  always try Telescope (fallback to vim.ui.select)
---   • "fzf":        always try fzf-lua (fallback to vim.ui.select)
---   • "auto"/"match_engine"/invalid: match the engine hint: telescope → Telescope, fzf → fzf-lua; fallback to vim.ui.select
---
--- @param cfg RepoPickersConfig
--- @param engine_hint "telescope"|"fzf"|nil
--- @return fun(cfg:RepoPickersConfig, repos:RepoDir[], on_choice:fun(dir:RepoDir))
function M.mk_selector(cfg, engine_hint)
  local sel = cfg.selector or "auto"

  -- Force vim.ui.select
  if sel == "vim_select" then
    return function(c, r, cb)
      sel_vim.select(c, r, cb)
    end
  end

  -- Force specific UI regardless of engine (allowed, but not recommended)
  if sel == "telescope" then
    return function(c, r, cb)
      if not sel_tel.select(c, r, cb) then
        sel_vim.select(c, r, cb)
      end
    end
  end
  if sel == "fzf" then
    return function(c, r, cb)
      if not sel_fzf.select(c, r, cb) then
        sel_vim.select(c, r, cb)
      end
    end
  end

  -- auto / match_engine / anything else: follow the engine hint
  if engine_hint == "telescope" then
    return function(c, r, cb)
      if not sel_tel.select(c, r, cb) then
        sel_vim.select(c, r, cb)
      end
    end
  elseif engine_hint == "fzf" then
    return function(c, r, cb)
      if not sel_fzf.select(c, r, cb) then
        sel_vim.select(c, r, cb)
      end
    end
  else
    -- Unknown engine: try fzf, then Telescope then fallback
    return function(c, r, cb)
      if sel_fzf.select(c, r, cb) then
        return
      end
      if sel_tel.select(c, r, cb) then
        return
      end
      sel_vim.select(c, r, cb)
    end
  end
end

return M
