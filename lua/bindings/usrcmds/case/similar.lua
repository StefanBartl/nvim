---@module 'bindings.usrcmds.case.similar'
--- "Which past cases look like this one?" — TF-IDF-weighted cosine
--- similarity over each case's title + Summary.md (ROADMAP.md v8).
---
--- Deliberately lexical, no AI/embeddings: the bestand is technical bug
--- reports whose vocabulary is unusually diagnostic ("Unmapped Control",
--- "Element Not Found", "HTML Parent Document"), so two cases about the
--- same underlying problem overwhelmingly share the same rare terms. TF-IDF
--- is exactly the weighting that exploits that — a term appearing in nearly
--- every case ("SAP", "Tosca", "customer") contributes almost nothing,
--- while a term appearing in three cases dominates the score.
---
--- The known limitation, stated plainly: this matches WORDS, not meaning.
--- Two cases describing one problem in entirely different words score 0.
--- Whether that matters in practice is what ROADMAP.md v8 says to find out
--- before reaching for an embedding model.

local registry = require("bindings.usrcmds.case.registry")
local meta = require("bindings.usrcmds.case.meta")
local read = require("lib.nvim.fs.read")

local M = {}

--- Words carrying no topical signal, in both languages the bestand mixes.
--- Not exhaustive by design — TF-IDF already suppresses anything common,
--- so this list only needs to catch short function words that would
--- otherwise survive as noise in very short documents.
local STOPWORDS = {}
for _, w in ipairs({
  -- German
  "aber", "alle", "allem", "als", "also", "am", "an", "auch", "auf", "aus",
  "bei", "beim", "bin", "bis", "da", "dann", "das", "dass", "dem", "den",
  "der", "des", "die", "dies", "diese", "diesem", "diesen", "dieser",
  "doch", "dort", "durch", "ein", "eine", "einem", "einen", "einer",
  "eines", "er", "es", "für", "hat", "hatte", "ich", "ihre", "im", "in",
  "ist", "kann", "man", "mehr", "mit", "nach", "nicht", "noch", "nur",
  "oder", "sein", "sich", "sie", "sind", "so", "über", "um", "und", "vom",
  "von", "vor", "war", "wenn", "werden", "wie", "wir", "wird", "zu", "zum",
  "zur",
  -- English
  "a", "an", "and", "are", "as", "at", "be", "been", "but", "by", "can",
  "for", "from", "had", "has", "have", "he", "her", "his", "if", "in",
  "into", "is", "it", "its", "not", "of", "on", "or", "she", "that", "the",
  "their", "then", "there", "these", "they", "this", "to", "was", "we",
  "were", "when", "which", "will", "with", "would", "you", "your",
}) do
  STOPWORDS[w] = true
end

--- `string.lower` only folds ASCII, so "Über" and "über" would otherwise be
--- two different terms. Fold the German uppercase umlauts (UTF-8 byte
--- sequences) explicitly before lowering the rest.
local UMLAUT_FOLD = {
  ["\195\132"] = "\195\164", -- Ä -> ä
  ["\195\150"] = "\195\182", -- Ö -> ö
  ["\195\156"] = "\195\188", -- Ü -> ü
}

local MIN_TOKEN_LEN = 3

--- A hit needs at least this many shared terms. Without it, two nearly
--- empty summaries sharing one generic word ("Research") score ~90% purely
--- because a 1-term vector is perfectly parallel to another 1-term vector —
--- observed on the real bestand during the first evaluation run.
local MIN_SHARED_TERMS = 2

--- Below this many distinct terms a document is too thin to say anything
--- about; it neither ranks nor gets ranked against.
local MIN_DOC_TERMS = 8

---@param text string
---@return string[]
local function tokenize(text)
  text = text:gsub("\r", "")

  -- Markdown/structural noise that would otherwise contribute terms:
  -- fenced code, inline code, URLs, TOC anchor links, and the box-drawing
  -- characters some summaries in this bestand use as section rules.
  text = text:gsub("```.-```", " ")
  text = text:gsub("`[^`]*`", " ")
  text = text:gsub("https?://%S+", " ")
  text = text:gsub("%[[^%]]*%]%(#[^%)]*%)", " ")

  for upper, lower in pairs(UMLAUT_FOLD) do
    text = text:gsub(upper, lower)
  end
  text = text:lower()

  local tokens = {}
  -- Bytes >= 128 (UTF-8 continuation/lead bytes for umlauts etc.) are
  -- neither %s nor %p nor %d, so this keeps accented words intact rather
  -- than splitting them mid-character. The %a check then throws out runs
  -- that are ONLY high bytes — box-drawing rules like "╙───────────" are
  -- used as section separators throughout this bestand and would otherwise
  -- rank as top shared "terms" (they did, on the first evaluation run).
  for word in text:gmatch("[^%s%p%d]+") do
    if #word >= MIN_TOKEN_LEN and word:find("%a") and not STOPWORDS[word] then
      tokens[#tokens + 1] = word
    end
  end
  return tokens
end

--- Both documents feed the comparison, for different reasons: `Summary.md`
--- carries the SNOW problem statement and solution (the most diagnostic
--- text a case has), `Notes.md` the private working notes (often the only
--- text at all, on a case whose SNOW summary was never filled in). Reading
--- just one would miss half the bestand — see CONCEPT.md §8a.
local SOURCE_FILES = { "Summary.md", "Notes.md" }

--- A term that's part of the TITLE gets counted this many times ON TOP OF
--- its natural occurrences in the combined text (ROADMAP.md v9: "gleiche
--- wörter im title zählen ein wenig mehr"). The title is a one-sentence
--- human summary of what the case IS ("Unmapped Control after Fiori
--- Update"); the body is a transcript of the whole back-and-forth,
--- including greetings, SNOW boilerplate, and "Best Regards" — a word the
--- author chose to put in the title is far more likely to be the actual
--- topic than a word that merely occurs somewhere in three paragraphs of
--- correspondence. Sublinear TF-IDF (`tfidf_vector` below) means this
--- doesn't dominate the score outright — log(1+count) flattens the boost —
--- it nudges title terms up without letting a two-word title out-rank a
--- detailed Summary.md on its own.
local TITLE_BOOST = 2

---@param entry Lib.Case.RegistryEntry
---@return string title  raw, untokenized (caller tokenizes)
---@return string body  title + Summary.md + Notes.md, concatenated
local function document_parts(entry)
  local m = meta.read(entry.dir)
  local title = (m and m.title) or ""
  local parts = {}
  if title ~= "" then
    parts[#parts + 1] = title
  end
  for _, name in ipairs(SOURCE_FILES) do
    local content = read(entry.dir .. "/" .. name)
    if content then
      parts[#parts + 1] = content
    end
  end
  return title, table.concat(parts, "\n")
end

---@param tokens string[]  the full document (title already included once)
---@param title_tokens string[]|nil  same terms again, to weight them up
---@return table<string, number> term -> raw count
local function term_counts(tokens, title_tokens)
  local tf = {}
  for _, t in ipairs(tokens) do
    tf[t] = (tf[t] or 0) + 1
  end
  if title_tokens then
    for _, t in ipairs(title_tokens) do
      tf[t] = (tf[t] or 0) + TITLE_BOOST
    end
  end
  return tf
end

---@class Lib.Case.SimilarHit
---@field entry Lib.Case.RegistryEntry
---@field score number  Cosine similarity in [0, 1].
---@field terms string[]  The terms contributing most to the score, best first.

local TOP_TERMS = 5

--- Rank every other case by similarity to `short`.
---@param short string
---@param n integer|nil  How many hits to return (default 5).
---@return Lib.Case.SimilarHit[] hits  Descending by score, zero-score cases omitted.
---@return string|nil err  Set when `short` itself has nothing to compare.
function M.rank(short, n)
  n = n or 5

  local entries = registry.list()
  local docs, target_idx = {}, nil
  for i, e in ipairs(entries) do
    local title, body = document_parts(e)
    docs[i] = term_counts(tokenize(body), tokenize(title))
    if e.short == short then
      target_idx = i
    end
  end

  if not target_idx then
    return {}, ("unknown case: %s"):format(short)
  end
  local target_terms = vim.tbl_count(docs[target_idx])
  if target_terms < MIN_DOC_TERMS then
    return {},
      ("case %s has too little Summary.md text to compare (%d distinct terms, need %d)"):format(
        short,
        target_terms,
        MIN_DOC_TERMS
      )
  end

  -- Document frequency, then idf. `#entries` is the corpus size; a term in
  -- every case gets idf ~0 and drops out of the ranking entirely.
  local df = {}
  for _, tf in ipairs(docs) do
    for term in pairs(tf) do
      df[term] = (df[term] or 0) + 1
    end
  end
  local idf = {}
  for term, count in pairs(df) do
    idf[term] = math.log(#entries / count) + 1
  end

  -- Sublinear (log-scaled) term frequency: a word used 20 times in one long
  -- summary shouldn't outweigh a rarer, more diagnostic word used twice.
  ---@param tf table<string, number>
  ---@return table<string, number> vec, number norm
  local function tfidf_vector(tf)
    local vec, sum_sq = {}, 0
    for term, count in pairs(tf) do
      local w = (1 + math.log(count)) * (idf[term] or 0)
      if w > 0 then
        vec[term] = w
        sum_sq = sum_sq + w * w
      end
    end
    return vec, math.sqrt(sum_sq)
  end

  local target_vec, target_norm = tfidf_vector(docs[target_idx])
  if target_norm == 0 then
    return {}, ("case %s shares no distinctive terms with the rest"):format(short)
  end

  local hits = {}
  for i, e in ipairs(entries) do
    if i ~= target_idx then
      local vec, norm = tfidf_vector(docs[i])
      if norm > 0 then
        local dot = 0
        local contributions = {}
        for term, w in pairs(target_vec) do
          local other = vec[term]
          if other then
            local product = w * other
            dot = dot + product
            contributions[#contributions + 1] = { term = term, product = product }
          end
        end
        if dot > 0 then
          table.sort(contributions, function(a, b)
            return a.product > b.product
          end)
          local terms = {}
          for k = 1, math.min(TOP_TERMS, #contributions) do
            terms[k] = contributions[k].term
          end
          hits[#hits + 1] = {
            entry = e,
            score = dot / (target_norm * norm),
            terms = terms,
          }
        end
      end
    end
  end

  table.sort(hits, function(a, b)
    return a.score > b.score
  end)

  local out = {}
  for i = 1, math.min(n, #hits) do
    out[i] = hits[i]
  end
  return out, nil
end

return M
