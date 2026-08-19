---@module 'bindings.usrcmds.case.solution'
--- Die Lösung eines Cases als EINE bekannte Datei: `Solution/Solution.md`.
---
--- Warum eine eigene Datei und nicht "steht ja im Summary": `Summary.md` ist
--- das ServiceNow-Dokument (fixe SNOW-Vorlage, kein Markdown, CONCEPT.md
--- §8a), `Notes.md` das Arbeitsprotokoll — beide sind Verlauf, keine
--- Antwort. Was am Ende WIRKLICH geholfen hat, steht dort zwischen drei
--- Fehlversuchen, einem Coach-Hinweis und "Best Regards". Genau dieser eine
--- Absatz ist aber das, was ein halbes Jahr später beim nächsten Case
--- denselben Nachmittag spart. Eine feste Datei an einem festen Ort ist die
--- Voraussetzung dafür, dass man ihn wiederfindet — per Heuristik heute
--- (`M.search`, TF-IDF über genau diese Dateien) und per KI später
--- (ROADMAP.md: nur Referenzen aus der offiziellen Doku und Gleichwertigem
--- zählen als Quelle für Case-Lösungen — die eigenen, verifizierten
--- Lösungen sind die zweite solche Quelle).
---
--- Der Ort ist NICHT neu erfunden: `doctor.lua` erzwingt die Konvention
--- `Solution/` (Ordner, Singular) längst im Bestand und schiebt ein flaches
--- `Solution.md` bzw. ein `Solutions/` dorthin. Dieses Modul schreibt
--- deshalb immer nach `Solution/Solution.md` — liest aber (siehe
--- `M.locate`) auch die Altlagen, damit ein noch nicht normalisierter Case
--- nicht fälschlich als "keine Lösung" gilt.
---
--- Die Struktur (## Status / Problem / Ursache / Lösung / Verifikation /
--- Schlagworte / Referenzen, `templates/Solution.md`) ist der eigentliche
--- Mehrwert gegenüber Freitext: sie macht die Suche feldweise gewichtbar
--- (ein Treffer in `## Schlagworte` wiegt mehr als einer irgendwo im
--- Fließtext) und gibt einer späteren KI ein Format, das sie nicht raten
--- muss. Der Parser besteht trotzdem NICHT darauf: eine handgeschriebene
--- Solution.md ohne eine einzige bekannte Überschrift bleibt vollständig
--- durchsuchbar, sie verliert nur die Gewichtung.

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

--- Kanonische Abschnitte in Dateireihenfolge — zugleich die
--- Anzeigereihenfolge in `:Case solution`.
---@type string[]
M.SECTIONS = { "status", "problem", "cause", "solution", "verification", "keywords", "references" }

--- Kanonischer Schlüssel -> Überschrift, wie sie in der Datei steht.
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

--- Überschrift (kleingeschrieben) -> kanonischer Schlüssel. Deutsch UND
--- Englisch, weil der Bestand beides mischt: die SNOW-Vorlage schreibt
--- "Solution or workaround", eine handgeschriebene Notiz "Lösung", eine
--- KI-Antwort gern "Root cause". Ein hier fehlendes Alias kostet nur die
--- Feldgewichtung — der Text bleibt über den Volltext auffindbar.
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
---@field path string             Wo die Datei tatsächlich liegt (kann eine Altlage sein).
---@field canonical boolean       false, wenn sie noch nicht unter `Solution/Solution.md` liegt.
---@field title string            Case-Titel aus `.case.json` ("" wenn keiner).
---@field status string|nil       Normalisiert auf einen `config.solution_statuses`-Eintrag.
---@field keywords string[]
---@field sections table<string, string>  kanonischer Schlüssel -> Abschnittstext
---@field extra table<string, string>     unbekannte Überschrift -> Abschnittstext
---@field text string             Volltext ohne H1 — das Suchsubstrat.

-- ── Pfade ────────────────────────────────────────────────────────────────

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

--- Die Lösungsdatei eines Cases, egal in welcher der historischen Lagen sie
--- steckt. Reihenfolge = "je kanonischer, desto früher"; `:Cases doctor`/
--- `normalize` räumt die hinteren irgendwann auf die vordere um, aber bis
--- dahin soll `:Case solution` sie trotzdem finden, statt "keine Lösung" zu
--- behaupten und daneben eine zweite anzulegen.
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

-- ── Parsen ───────────────────────────────────────────────────────────────

---@param heading string
---@return string|nil canonical key
local function canonical_section(heading)
  local h = vim.trim(heading)
  h = h:gsub("%[([^%]]+)%]%([^%)]*%)", "%1") -- ## [Foo](url) -> Foo
  h = h:gsub("%s*:%s*$", "")
  return ALIASES[h:lower()]
end

--- Erste nicht-leere Zeile des Status-Abschnitts auf einen
--- `config.solution_statuses`-Eintrag abbilden. Teilstring statt Gleichheit:
--- "Gelöst (Workaround beim Kunden aktiv)" soll noch als Status durchgehen
--- statt als "unbekannt" zu verschwinden. Die Reihenfolge in der Config
--- entscheidet bei Mehrdeutigkeit — deshalb steht dort das spezifischere
--- "Workaround" vor dem allgemeinen "Offen".
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

--- Rohtext -> Abschnitte. Die H1 (`config.headline_format`) fällt raus: sie
--- ist Case-Metadatum, keine Lösung, und würde in der Suche nur den Titel
--- doppelt zählen — den gewichtet `M.search` ohnehin schon separat.
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
      -- H1 = die vorgeschriebene Case-Headline, kein Inhalt.
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

--- Die Lösung eines Cases, geparst. `nil` (kein Fehler) wenn es keine gibt —
--- der Normalfall für jeden noch laufenden Case.
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

--- Jede Lösung im Bestand, in Registry-Reihenfolge.
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

-- ── Anlegen ──────────────────────────────────────────────────────────────

--- Der Inhalt einer frischen Lösung: die vorgeschriebene H1
--- (`config.headline_format` zentral über `render.headline`, genau wie
--- `plan.lua` sie für jede Blueprint-Datei schreibt) plus der Rumpf aus
--- `templates/Solution.md`.
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

--- Legt `Solution/Solution.md` an — und nur, wenn es noch gar keine Lösung
--- gibt (auch keine in einer Altlage): eine bestehende Datei wird nie
--- überschrieben, dieselbe Regel wie bei jedem Blueprint-Knoten
--- (`overwrite = false`).
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

-- ── Suche (Heuristik, keine KI) ──────────────────────────────────────────

--- Ein Begriff aus `## Schlagworte` zählt so oft extra — dieselbe Mechanik
--- wie `similar.lua`s TITLE_BOOST (Zusatzzählungen in derselben tf-Tabelle,
--- kein zweiter Vektor), und aus demselben Grund: die Schlagworte sind das,
--- was jemand bewusst als "darum ging es hier" hingeschrieben hat, der
--- Fließtext enthält auch Fehlversuche und Zitate.
local KEYWORD_BOOST = 3
local TITLE_BOOST = 2

--- Kommt die Anfrage als ZUSAMMENHÄNGENDE Zeichenkette vor ("unmapped
--- control"), ist das ein stärkeres Signal als dieselben Wörter verstreut.
--- Multiplikator statt fixem Bonus, damit ein Phrasentreffer in einem sonst
--- schwachen Dokument nicht an einem inhaltlich besseren vorbeizieht.
local PHRASE_BOOST = 1.5

---@class Lib.Case.SolutionHit
---@field doc Lib.Case.SolutionDoc
---@field score number    Nur zum Sortieren vergleichbar, keine Prozentangabe (s. u.).
---@field terms string[]  Tatsächlich getroffene Suchbegriffe, stärkster zuerst.
---@field matched integer
---@field wanted integer  Auswertbare Begriffe in der Anfrage.
---@field phrase boolean  Anfrage kam wörtlich als Zeichenkette vor.

--- Termzählungen eines Dokuments, inklusive Feldgewichtung.
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

--- Lösungen zu einer Anfrage, absteigend nach Übereinstimmung.
---
--- Bewusst KEINE Prozentzahl wie bei `:Case similar`: dort stehen sich zwei
--- Dokumente derselben Art gegenüber (Kosinus zweier Vektoren, 0..1 ist
--- echt), hier eine dreiwortige Anfrage gegen ein Dokument — jede Normierung
--- darauf wäre erfundene Genauigkeit. Stattdessen zeigen `matched`/`wanted`
--- und die Trefferbegriffe, WARUM etwas oben steht; dieselbe Ehrlichkeit,
--- die `:Case similar` mit seiner Termliste verfolgt.
---
--- Ohne Anfrage: jede Lösung, in Registry-Reihenfolge und mit `score = 0` —
--- das Filtern übernimmt dann der Picker.
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

  -- Anfrage ohne auswertbaren Begriff (zu kurz, reines Stoppwort, "1234"):
  -- reine Teilstringsuche, statt eine leere Liste zu liefern, die aussähe,
  -- als gäbe es nichts.
  if #q_tokens == 0 then
    local hits = {}
    for _, doc in ipairs(docs) do
      if doc.text:lower():find(needle, 1, true) then
        hits[#hits + 1] = { doc = doc, score = 1, terms = { query }, matched = 1, wanted = 1, phrase = true }
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
        -- Sublineares tf, idf über genau diesen Korpus: ein Wort, das in
        -- JEDER Lösung steht ("tosca"), trägt fast nichts bei.
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
