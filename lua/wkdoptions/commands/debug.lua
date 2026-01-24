---@module 'wkdoptions.commands.debug'
--- Debug command for breadcrumb context providers.
--- Command: WKDHighlightDebugCtx

local Core = require("wkdoptions.commands.core")
local C = require("wkdoptions.config")
local notify = require("lib.notify").create("[Commands.Debug]")

local M = {}

--- Safe wrapper for provider calls
---@nodiscard
---@param fn function|nil
---@return string
local function safe_call(fn)
  if type(fn) ~= "function" then
    return "<unavailable>"
  end

  local ok, val = pcall(fn)
  if ok then
    return tostring(val or "<nil>")
  else
    return "<error: " .. tostring(val) .. ">"
  end
end

--- Register debug command for breadcrumb context.
---@param opts WKDOptions.Commands.Debug_Opts|nil
---@return nil
function M.register(opts)
  opts = opts or {}
  local names = opts.names or {}
  local name_debug = names.debug or "WKDHighlightDebugCtx"

  -- Context module (provider) injected or loaded
  local mod = opts.mod or require("wkdoptions.hl_config.breadcrumbs.ctx")

  -- Separator resolver
  local function default_sepfn()
    local hc = C.cfg.highlight
    local s = hc.breadcrumbs_separator
    if type(s) == "string" and s ~= "" then
      return s
    end
    local hex = hc.breadcrumbs_nerd_hex
    if type(hex) == "string" and hex ~= "" then
      local n = tonumber(hex, 16)
      if n then
        return " " .. vim.fn.nr2char(n) .. " "
      end
    end
    return (vim.o.columns >= 100) and " ⟶ " or " › "
  end

  local get_sep = opts.sepfn or default_sepfn

  Core.define_cmd(name_debug, function()
    local hc = C.cfg.highlight
    local bctx = hc.breadcrumbs_ctx or {}

    -- Query providers
    local p = {
      lsp_func = safe_call(mod._ctx_lsp_func),
      ts_symbol = safe_call(mod._ctx_ts_symbol),
      lang_extra = safe_call(mod._ctx_lang_extra),
      word = safe_call(mod._ctx_word_fallback),
    }

    local base = safe_call(mod._ctx_base_token)

    -- Container augmenter
    local container_input = (p.ts_symbol ~= "<unavailable>" and p.ts_symbol ~= "<nil>")
        and p.ts_symbol
      or (base ~= "<unavailable>" and base ~= "<nil>") and base
      or nil

    p.container = (type(mod._ctx_with_container) == "function" and container_input)
        and safe_call(function()
          return mod._ctx_with_container(container_input)
        end)
      or "<unavailable>"

    -- Final context
    local chosen = safe_call(mod._build_context)

    -- Preview line (how winbar would look)
    local rel = (function(path)
      if path == "" then
        return "[No Name]"
      end
      local dir = vim.fn.fnamemodify(path, ":h")
      local gitdir = vim.fs.find(".git", { upward = true, path = dir })[1]
      if gitdir then
        local root = vim.fn.fnamemodify(gitdir, ":h")
        local relp = vim.fn.fnamemodify(path, (":~:%s"):format(root))
        if relp == path then
          return vim.fn.fnamemodify(path, ":t")
        end
        relp = relp:gsub("^%./", ""):gsub("^/", "")
        return relp
      else
        return vim.fn.fnamemodify(path, ":~:.")
      end
    end)(vim.api.nvim_buf_get_name(0))

    local sep = get_sep()
    local line = (chosen ~= "<unavailable>" and chosen ~= "<nil>")
        and (rel .. sep .. chosen)
      or rel

    -- Output
    local lines = {
      "Breadcrumbs Debug",
      ("file: %s"):format(vim.api.nvim_buf_get_name(0)),
      ("separator: %s"):format(sep),
      ("providers_order: %s"):format(vim.inspect(bctx.providers_order or {})),
      "flags:",
      ("  prefer_lsp_function            = %s"):format(tostring(bctx.prefer_lsp_function)),
      ("  use_treesitter_symbol          = %s"):format(tostring(bctx.use_treesitter_symbol)),
      ("  use_container_chain            = %s"):format(tostring(bctx.use_container_chain)),
      ("  use_lang_specific              = %s"):format(tostring(bctx.use_lang_specific)),
      ("  fallback_object_when_empty     = %s"):format(tostring(bctx.fallback_object_when_empty)),
      ("  fallback_word_when_empty       = %s"):format(tostring(bctx.fallback_word_when_empty)),
      ("  prefer_owner_in_literals       = %s"):format(tostring(bctx.prefer_owner_in_literals)),
      ("  prefer_owner_on_member_access  = %s"):format(tostring(bctx.prefer_owner_on_member_access)),
      ("  dedupe_containers              = %s"):format(tostring(bctx.dedupe_containers)),
      ("  container_join                 = %s"):format(tostring(bctx.container_join)),
      ("  container_max_depth            = %s"):format(tostring(bctx.container_max_depth)),
      ("  breadcrumbs_separator          = %s"):format(tostring(hc.breadcrumbs_separator)),
      ("  breadcrumbs_nerd_hex           = %s"):format(tostring(hc.breadcrumbs_nerd_hex)),
      "",
      "provider results:",
      ("  base       → %s"):format(base),
      ("  lsp_func   → %s"):format(p.lsp_func),
      ("  ts_symbol  → %s"):format(p.ts_symbol),
      ("  container  → %s"):format(p.container),
      ("  lang_extra → %s"):format(p.lang_extra),
      ("  word       → %s"):format(p.word),
      "",
      ("chosen: %s"):format(chosen),
      ("preview line: %s"):format(line),
    }

    notify.info(table.concat(lines, "\n"))
  end, { desc = "Debug breadcrumb context providers" })
end

return M
