---@module 'bindings.usrcmds.case.solution'
--- A case's solution as ONE known file: `Solution/Solution.md`.
---
--- Why its own file and not "it's in the Summary": `Summary.md` is the
--- ServiceNow document (fixed SNOW template, not Markdown, CONCEPT.md §8a),
--- `Notes.md` the work log — both are history, not an answer. What REALLY
--- helped ends up there between three failed attempts, a coach hint and "Best
--- Regards". That one paragraph is what saves the same afternoon on the next
--- similar case half a year later. A fixed file in a fixed place is the
--- precondition for finding it again — heuristically today (`M.search`,
--- TF-IDF over exactly these files) and via AI later (ROADMAP.md: only
--- references from the official docs and equivalents count as a source for
--- case solutions — one's own verified solutions are the second such source).
---
--- The location is NOT newly invented: `doctor.lua` already enforces the
--- `Solution/` convention (folder, singular) across the corpus and moves a
--- flat `Solution.md` or a `Solutions/` there. So this module always writes
--- to `Solution/Solution.md` — but also reads the legacy locations (see
--- `M.locate`) so a not-yet-normalized case doesn't wrongly count as "no
--- solution".
---
--- The structure (## Status / Problem / Ursache / Lösung / Verifikation /
--- Schlagworte / Referenzen, `templates/Solution.md`) is the real value over
--- free text: it makes the search weightable per field (a hit in
--- `## Schlagworte` weighs more than one somewhere in prose) and gives a
--- later AI a format it need not guess. The parser still does NOT insist: a
--- hand-written Solution.md without a single known heading stays fully
--- searchable, it just loses the weighting.

local config = require("bindings.usrcmds.case.config")
local registry = require("bindings.usrcmds.case.registry")
local meta = require("bindings.usrcmds.case.meta")
local render = require("bindings.usrcmds.case.render")
local templates = require("bindings.usrcmds.case.templates")
local similar = require("bindings.usrcmds.case.similar")

local read = require("lib.nvim.fs.read")
local mkdirp = require("lib.nvim.fs.mkdirp")
local write_to_file = require("lib.nvim.fs.write.to_file")

local uv = vim.uv or vim.loop

local M = {}

--- Canonical sections in file order — also the display order in
--- `:Case solution`.
---@type string[]
M.SECTIONS = { "status", "problem", "cause", "solution", "verification", "keywords", "references" }

--- Canonical key -> heading as it appears in the file (German — this is the
--- template's section wording).
---@type table<string, string>
M.LABELS = {
  status = "Status",
  problem = "Problem",
  cause = "Ursache",
  solution = "Lösung",
  verification = "Verifikation",
  keywords = "Schlagworte",
  references = "Referenzen",
}

--- Heading (lower-cased) -> canonical key. German AND English, because the
--- corpus mixes both: the SNOW template writes "Solution or workaround", a
--- hand-written note "Lösung", an AI answer often "Root cause". A missing
--- alias here costs only the field weighting — the text stays findable via
--- full text.
---@type table<string, string>
local ALIASES = {
  ["status"] = "status",
  ["stand"] = "status",
  ["problem"] = "problem",
  ["problem statement"] = "problem",
  ["symptom"] = "problem",
  ["fehlerbild"] = "problem",
  ["ursache"] = "cause",
  ["root cause"] = "cause",
  ["cause"] = "cause",
  ["lösung"] = "solution",
  ["loesung"] = "solution",
  ["solution"] = "solution",
  ["solution or workaround"] = "solution",
  ["workaround"] = "solution",
  ["fix"] = "solution",
  ["verifikation"] = "verification",
  ["verification"] = "verification",
  ["nachweis"] = "verification",
  ["schlagworte"] = "keywords",
  ["schlagwörter"] = "keywords",
  ["keywords"] = "keywords",
  ["tags"] = "keywords",
  ["referenzen"] = "references",
  ["references"] = "references",
  ["quellen"] = "references",
  ["links"] = "references",
}

---@class Lib.Case.SolutionDoc
---@field entry Lib.Case.RegistryEntry
---@field path string             where the file actually sits (may be a legacy location).
---@field canonical boolean       false when it is not yet at `Solution/Solution.md`.
---@field title string            case title from `.case.json` ("" if none).
---@field status string|nil       normalized to a `config.solution_statuses` entry.
---@field keywords string[]
---@field sections table<string, string>  canonical key -> section text
---@field extra table<string, string>     unknown heading -> section text
---@field text string             full text without the H1 — the search substrate.

-- ── Paths ────────────────────────────────────────────────────────────────

---@param case_dir string
---@return string
function M.dir(case_dir)
  return case_dir .. "/" .. config.solution_dirname
end

--- Wohin GESCHRIEBEN wird — immer, ausnahmslos. Gelesen wird auch woanders
--- (`M.locate`).
---@param case_dir string
---@return string
function M.path(case_dir)
  return M.dir(case_dir) .. "/" .. config.solution_filename
end

---@param dir string
---@return string[] absolute Pfade aller *.md, alphabetisch
local function markdown_files(dir)
  local out = {}
  local fd = uv.fs_scandir(dir)
  if not fd then
    return out
  end
  while true do
    local name, typ = uv.fs_scandir_next(fd)
    if not name then
      break
    end
    if typ ~= "directory" and name:lower():match("%.md$") then
      out[#out + 1] = dir .. "/" .. name
    end
  end
  table.sort(out)
  return out
end

--- A case's solution file, whichever of the historical locations it sits in.
--- Order = "more canonical, earlier"; `:Cases doctor` / `normalize` eventually
--- move the later ones onto the first, but until then `:Case solution` should
--- still find it rather than claim "no solution" and create a second one.
---@param case_dir string
---@return string|nil path, boolean canonical
function M.locate(case_dir)
  local canonical = M.path(case_dir)
  if uv.fs_stat(canonical) then
    return canonical, true
  end
  for _, dirname in ipairs({ config.solution_dirname, config.solution_dirname .. "s" }) do
    local files = markdown_files(case_dir .. "/" .. dirname)
    if #files > 0 then
      return files[1], false
    end
  end
  local flat = case_dir .. "/" .. config.solution_filename
  if uv.fs_stat(flat) then
    return flat, false
  end
  return nil, false
end

---@param case_dir string
---@return boolean
function M.exists(case_dir)
  return (M.locate(case_dir)) ~= nil
end

-- ── Parsing ──────────────────────────────────────────────────────────────

---@param heading string
---@return string|nil canonical key
local function canonical_section(heading)
  local h = vim.trim(heading)
  h = h:gsub("%[([^%]]+)%]%([^%)]*%)", "%1") -- ## [Foo](url) -> Foo
  h = h:gsub("%s*:%s*$", "")
  return ALIASES[h:lower()]
end

--- Map the first non-empty line of the Status section to a
--- `config.solution_statuses` entry. Substring, not equality: "Gelöst
--- (Workaround beim Kunden aktiv)" should still pass as a status rather than
--- vanish as "unknown". Config order decides ambiguity — hence the specific
--- "Workaround" before the general "Offen".
---@param text string|nil
---@return string|nil
local function parse_status(text)
  if not text or text == "" then
    return nil
  end
  local first = vim.trim(vim.split(text, "\n", { plain = true })[1] or ""):lower()
  if first == "" then
    return nil
  end
  for _, status in ipairs(config.solution_statuses) do
    if first:find(status:lower(), 1, true) then
      return status
    end
  end
  return nil
end

--- Schlagworte aus ihrem Abschnitt: Kommaliste, Bullet-Liste oder eine
--- Zeile pro Begriff — alle drei kommen in handgeschriebenen Notizen vor,
--- also werden alle drei akzeptiert.
---@param text string|nil
---@return string[]
local function parse_keywords(text)
  if not text or text == "" then
    return {}
  end
  local out, seen = {}, {}
  for _, line in ipairs(vim.split(text, "\n", { plain = true })) do
    line = line:gsub("^%s*[%-%*%+]%s*", "")
    for part in (line .. ","):gmatch("([^,;]*)[,;]") do
      local kw = vim.trim(part:gsub("^`(.*)`$", "%1"))
      if kw ~= "" and not seen[kw:lower()] then
        seen[kw:lower()] = true
        out[#out + 1] = kw
      end
    end
  end
  return out
end

--- Raw text -> sections. The H1 (`config.headline_format`) drops out: it is
--- case metadata, not a solution, and would only double-count the title in
--- the search — which `M.search` already weights separately.
---@param text string
---@return { sections: table<string, string>, extra: table<string, string>, status: string|nil, keywords: string[], text: string }
function M.parse(text)
  text = (text or ""):gsub("\r", "")
  local sections, extra = {}, {}
  local current_key, current_raw, body = nil, nil, {}
  local body_lines = {}

  local function flush()
    local joined = vim.trim(table.concat(body, "\n"))
    if current_key then
      sections[current_key] = joined
    elseif current_raw then
      extra[current_raw] = joined
    end
    body = {}
  end

  for _, line in ipairs(vim.split(text, "\n", { plain = true })) do
    if line:match("^#%s") then
      -- H1 = the mandated case headline, not content.
      flush()
      current_key, current_raw = nil, nil
    else
      local heading = line:match("^#+%s+(.+)$")
      if heading then
        flush()
        current_key = canonical_section(heading)
        current_raw = current_key and nil or vim.trim(heading)
        body_lines[#body_lines + 1] = heading
      else
        body[#body + 1] = line
        body_lines[#body_lines + 1] = line
      end
    end
  end
  flush()

  return {
    sections = sections,
    extra = extra,
    status = parse_status(sections.status),
    keywords = parse_keywords(sections.keywords),
    text = vim.trim(table.concat(body_lines, "\n")),
  }
end

--- A case's solution, parsed. `nil` (not an error) when there is none — the
--- normal state for any still-running case.
---@param entry Lib.Case.RegistryEntry
---@return Lib.Case.SolutionDoc|nil
function M.read(entry)
  local path, canonical = M.locate(entry.dir)
  if not path then
    return nil
  end
  local content = read(path)
  if not content then
    return nil
  end
  local parsed = M.parse(content)
  local m = meta.read(entry.dir)
  return {
    entry = entry,
    path = path,
    canonical = canonical,
    title = (m and m.title) or "",
    status = parsed.status,
    keywords = parsed.keywords,
    sections = parsed.sections,
    extra = parsed.extra,
    text = parsed.text,
  }
end

--- Every solution in the corpus, in registry order.
---@return Lib.Case.SolutionDoc[]
function M.corpus()
  local out = {}
  for _, entry in ipairs(registry.list()) do
    local doc = M.read(entry)
    if doc then
      out[#out + 1] = doc
    end
  end
  return out
end

-- ── Creating ─────────────────────────────────────────────────────────────

--- The content of a fresh solution: the mandated H1 (`config.headline_format`
--- centrally via `render.headline`, exactly as `plan.lua` writes it for every
--- blueprint file) plus the body from `templates/Solution.md`.
---@param entry Lib.Case.RegistryEntry
---@return string[]
function M.template_lines(entry)
  local m = meta.read(entry.dir)
  local tokens = {
    case = entry.short,
    title = (m and m.title) or "",
    company = (m and m.company) or "",
    name = (m and m.name) or "",
    year = (m and m.year) or os.date("%Y"),
    today = os.date("%Y-%m-%d"),
  }
  local lines = {
    render.headline(entry.short, m and m.title, render.filename_token(config.solution_filename)),
    "",
  }
  vim.list_extend(lines, templates.render(templates.SOLUTION, tokens))
  return lines
end

--- Creates `Solution/Solution.md` — and only when there is no solution at all
--- yet (not even in a legacy location): an existing file is never overwritten,
--- the same rule as every blueprint node (`overwrite = false`).
---@param entry Lib.Case.RegistryEntry
---@return string|nil path, string|nil err
function M.create(entry)
  local existing = M.locate(entry.dir)
  if existing then
    return existing, nil
  end
  local ok_dir, err_dir = mkdirp(M.dir(entry.dir))
  if ok_dir == false then
    return nil, tostring(err_dir)
  end
  local path = M.path(entry.dir)
  local ok, err = write_to_file(path, table.concat(M.template_lines(entry), "\n"))
  if not ok then
    return nil, tostring(err)
  end
  return path, nil
end

-- ── Search (heuristic, not AI) ───────────────────────────────────────────

--- A term from `## Schlagworte` counts this many times extra — the same
--- mechanic as `similar.lua`'s TITLE_BOOST (extra counts in the same tf table,
--- not a second vector), for the same reason: the keywords are what someone
--- deliberately wrote as "this is what it was about", the prose also contains
--- failed attempts and quotes.
local KEYWORD_BOOST = 3
local TITLE_BOOST = 2

--- If the query occurs as a CONTIGUOUS string ("unmapped control"), that is a
--- stronger signal than the same words scattered. A multiplier, not a fixed
--- bonus, so a phrase hit in an otherwise weak document doesn't overtake a
--- substantively better one.
local PHRASE_BOOST = 1.5

---@class Lib.Case.SolutionHit
---@field doc Lib.Case.SolutionDoc
---@field score number    comparable for sorting only, not a percentage (see below).
---@field terms string[]  query terms actually hit, strongest first.
---@field matched integer
---@field wanted integer  evaluable terms in the query.
---@field phrase boolean  query occurred verbatim as a string.

--- A document's term counts, including field weighting.
---@param doc Lib.Case.SolutionDoc
---@return table<string, number>
local function term_counts(doc)
  local tf = {}
  for _, t in ipairs(similar.tokenize(doc.text)) do
    tf[t] = (tf[t] or 0) + 1
  end
  for _, t in ipairs(similar.tokenize(table.concat(doc.keywords, " "))) do
    tf[t] = (tf[t] or 0) + KEYWORD_BOOST
  end
  for _, t in ipairs(similar.tokenize(doc.title)) do
    tf[t] = (tf[t] or 0) + TITLE_BOOST
  end
  return tf
end

--- Solutions for a query, descending by match.
---
--- Deliberately NO percentage like `:Case similar`: there two documents of the
--- same kind face off (cosine of two vectors, 0..1 is real); here a
--- three-word query against a document — any normalization onto that would be
--- invented precision. Instead `matched`/`wanted` and the hit terms show WHY
--- something ranks where it does; the same honesty `:Case similar` pursues
--- with its term list.
---
--- Without a query: every solution, in registry order with `score = 0` — the
--- picker does the filtering then.
---@param query string|nil
---@return Lib.Case.SolutionHit[] hits
---@return string|nil err
function M.search(query)
  local docs = M.corpus()
  if #docs == 0 then
    return {}, "im Bestand gibt es noch keine einzige Lösung"
  end

  query = vim.trim(query or "")
  if query == "" then
    local all = {}
    for _, doc in ipairs(docs) do
      all[#all + 1] = { doc = doc, score = 0, terms = {}, matched = 0, wanted = 0, phrase = false }
    end
    return all, nil
  end

  local q_tokens = similar.tokenize(query)
  local needle = query:lower()

  -- Query with no evaluable term (too short, pure stopword, "1234"): plain
  -- substring search, rather than an empty list that would look like there's
  -- nothing.
  if #q_tokens == 0 then
    local hits = {}
    for _, doc in ipairs(docs) do
      if doc.text:lower():find(needle, 1, true) then
        hits[#hits + 1] =
          { doc = doc, score = 1, terms = { query }, matched = 1, wanted = 1, phrase = true }
      end
    end
    return hits, nil
  end

  local tfs, df = {}, {}
  for i, doc in ipairs(docs) do
    tfs[i] = term_counts(doc)
    for term in pairs(tfs[i]) do
      df[term] = (df[term] or 0) + 1
    end
  end

  local hits = {}
  for i, doc in ipairs(docs) do
    local tf = tfs[i]
    local score, contributions, seen = 0, {}, {}
    for _, term in ipairs(q_tokens) do
      local count = tf[term]
      if count and not seen[term] then
        seen[term] = true
        -- Sublinear tf, idf over exactly this corpus: a word in EVERY solution
        -- ("tosca") contributes almost nothing.
        local idf = math.log(#docs / df[term]) + 1
        local w = (1 + math.log(count)) * idf
        score = score + w
        contributions[#contributions + 1] = { term = term, w = w }
      end
    end
    local phrase = doc.text:lower():find(needle, 1, true) ~= nil
    if phrase then
      score = math.max(score, 1) * PHRASE_BOOST
    end
    if score > 0 then
      table.sort(contributions, function(a, b)
        return a.w > b.w
      end)
      local terms = {}
      for k, c in ipairs(contributions) do
        terms[k] = c.term
      end
      hits[#hits + 1] = {
        doc = doc,
        score = score,
        terms = terms,
        matched = #contributions,
        wanted = #q_tokens,
        phrase = phrase,
      }
    end
  end

  table.sort(hits, function(a, b)
    if a.score ~= b.score then
      return a.score > b.score
    end
    return a.doc.entry.short < b.doc.entry.short
  end)
  return hits, nil
end

return M
