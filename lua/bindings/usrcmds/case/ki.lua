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
local config = require("bindings.usrcmds.case.config")
local replygate = require("bindings.usrcmds.case.replygate")

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
---@field sla string|nil  One-line SLA context (SLA.md §6E) — priority + the most urgent clock's remaining time, so the AI scopes its answer to how much time this actually has. `{sla}`, deliberately no underscore: templates.lua's `%{(%w+)%}` substitution pattern doesn't match one (see `{activitystream}`'s own comment below).
---@field facts string|nil  The "Ermittelte Fakten" block (EXTRACTION.md §7 Richtung 1, `extract.facts.render`) — everything deterministically parsable (versions, SAP Component, SLA state, doc-link versions) as ground truth in the prompt instead of left for the model to guess. `{facts}`, same no-underscore reason as `{sla}`.
---@field screenshots string|nil  The text `:Case ocr` read out of this case's attachments (`ocr.render`) — the one part of a case that used to be unreadable to every text-based feature here. Carries its own "machine-read, may be wrong" caveat inside the block rather than beside it, because `{facts}` and this must not read as the same class of evidence: facts are parsed from files the customer sent, this is guessed from pixels. `{screenshots}`, same no-underscore reason as `{sla}`.

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
    sla = tokens.sla,
    facts = tokens.facts,
    screenshots = tokens.screenshots,
    activitystream = vim.trim(activity_stream or ""),
    -- `{reporoot}`, deliberately no underscore: templates.lua's
    -- `%{(%w+)%}` substitution pattern doesn't match one (see `{sla}`'s
    -- own comment above for the same reason). Machine-specific
    -- (config.repo_root derives from $REPOS_DIR) rather than the
    -- workstation's own hardcoded drive letter.
    reporoot = config.repo_root,
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

--- Headings that only ever appear in the prompt `M.build_prompt` writes,
--- never in an answer to it. `KiPrompt.md` spells the requested answer
--- format out verbatim (`## 1. Activity Stream Analysis` … `## 5. …`), so
--- the prompt parses as a perfectly well-formed — and completely empty —
--- response. Used solely to word the error when that happens.
local PROMPT_MARKERS = {
  "## Antwortformat",
  "## My Job Role Description",
  "## Workflow-Ressourcen & Policies",
}

--- Split a pasted AI answer into its five sections by the leading digit of
--- each `## N. ...` heading. A missing section is simply absent from the
--- result (nil), not an error — the caller decides whether e.g. a missing
--- reply draft is fatal for what it's about to do.
---@param text string
---@return Lib.Case.KiResponse|nil sections
---@return string|nil err  Set when no numbered section was found at all, or
--- when sections 1-3 are all empty (nothing worth filing — typically the
--- prompt itself pasted back).
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
    return nil,
      "no numbered '## N. ...' sections found — paste the AI's full answer, in the requested format"
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

  -- The AI sometimes signs the reply draft anyway despite the prompt never
  -- asking for one — same "always leave it out" feedback (2026-08-11) that
  -- `blocks.lua` handles for the hand-written block library. Only the
  -- customer-facing section, not analysis/difficulty/solution/notes.
  if sections.reply then
    sections.reply = replygate.strip_signature(sections.reply)
  end

  -- An answer always fills 1-3; only the prompt's own format spec matches
  -- the headings with nothing under them. Refuse rather than file three
  -- headline-only files and append the whole activity stream to Notes.md.
  local has_body = false
  for _, key in ipairs({ "analysis", "difficulty", "solution" }) do
    if vim.trim(sections[key] or "") ~= "" then
      has_body = true
      break
    end
  end
  if not has_body then
    for _, marker in ipairs(PROMPT_MARKERS) do
      if text:find(marker, 1, true) then
        return nil,
          "that's the prompt, not the answer — paste it into your AI chat first, then copy the reply"
      end
    end
    return nil, "sections 1-3 are empty — paste the AI's full answer, in the requested format"
  end

  return sections, nil
end

return M
