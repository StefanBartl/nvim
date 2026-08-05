---@module 'bindings.usrcmds.case.replygate'
--- Pre-send checks for a reply draft (ROADMAP.md v8's "Reply-Gate"): emoji
--- count, stray markdown headlines (a plain-text reply shouldn't carry
--- `##`, same reasoning as `doctor.lua`'s `summary-markdown` check), and
--- whether any link the reply mentions is still alive.
---
--- Spelling/grammar is deliberately NOT reimplemented here — language.nvim
--- already owns that domain; this module only launches its interactive
--- spellcheck (`ui.lua`'s caller does that directly, since it has no
--- "result" to fold into a report — spell issues are highlighted in the
--- buffer, not returned as data).
---
--- Every integration is optional (`pcall`-guarded): a machine without
--- emojis.nvim installed still gets the headline/link checks.

local linkcheck = require("bindings.usrcmds.case.linkcheck")

local M = {}

local URL_PATTERN = "https?://[%w%-%._~:/?#%[%]@!%$&'%(%)%*%+,;=%%]+"

---@param bufnr integer
---@return string[]
local function buf_lines(bufnr)
  return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
end

---@param lines string[]
---@return integer|nil  nil when emojis.nvim isn't installed.
local function count_emojis(lines)
  local ok_mod, emojis = pcall(require, "emojis")
  if not ok_mod then
    return nil
  end
  local ok_ops, ops = pcall(emojis.ops)
  if not ok_ops or not ops.count then
    return nil
  end
  local ok_count, n = pcall(ops.count, lines)
  return ok_count and n or nil
end

---@param lines string[]
---@return integer[]  1-based line numbers using a markdown heading (`#`, `##`, …).
local function headline_lines(lines)
  local out = {}
  for i, line in ipairs(lines) do
    if line:find("^#+%s") then
      out[#out + 1] = i
    end
  end
  return out
end

---@param lines string[]
---@return string[]  deduplicated URLs, in first-seen order.
local function extract_urls(lines)
  local seen, out = {}, {}
  for _, line in ipairs(lines) do
    for url in line:gmatch(URL_PATTERN) do
      url = url:gsub("[%.,;:%)]+$", "")
      if not seen[url] then
        seen[url] = true
        out[#out + 1] = url
      end
    end
  end
  return out
end

---@class Lib.Case.ReplyGateReport
---@field emoji_count integer|nil
---@field headline_lines integer[]
---@field link_results Lib.Case.LinkCheckResult[]

--- Runs the emoji/headline checks synchronously and the link check async
--- (it's a network call) — `on_done` fires once with the whole report, so a
--- caller building one combined view never has to juggle partial results.
---@param bufnr integer
---@param on_done fun(report: Lib.Case.ReplyGateReport)
function M.check(bufnr, on_done)
  local lines = buf_lines(bufnr)

  local urls = extract_urls(lines)
  local targets = {}
  for i, url in ipairs(urls) do
    targets[i] = { short = ("line %d"):format(i), url = url }
  end

  linkcheck.run(targets, function(link_results)
    on_done({
      emoji_count = count_emojis(lines),
      headline_lines = headline_lines(lines),
      link_results = link_results,
    })
  end)
end

--- Remove every emoji from `bufnr` in place. `nil, err` when emojis.nvim
--- isn't installed or its pure ops API is unavailable — never silently
--- does nothing.
---@param bufnr integer
---@return integer|nil removed
---@return string|nil err
function M.clear_emojis(bufnr)
  local ok_mod, emojis = pcall(require, "emojis")
  if not ok_mod then
    return nil, "emojis.nvim not installed"
  end
  local ok_ops, ops = pcall(emojis.ops)
  if not ok_ops or not ops.clear then
    return nil, "emojis.nvim's ops API is unavailable"
  end
  local lines = buf_lines(bufnr)
  local ok_clear, cleaned, removed = pcall(ops.clear, lines)
  if not ok_clear then
    return nil, tostring(cleaned)
  end
  if removed > 0 then
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, cleaned)
  end
  return removed, nil
end

return M
