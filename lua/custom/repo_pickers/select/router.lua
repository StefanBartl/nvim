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
--- @param cfg RepoPickers.Config
--- @param engine_hint "telescope"|"fzf"|nil
--- @return fun(cfg:RepoPickers.Config, repos:RepoPickers.RepoDir[], on_choice:fun(dir:RepoPickers.RepoDir))
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

--- Check if a function exists in a module
---@param mod table
---@param func_name string
---@return boolean
local function has_function(mod, func_name)
  return type(mod[func_name]) == "function"
end

--- Build a selector function for wkdbooks from cfg.selector and the desired engine.
---@param cfg RepoPickers.Config
---@param engine_hint "telescope"|"fzf"|nil
---@return fun(cfg:RepoPickers.Config, wkdbooks:RepoPickers.RepoDir[], on_choice:fun(dir:RepoPickers.RepoDir))
function M.mk_wkdbook_selector(cfg, engine_hint)
  local sel = cfg.selector or "auto"

  -- Check if selectors have wkdbook-specific functions
  local vim_has_wkdbook = has_function(sel_vim, "select_wkdbook")
  local tel_has_wkdbook = has_function(sel_tel, "select_wkdbook")
  local fzf_has_wkdbook = has_function(sel_fzf, "select_wkdbook")

  -- Force vim.ui.select
  if sel == "vim_select" then
    return function(c, w, cb)
      if vim_has_wkdbook then
        sel_vim.select_wkdbook(c, w, cb)
      else
        sel_vim.select(c, w, cb)
      end
    end
  end

  -- Force specific UI regardless of engine
  if sel == "telescope" then
    return function(c, w, cb)
      local handled = false
      if tel_has_wkdbook then
        handled = sel_tel.select_wkdbook(c, w, cb)
      else
        handled = sel_tel.select(c, w, cb)
      end
      if not handled then
        if vim_has_wkdbook then
          sel_vim.select_wkdbook(c, w, cb)
        else
          sel_vim.select(c, w, cb)
        end
      end
    end
  end
  if sel == "fzf" then
    return function(c, w, cb)
      local handled = false
      if fzf_has_wkdbook then
        handled = sel_fzf.select_wkdbook(c, w, cb)
      else
        handled = sel_fzf.select(c, w, cb)
      end
      if not handled then
        if vim_has_wkdbook then
          sel_vim.select_wkdbook(c, w, cb)
        else
          sel_vim.select(c, w, cb)
        end
      end
    end
  end

  -- auto / match_engine / anything else: follow the engine hint
  if engine_hint == "telescope" then
    return function(c, w, cb)
      local handled = false
      if tel_has_wkdbook then
        handled = sel_tel.select_wkdbook(c, w, cb)
      else
        handled = sel_tel.select(c, w, cb)
      end
      if not handled then
        if vim_has_wkdbook then
          sel_vim.select_wkdbook(c, w, cb)
        else
          sel_vim.select(c, w, cb)
        end
      end
    end
  elseif engine_hint == "fzf" then
    return function(c, w, cb)
      local handled = false
      if fzf_has_wkdbook then
        handled = sel_fzf.select_wkdbook(c, w, cb)
      else
        handled = sel_fzf.select(c, w, cb)
      end
      if not handled then
        if vim_has_wkdbook then
          sel_vim.select_wkdbook(c, w, cb)
        else
          sel_vim.select(c, w, cb)
        end
      end
    end
  else
    -- Unknown engine: try fzf, then Telescope then fallback
    return function(c, w, cb)
      local handled = false
      if fzf_has_wkdbook then
        handled = sel_fzf.select_wkdbook(c, w, cb)
      else
        handled = sel_fzf.select(c, w, cb)
      end
      if handled then
        return
      end
      if tel_has_wkdbook then
        handled = sel_tel.select_wkdbook(c, w, cb)
      else
        handled = sel_tel.select(c, w, cb)
      end
      if handled then
        return
      end
      if vim_has_wkdbook then
        sel_vim.select_wkdbook(c, w, cb)
      else
        sel_vim.select(c, w, cb)
      end
    end
  end
end

return M
