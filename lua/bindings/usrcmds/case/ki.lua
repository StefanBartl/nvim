---@module 'bindings.usrcmds.case.ki'
--- Round-trip with an external AI chat (Gemini, Claude, whatever the user
--- has open) for "analyze this case's activity stream": `M.build_prompt`
--- assembles the same prompt every time — role, policies, this case's
--- activity stream, a fixed response format — instead of hand-copying
--- `StartChat.md` and three resource paths per case; `M.parse_response`
--- reads back an answer pasted in that format and splits it into the
--- pieces casedesk actually files somewhere.
---
--- Deliberately NOT an API call — casedesk has no AI dependency (same
--- reasoning as `:Case similar`'s TF-IDF-not-embeddings choice, CONCEPT.md
--- §8e: no external service, no latency, no non-determinism baked into the
--- module itself). The user pastes into whichever chat they already have
--- open and pastes the answer back; this module only makes both ends of
--- that copy-paste reliable and format-stable.

local templates = require("bindings.usrcmds.case.templates")

local M = {}

--- The five sections the prompt asks the AI to answer with, in order.
--- `M.parse_response` matches purely on the leading digit of an `## N. ...`
--- heading, not the wording after it — LLMs are far more reliable at
--- keeping a numbered list's numbers straight than at reproducing an exact
--- heading string verbatim, so the parser leans on the cheaper invariant.
local DIGIT_KEY = {
  ["1"] = "analysis",
  ["2"] = "difficulty",
  ["3"] = "solution",
  ["4"] = "reply",
  ["5"] = "notes",
}

---@class Lib.Case.KiTokens
---@field case string
---@field title string|nil
---@field company string|nil
---@field name string|nil

--- Assemble the full prompt for this case's activity stream.
---@param tokens Lib.Case.KiTokens
---@param activity_stream string
---@return string
function M.build_prompt(tokens, activity_stream)
  local render_tokens = {
    case = tokens.case,
    title = tokens.title,
    company = tokens.company,
    name = tokens.name,
    activitystream = vim.trim(activity_stream or ""),
  }
  local lines = templates.render(templates.KI_PROMPT, render_tokens)
  return table.concat(lines, "\n")
end

---@class Lib.Case.KiResponse
---@field analysis string|nil
---@field difficulty string|nil
---@field solution string|nil
---@field reply string|nil
---@field notes string|nil

--- Split a pasted AI answer into its five sections by the leading digit of
--- each `## N. ...` heading. A missing section is simply absent from the
--- result (nil), not an error — the caller decides whether e.g. a missing
--- reply draft is fatal for what it's about to do.
---@param text string
---@return Lib.Case.KiResponse|nil sections
---@return string|nil err  Set only when NO numbered section was found at all.
function M.parse_response(text)
  text = (text or ""):gsub("\r", "")
  local lines = vim.split(text, "\n", { plain = true })

  local headings = {}
  for i, line in ipairs(lines) do
    local digit = line:match("^##+%s*(%d)%.%s")
    if digit and DIGIT_KEY[digit] then
      headings[#headings + 1] = { idx = i, key = DIGIT_KEY[digit] }
    end
  end
  if #headings == 0 then
    return nil, "no numbered '## N. ...' sections found — paste the AI's full answer, in the requested format"
  end

  local sections = {}
  for i, h in ipairs(headings) do
    local from = h.idx + 1
    local to = (headings[i + 1] and headings[i + 1].idx - 1) or #lines
    local body = {}
    for j = from, to do
      body[#body + 1] = lines[j]
    end
    while body[1] and vim.trim(body[1]) == "" do
      table.remove(body, 1)
    end
    while body[#body] and vim.trim(body[#body]) == "" do
      table.remove(body)
    end
    sections[h.key] = table.concat(body, "\n")
  end
  return sections, nil
end

return M
