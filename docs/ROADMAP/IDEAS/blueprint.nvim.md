# `blueprint.nvim` — Konzept

> Arbeitstitel. Alternativen: `patterns.nvim`, `forge.nvim`, `codebook.nvim`
> (siehe [Offene Fragen](#offene-fragen)). `snippets.nvim` bewusst **nicht** —
> das Plugin ist kein LuaSnip-Konkurrent, siehe [Abgrenzung](#abgrenzung-zu-luasnip--vimsnippet).

## Table of content

- [Problem](#problem)
- [Idee in einem Satz](#idee-in-einem-satz)
- [Bewertung: sinnvoll? umsetzbar?](#bewertung-sinnvoll-umsetzbar)
- [Eigenes Plugin oder nvim-Config?](#eigenes-plugin-oder-nvim-config)
- [Abgrenzung zu LuaSnip / vim.snippet](#abgrenzung-zu-luasnip--vimsnippet)
- [Bedienung](#bedienung)
  - [Usercommand](#usercommand)
  - [Ablauf](#ablauf)
  - [Insert-Modi](#insert-modi)
- [Datenmodell: die Template-Bibliothek](#datenmodell-die-template-bibliothek)
  - [Verzeichnisstruktur](#verzeichnisstruktur)
  - [`meta.lua` — Schema](#metalua--schema)
  - [Lite-Form: Einzeldatei mit Front-Matter](#lite-form-einzeldatei-mit-front-matter)
  - [Good/Bad-Paare](#goodbad-paare)
  - [Sources und Präzedenz](#sources-und-präzedenz)
- [Architektur-Skizze](#architektur-skizze)
  - [Modulbaum](#modulbaum)
  - [Index und Cache](#index-und-cache)
  - [Insert-Pipeline](#insert-pipeline)
  - [Picker-Schicht](#picker-schicht)
- [Wiederverwendung: `lib.nvim` und eigene Plugins](#wiederverwendung-libnvim-und-eigene-plugins)
- [Feature-Brainstorm](#feature-brainstorm)
  - [Kern (sollte rein)](#kern-sollte-rein)
  - [Stark, aber Phase 2+](#stark-aber-phase-2)
  - [Spielwiese / später prüfen](#spielwiese--später-prüfen)
- [Die Regel-Dokumente als Quelle](#die-regel-dokumente-als-quelle)
- [Phasen](#phasen)
- [Checklisten-Abgleich (NEW_PROJECT)](#checklisten-abgleich-new_project)
- [Risiken / Komplexitätstreiber](#risiken--komplexitätstreiber)
- [Offene Fragen](#offene-fragen)
- [Literatur und Referenzen](#literatur-und-referenzen)

---

## Problem

Das Wissen aus [`Arch&Coding-Regeln.md`](../MATERIALS/Arch&Coding-Regeln.md),
[`Zentrale-Prinzipien.md`](../MATERIALS/Zentrale-Prinzipien.md) und
[`Checklist.md`](../MATERIALS/Checklist.md) liegt als Prosa in Markdown-Dateien.
Beim Codieren ist es damit **nicht abrufbar**: Wer mitten in einer Funktion
denkt „ich brauche jetzt einen Aggregator" oder „wie war die allokationsfreie
Schleifenvariante nochmal", müsste die Datei öffnen, scrollen, den Codeblock
suchen, kopieren, einrücken. Das passiert in der Praxis nicht — das Wissen
verpufft, und es wird die Variante geschrieben, die gerade im Kopf ist.

Dasselbe gilt für selbst gebaute, wiederkehrende Bausteine (eigene Klassen,
Modul-Skelette, `@types`-Dateien, Health-Checks): sie werden aus einem alten
Repo zusammengesucht statt abgerufen.

## Idee in einem Satz

Ein Neovim-Plugin, das eine **dateisystembasierte, sprachsortierte Bibliothek
aus Code-Templates, Design-Patterns und Performance-Idiomen** über einen Picker
durchsuchbar macht und den gewählten Baustein — inkl. Beschreibung (de/en),
Keywords und Rückverweis auf die Regel — direkt an der Cursorposition einfügt.

## Bewertung: sinnvoll? umsetzbar?

**Sinnvoll: ja, mit einer Einschränkung.** Der Nutzen steht und fällt mit der
Trefferquote beim *Suchen*. Eine Bibliothek mit 200 Einträgen, in der man den
richtigen nicht findet, ist wertloser als 20 gut verschlagwortete. Deshalb sind
`keywords`, `tags` und der Regel-Rückverweis kein Beiwerk, sondern das
Kernfeature — und deshalb ist [`:Blueprint new`](#kern-sollte-rein) (Template
aus Selektion anlegen) so wichtig: die Bibliothek muss beim Arbeiten *nebenbei*
wachsen, sonst wächst sie nie.

Zweite Einschränkung: die Grenze zu LuaSnip ist real, aber sauber ziehbar
(siehe [Abgrenzung](#abgrenzung-zu-luasnip--vimsnippet)).

**Umsetzbar: ja, unkritisch.** Alle Bausteine existieren:

| Baustein | Woher |
| --- | --- |
| Verzeichnis-Scan, mtime | `vim.uv.fs_scandir` / `lib.nvim.cross.fs` |
| Index-Cache auf Platte | `lib.nvim.nvim.cache.disk` + `lib.nvim.lua.json` |
| Compound-Usercmd + Completion | `lib.nvim.bindings.usercmd.composer` |
| Picker (telescope/fzf/snacks) | `pickers.nvim` → `pickers.engines` |
| Fallback-Auswahl | `lib.nvim.ui.kit.select` (hover_select) |
| Tabstops beim Einfügen | `vim.snippet.expand` (nvim ≥ 0.10), sonst Plain-Insert |
| Notify, Map, Autocmd | `lib.nvim` |

Kein externes Tooling, kein Netz, kein Parser. Das MVP ist realistisch ein
Wochenend-Projekt; der Aufwand liegt danach im **Befüllen** der Bibliothek —
das ist der eigentliche Kostenpunkt, nicht der Code.

## Eigenes Plugin oder nvim-Config?

**Eigenes Plugin** — `blueprint.nvim`. Gründe:

1. Der Nutzen ist maschinenübergreifend (Job/privat) und nicht an diese
   Config gebunden.
2. Es hat ein `:checkhealth`-, Config-, Bindings- und Doku-Bedürfnis, das die
   Config-Module nicht sauber abbilden.
3. Es passt in die bestehende Plugin-Familie und soll `pickers.nvim` als Engine
   nutzen — plugin-zu-plugin, nicht config-zu-plugin.

**Wichtig — Trennung von Code und Inhalt:** Das Plugin liefert nur die
Mechanik plus eine kleine Seed-Bibliothek. Die *eigenen* Templates leben im
`Notes`-Repo (z. B. `C:\repos\Notes\MyNotes\Templates\`) und werden per
`sources` eingebunden. Damit synchronisiert sich die Bibliothek über Git
zwischen Rechnern, ohne dass das Plugin-Repo mit persönlichem Material
verschmutzt.

Config-seitig bleibt nur die Spec:

```lua
{
  "StefanBartl/blueprint.nvim",
  dependencies = { "StefanBartl/lib.nvim" },
  cmd = { "Blueprint" },
  opts = {
    sources  = { vim.env.NOTES_DIR .. "/MyNotes/Templates" },
    doc_lang = "de",
  },
}
```

## Abgrenzung zu LuaSnip / vim.snippet

| | LuaSnip | `blueprint.nvim` |
| --- | --- | --- |
| Auslöser | Tippen eines Triggers, im Insert-Mode | bewusster Aufruf, Suche über Beschreibung |
| Einheit | kurzes Fragment (`fn`, `if`) | ganzer Baustein: Pattern, Modul, Idiom |
| Auswahl | Trigger muss bekannt sein | Fuzzy über Titel, Keywords, Body |
| Metadaten | keine | Beschreibung de/en, Refs, Komplexität, Regel-Link |
| Lerneffekt | keiner | Preview erklärt, *warum* so |

Kurz: LuaSnip beschleunigt **Tippen**, `blueprint.nvim` beschleunigt
**Erinnern**. Sie beißen sich nicht — `vim.snippet.expand` wird sogar als
Einfüge-Backend genutzt, damit Tabstops funktionieren.

## Bedienung

### Usercommand

Ein Compound-Command nach der Hausregel, gebaut mit
`lib.nvim.bindings.usercmd.composer` (Completion auf allen Ebenen):

```
:Blueprint [lang] [category] [action]

:Blueprint                    -- Sprache = Filetype des Buffers, sonst Prompt
:Blueprint lua                -- alle Lua-Templates
:Blueprint lua patterns       -- nur Kategorie
:Blueprint all                -- sprachübergreifend, mit Sprach-Badge je Eintrag
:Blueprint js perf            -- Kategorie-Alias
:Blueprint new [lang] [cat]   -- Template aus Selektion/Buffer anlegen
:Blueprint grep <text>        -- Volltext über alle Template-Bodies
:Blueprint reload             -- Index neu aufbauen
:Blueprint check              -- Bibliothek validieren (Schema, Links, Luacheck)
```

Range-Unterstützung (`v`, `V`, `<C-v>`) ist Pflicht laut
[NEW_PROJECT](../MATERIALS/NEW_Project.md) und hier auch inhaltlich sinnvoll:

- `:'<,'>Blueprint …` → gewählte Selektion wird **ersetzt** statt eingefügt,
  und steht dem Template zusätzlich als `${SELECTION}` zur Verfügung
  (z. B. „umschließe das mit `pcall`", „mach daraus eine memoisierte Funktion").
- `:'<,'>Blueprint new …` → Selektion wird zum Body des neuen Templates.

Keymap-Vorschlag (deaktivierbar, which-key-fähig): `<leader>bb` Picker,
`<leader>bn` neu aus Selektion, `<leader>bl` letztes Template erneut einfügen.

### Ablauf

1. Codieren, Gedanke: „ich brauche einen Aggregator".
2. `:Blueprint lua` (oder `<leader>bb`).
3. Picker öffnet, Liste zeigt `title` + `short` + Kategorie + Tags.
   Preview-Fenster zeigt den Code (mit Syntax-Highlighting des Ziel-Filetypes)
   und darunter die Langbeschreibung in der eingestellten Sprache.
4. Auswahl mit `<CR>` → Insert an der Cursorposition, Einrückung angepasst,
   Cursor springt auf den ersten Tabstop.
5. Optional `<C-y>` statt `<CR>` → nur in die Zwischenablage; `<C-o>` → in
   einen Scratch-Buffer; `<C-e>` → Template-Datei zum Bearbeiten öffnen.

### Insert-Modi

Konfigurierbar und im Picker per Alternativ-Mapping erreichbar:
`cursor` (Default) · `line_below` · `replace_selection` · `new_file`
· `register` · `float_preview` (erst zeigen, dann bestätigen).

## Datenmodell: die Template-Bibliothek

### Verzeichnisstruktur

Erste Ebene = **Sprache** (Filetype-Name, damit Auto-Erkennung trivial ist),
zweite Ebene = **Kategorie** (frei, wird per Scan entdeckt — keine Registry,
die gepflegt werden müsste), darunter je Template ein Ordner:

```
Templates/
  lua/
    patterns/
      aggregator/
        template.lua        -- der Body
        meta.lua            -- Beschreibung, Keywords, Refs
        bad.lua             -- optional: Anti-Pattern zum Vergleich
        variants/
          async.lua         -- optional: Varianten, im Picker als Untereinträge
      observer/
    perf/
      loop-no-alloc/
      string-build-table/
    module/
      nvim-plugin-skeleton/
      types-file/
    idioms/
  js/
    patterns/
    perf/
  ts/
  sh/
  misc/                     -- nicht-Code: Commit-Message-Vorlagen, ADR, PR-Text
    adr/
    commit-conventional/
```

Regeln, die die Erweiterbarkeit sichern:

- **Neuer Ordner mit `template.*` = neues Template.** Kein Registrieren, kein
  `init.lua` anfassen. `:Blueprint reload` oder automatischer mtime-Check
  nimmt ihn auf.
- Kategorien sind **rekursiv**: `perf/loops/unrolled/` wird zu Kategorie
  `perf/loops`. Beliebige Tiefe.
- Fehlt `meta.lua`, funktioniert der Eintrag trotzdem: Titel = Ordnername,
  Beschreibung leer. Erst der Fuzzy-Wert leidet — nie die Funktion.
  (Bewusst: die Hürde für „schnell mal ablegen" muss null sein.)
- `misc/` liegt auf Sprachebene, weil es sprachneutral ist.

### `meta.lua` — Schema

Lua statt JSON/YAML: nativ ladbar (`loadfile`), typisierbar per LuaLS-Annotation,
und man kann Werte berechnen. Alle Felder optional.

```lua
---@type Blueprint.Meta
return {
  title    = { de = "Aggregator", en = "Aggregator" },
  short    = { de = "Sammelt Teilergebnisse allokationsfrei in einem Akkumulator",
               en = "Folds partial results into one accumulator, allocation-free" },
  long     = { de = [[Ausführlich …]], en = [[Long form …]] },

  keywords = { "aggregate", "fold", "reduce", "accumulate", "sammeln" },
  tags     = { "pattern", "collection", "hotpath" },

  complexity = "O(n) Zeit, O(1) Zusatzspeicher",
  requires   = { "nvim>=0.10" },
  scope      = "statement",          -- statement | function | module | file
  variants   = { "async" },

  -- Rückverweis auf die Hausregel, aus der das Template stammt:
  rule = {
    file    = "Arch&Coding-Regeln.md",
    anchor  = "#8-performance--speicher",
    quote   = { de = "Keine Tabellen-Allokation im Hot-Path." },
  },

  refs = {
    { title = "Programming in Lua, Ch. 11", url = "https://www.lua.org/pil/11.html" },
  },

  -- Einfüge-Verhalten überschreiben:
  insert = { mode = "cursor", snippet = true, reindent = true },
}
```

Der `rule`-Rückverweis ist mehr als Deko: er ermöglicht
`:Blueprint rules` (Browsen nach Regel statt nach Kategorie) und einen
`gd`-artigen Sprung aus der Preview in die Regel-Datei — Template und Begründung
bleiben verbunden.

### Lite-Form: Einzeldatei mit Front-Matter

Für Ein-Zeiler ist ein Ordner mit zwei Dateien zu viel Zeremonie. Deshalb gilt
zusätzlich: **eine lose Datei im Kategorie-Ordner ist auch ein Template**, mit
optionalem Front-Matter im Kommentar-Stil der Sprache:

```lua
--- @bp title: Weak-Table-Cache
--- @bp keywords: cache, weak, memo, gc
--- @bp short: Cache, dessen Einträge der GC freigeben darf
local cache = setmetatable({}, { __mode = "k" })
```

Der Parser liest nur führende Kommentarzeilen mit `@bp ` — billig, kein
YAML-Parser nötig, funktioniert in jeder Sprache mit Zeilenkommentaren.
`:Blueprint promote` wandelt eine Lite-Datei in einen vollen Ordner um.

### Good/Bad-Paare

Die Regel-Dokumente arbeiten durchgehend mit „Don't / Do" (siehe
`Arch&Coding-Regeln.md → Zusammengefasst: Do & Don't`). Das bildet die
Bibliothek 1:1 ab: liegt neben `template.lua` eine `bad.lua`, zeigt die Preview
beide im Diff-Layout — eingefügt wird immer nur die gute Variante. Für die
Diff-Darstellung ist `lib.nvim.lua.diff` bzw. `diff.nvim` da.

### Sources und Präzedenz

```lua
sources = {
  -- implizit: die mit dem Plugin gelieferte Seed-Bibliothek (niedrigste Prio)
  vim.fn.stdpath("config") .. "/templates",     -- config-lokal
  vim.env.NOTES_DIR .. "/MyNotes/Templates",    -- persönlich, git-synchron
  "//share/team/templates",                     -- optional, read-only
}
```

Gleiche ID in mehreren Sources → die **spätere** Source gewinnt (Overlay), die
überschriebene bleibt über `:Blueprint … --all-sources` erreichbar. Damit kann
ein Team-Template lokal angepasst werden, ohne es zu forken.

## Architektur-Skizze

### Modulbaum

Nach [NEW_PROJECT](../MATERIALS/NEW_Project.md):

```
blueprint.nvim/
  lua/blueprint/
    init.lua              -- setup()
    config/
      init.lua
      DEFAULTS.lua
    bindings/
      keymaps.lua  usrcmds.lua  autocmds.lua  whichkey.lua
    library/
      scan.lua            -- fs-Walk über sources
      entry.lua           -- Entry-Objekt, lazy body/long-description
      meta.lua            -- meta.lua laden + Front-Matter-Parser
      index.lua           -- Index bauen, cachen, invalidieren
      sources/
        fs.lua            -- Ordner/Lite-Dateien
        markdown.lua      -- Codeblöcke aus Regel-Docs (Phase 2)
    query/
      filter.lua          -- lang/category/tags
      score.lua           -- Fuzzy + Frecency
    insert/
      resolve.lua         -- Variablen ${MODULE} etc.
      indent.lua          -- Einrückung an Zielzeile anpassen
      expand.lua          -- vim.snippet vs. plain
      modes.lua           -- cursor/line_below/replace/register/…
    ui/
      picker.lua          -- pickers.nvim-Engine + Fallback
      preview.lua
      author.lua          -- :Blueprint new
    @types/init.lua
    health.lua
  doc/blueprint.txt
  docs/{ROADMAP,BINDINGS}.md
  templates/               -- Seed-Bibliothek
```

### Index und Cache

Direkt aus [Zentrale-Prinzipien](../MATERIALS/Zentrale-Prinzipien.md) §7 und §2:

- Der Index enthält **nur** was die Liste braucht: `id, lang, category, title,
  short, keywords, tags, path, mtime`. Body und Langbeschreibung werden erst
  bei Preview/Insert gelesen (`library.entry` lädt lazy).
- Persistenz als JSON in `stdpath("cache")/blueprint/index.json`
  (`lib.nvim.nvim.cache.disk`).
- Invalidierung über die höchste `mtime` je Source-Verzeichnis, geprüft beim
  ersten Aufruf pro Session — nicht bei jedem Event. Preis: ein neu angelegtes
  Template braucht ggf. ein `:Blueprint reload`. Optional (default aus) ein
  `vim.uv.fs_event`-Watcher auf die Sources.
- Der Scan läuft asynchron über `vim.uv.fs_scandir`, nie beim Startup: das
  Plugin lädt per `cmd = { "Blueprint" }`.

### Insert-Pipeline

```
Entry → resolve(vars) → indent(target_line) → expand(snippet?) → mode(cursor|…)
```

1. **resolve** ersetzt freie Variablen: `${MODULE}`, `${FILENAME}`, `${DATE}`,
   `${AUTHOR}`, `${SELECTION}`, `${CWD}`, `${GIT_BRANCH}`. Unbekannte
   `${NAME}`-Vorkommen werden einmalig abgefragt (`lib.nvim.ui.kit.select` /
   `input`) und im gesamten Body konsistent ersetzt.
2. **indent** normalisiert auf `shiftwidth`/`expandtab` des Zielbuffers und
   hängt die Einrückung der Cursorzeile vor. Template-Dateien werden immer mit
   zwei Leerzeichen und ohne Basis-Einrückung gespeichert.
3. **expand**: bei `snippet = true` → `vim.snippet.expand` (Tabstops `$1`,
   `${1:name}`, `$0`). **Achtung:** dann müssen literale `$` im Body escaped
   sein. Default ist deshalb `snippet = false`, Tabstops sind Opt-in pro
   Template — das verhindert die häufigste Fehlerquelle.
4. **mode** schreibt via `nvim_buf_set_text` (Cursor) oder `nvim_buf_set_lines`.

### Picker-Schicht

`pickers.nvim` bringt bereits die Engine-Erkennung
(`pickers.engines.load()` → telescope | fzf | snacks) und ein generisches
`M.pick_item{ items, prompt, on_select }`. Das reicht für das MVP.

Für die Preview fehlt dort ein Previewer-Hook. Statt in `blueprint.nvim` eine
zweite Engine-Abstraktion zu bauen, wird `pick_item` in `pickers.nvim` um
optionale Felder erweitert:

```lua
pick_item{
  items, prompt, on_select,
  preview = function(item) return lines, filetype end,   -- neu
  actions = { ["<C-y>"] = fn, ["<C-e>"] = fn },          -- neu
}
```

Das entspricht der Hausregel „Funktionen, die für andere Plugins interessant
sind, nach oben transferieren" — und `pickers.nvim` profitiert direkt mit.
Fallback ohne Engine: `lib.nvim.ui.kit.select` (hover_select) plus
Float-Preview aus `lib.nvim.nvim.ui.kit`.

## Wiederverwendung: `lib.nvim` und eigene Plugins

| Bedarf | Modul |
| --- | --- |
| Meldungen | `lib.nvim.nvim.notify` (nie `vim.notify`/`print`) |
| Keymaps/Usercmds/Autocmds | `lib.nvim.nvim.map` · `.usercmd` · `.autocmd` · `.augroup` |
| Compound-Command + Completion | `lib.nvim.bindings.usercmd.composer` |
| Pfade, Trennzeichen, Öffnen | `lib.nvim.nvim.cross` · `.fs` |
| Auswahl-UI ohne Picker-Engine | `lib.nvim.ui.kit.select` (hover_select) |
| Lazy-Require | `lib.nvim.nvim.require` · `lib.nvim.lua.lazy` |
| Memoization / LRU | `lib.nvim.lua.memo` (Scoring, geparste Metas) |
| Index-Persistenz | `lib.nvim.nvim.cache.disk` + `lib.nvim.lua.json` |
| Strings/Tables-Helfer | `lib.nvim.lua.strings` · `.tables` |
| Git-Infos für `${GIT_BRANCH}` | `lib.nvim.nvim.git` |

Sinnvolle Anschlüsse an die eigenen Plugins — alle **optional**, per
Nil-Check geladen:

- **`pickers.nvim`** — Picker-Engine (siehe oben). Die einzige echte
  Soft-Dependency.
- **`sandbox.nvim`** — `:Blueprint try`: Template in einen Scratch/Sandbox
  ausführen statt einfügen. „Funktioniert das überhaupt?" vor dem Commit.
- **`runtime-analysis.nvim`** — `:Blueprint bench`: zwei Varianten (bzw.
  `template.lua` vs. `bad.lua`) gegeneinander messen. Aus einer Behauptung im
  Regel-Dokument wird eine Zahl auf dieser Maschine.
- **`documentation.nvim`** — Templates für `@module`/`@brief`-Header und
  `@types`-Dateien; `:DocMap` prüft die Seed-Bibliothek mit.
- **`recommender.nvim`** — nach dem Einfügen die Alias-Empfehlungen auf den
  neuen Block laufen lassen.
- **`diff.nvim`** — Good/Bad-Preview.
- **`markdown.nvim` / `mdview.nvim`** — Rendering der Langbeschreibung.
- **`insights.nvim`** — umgekehrte Richtung: aus einer Struktur-Analyse heraus
  passende Templates vorschlagen (spekulativ, Phase 3+).

## Feature-Brainstorm

### Kern (sollte rein)

- **`:Blueprint new` — Template aus Selektion.** Selektion markieren, Sprache
  und Kategorie wählen, ID eintippen → Ordner wird angelegt, `template.*` mit
  dem Code gefüllt, `meta.lua`-Gerüst erzeugt und zum Ausfüllen geöffnet.
  Ohne diesen Befehl bleibt die Bibliothek leer. Wichtigstes Einzelfeature.
- **Frecency-Ranking.** Häufig genutzte Templates nach oben
  (`lib.nvim.nvim.store`). `pickers.nvim` hat bereits eine Frecency-Mechanik,
  die als Vorbild oder direkt als Modul dient.
- **Sprach-Aliase.** `js` → `javascript`, `ts`/`tsx` → `typescript`,
  `sh`/`bash`/`zsh` → gemeinsame Menge. Konfigurierbare Map, damit
  `:Blueprint js` und ein `javascriptreact`-Buffer dieselbe Liste sehen.
- **`all`-Modus mit Sprach-Badge**, damit sprachübergreifende Patterns
  („so sieht Aggregator in JS aus") sichtbar bleiben.
- **Zweisprachigkeit.** `doc_lang = "de" | "en" | "both"`, Fallback auf die
  jeweils andere Sprache statt Leerfeld.
- **`:Blueprint check`.** Validiert Meta-Schema, doppelte IDs, tote
  `rule`/`refs`-Links, und lässt Lua-Templates durch `luacheck`/LuaLS laufen.
  Eine Bibliothek mit kaputten Templates ist schlimmer als keine.
- **`:checkhealth blueprint`.** Sources vorhanden/lesbar, Engine gefunden,
  `vim.snippet` verfügbar, Cache beschreibbar, Anzahl Einträge je Sprache.
- **Letztes Template erneut einfügen** (`:Blueprint last`, `<leader>bl`).

### Stark, aber Phase 2+

- **Markdown-Source-Adapter** — siehe eigener Abschnitt unten. Macht die
  vorhandenen Regel-Dokumente ohne Migration zur Bibliothek.
- **Volltextsuche über Bodies** (`:Blueprint grep`) — wenn man den Namen nicht
  weiß, aber weiß, dass `setmetatable` drin vorkam.
- **Komposition.** Mehrere Templates im Picker markieren (`<Tab>`) und in
  Reihenfolge einfügen — Modul-Skelett + Health + Types in einem Rutsch.
- **Projekt-Templates / Scaffolding.** `scope = "file"`-Einträge mit
  Ziel-Pfad-Muster: `:Blueprint scaffold nvim-plugin` legt die komplette
  Struktur aus NEW_PROJECT an. Das ist die logische Endstufe und macht die
  Checkliste ausführbar.
- **Anti-Pattern-Erkennung im Buffer.** Autocmd (default aus) auf `BufWritePost`,
  das bekannte Anti-Patterns aus der Bibliothek (`bad.lua` als Suchmuster)
  markiert und das Gegenstück vorschlägt. Grenze zu Linting beachten — nur
  Vorschlag, keine Diagnose-Flut.
- **Kontext-Vorschlag.** Beim Öffnen ohne Query die Templates zuerst zeigen,
  die zum aktuellen Kontext passen (Filetype, umgebender Scope: in einer
  `for`-Schleife → `perf/loops` nach oben).
- **Snapshot/Export.** `:Blueprint export` schreibt die Bibliothek als eine
  Markdown-Datei (Cheatsheet zum Ausdrucken/Teilen), `pdfport.nvim` macht ein
  PDF daraus.

### Spielwiese / später prüfen

- **Lernmodus.** Täglich ein zufälliges Template als „Karte des Tages" beim
  Start — Spaced Repetition für die eigenen Regeln. Passt konzeptionell zum
  Lernmodus aus [`polyglot-cmd.nvim`](./polyglot-cmd.nvim.md); ggf. dort
  gemeinsam lösen statt doppelt bauen.
- **Nutzungsstatistik.** Welche Templates werden nie benutzt → Kandidaten zum
  Löschen. Rein lokal.
- **KI-Runde.** Template + Zielkontext an ein Modell geben und anpassen lassen
  (Namen, Typen). Analog zum `:Case ki`-Roundtrip in `casedesk`. Bewusst
  optional und default aus — der Wert des Plugins ist gerade die
  *deterministische*, geprüfte Vorlage.
- **Template-Vererbung.** `extends = "…"` in `meta.lua` für Varianten mit
  minimalen Unterschieden. Erst bauen, wenn die Duplikation wirklich weh tut.

## Die Regel-Dokumente als Quelle

`Arch&Coding-Regeln.md` (1105 Zeilen), `Checklist.md` (776) und
`Zentrale-Prinzipien.md` enthalten bereits Dutzende fertiger Codeblöcke —
Do/Don't-Paare, Bitoperationen, Sortier- und Suchalgorithmen, `types`-Datei-Demo.
Diese **nicht abtippen**. Stattdessen ein Source-Adapter
`library/sources/markdown.lua`:

- Er läuft über konfigurierte Markdown-Dateien, nimmt jeden Fenced-Code-Block
  mit Sprach-Tag und leitet ab: Titel = nächste Überschrift darüber,
  `short` = erster Satz des Absatzes davor, Kategorie = übergeordnete
  H2-Sektion, `rule` = Datei + Anker.
- Feinsteuerung optional per HTML-Kommentar direkt über dem Block:
  `<!-- bp: id=weak-cache, keywords=cache,gc, skip -->`. Ohne Annotation
  funktioniert es trotzdem, nur ungenauer.
- Aufeinanderfolgende Blöcke mit „Schlecht"/„Gut"-Überschrift werden
  automatisch zum [Good/Bad-Paar](#goodbad-paare) verknüpft.
- `:Blueprint eject` überführt einen so gefundenen Block in einen echten
  Ordner-Eintrag, sobald er gepflegt werden soll.

Effekt: Die Bibliothek startet nicht bei null, und die Regel-Dokumente bleiben
die **einzige Quelle der Wahrheit** — keine Kopie, die auseinanderläuft.

## Phasen

**Phase 0 — MVP (lauffähig, nützlich)**
Repo nach NEW_PROJECT anlegen · fs-Scan + In-Memory-Index · `meta.lua`-Loader ·
`:Blueprint [lang]` mit `pickers.pick_item` bzw. hover_select-Fallback ·
Insert an Cursor mit Reindent · 15–20 Seed-Templates für Lua ·
`:checkhealth` · README/vimdoc/BINDINGS.

**Phase 1 — Alltagstauglich**
Compound-Command mit voller Completion (`composer`) · Kategorie- und
Tag-Filter · Preview (Previewer-Hook in `pickers.nvim` ergänzen) · Range/Selektion ·
`${VAR}`-Resolver + `vim.snippet` · **`:Blueprint new`** · Disk-Index mit
mtime-Invalidierung · Frecency · Insert-Modi · which-key.

**Phase 2 — Bibliothek skaliert**
Markdown-Source-Adapter über die Regel-Dokumente · Good/Bad-Preview ·
`:Blueprint grep` · `:Blueprint check` · Lite-Front-Matter · `promote`/`eject` ·
JS/TS/Shell-Seeds.

**Phase 3 — Ökosystem**
`sandbox.nvim`-Try · `runtime-analysis.nvim`-Bench · Scaffolding (`scope=file`) ·
Komposition · Export/PDF · Kontext-Vorschlag.

## Checklisten-Abgleich (NEW_PROJECT)

- [ ] Repo `blueprint.nvim`, Default-Branch `main`, `.luarc.json`, keine Lizenzdatei
- [ ] `gh repo edit --description … --add-topic "neovim,lua,plugin,templates,snippets"`
- [ ] Struktur `config/DEFAULTS.lua`, `bindings/{keymaps,usrcmds,autocmds}`, `@types` je Ebene
- [ ] `health.lua` — Sources, Engine, `vim.snippet`, Cache, Eintragszahl
- [ ] `README.md` (en, ASCII-Art, Badges, TOC) + `>`-Absatz auf `pickers.nvim` als Schwesterplugin
- [ ] `doc/blueprint.txt`, `docs/ROADMAP.md`, `docs/BINDINGS.md`
- [ ] `lib.nvim` als Dependency, `documentation.nvim` als Dev-Dependency, `scripts/gen_map.lua` + `--check` in CI
- [ ] Compound-Usercmd via `lib.nvim.bindings.usercmd.composer`, Range `v`/`V`/`<C-v>` implementiert **und getestet**
- [ ] Keymaps modifizier- und deaktivierbar, which-key-fähig
- [ ] Cross-Plattform von Anfang an (`lib.nvim.cross` für Pfade — Windows-Backslashes in `sources`!)
- [ ] Bindings in die zentrale `docs/NOTES/PersonelPlugins/BINDINGS`-Sammlung eintragen
- [ ] Nicht passende Ideen nach `docs/ROADMAP.md` statt in den Code

## Risiken / Komplexitätstreiber

| Risiko | Gegenmaßnahme |
| --- | --- |
| **Bibliothek bleibt leer** — größtes Risiko, nicht technisch | `:Blueprint new` früh (Phase 1), Markdown-Adapter für Sofort-Bestand, Lite-Form ohne Zeremonie |
| **Nicht wiederfindbar** bei 100+ Einträgen | Keywords als Pflichtfeld in `check`, Frecency, Volltext-Grep, Kategorie-Filter |
| `$`-Kollision zwischen Lua-Code und Snippet-Tabstops | `snippet = false` als Default, Opt-in pro Template, `check` warnt bei unescaped `$` in Snippet-Templates |
| Einrückung/`expandtab`-Mismatch beim Einfügen | Templates ohne Basis-Einrückung speichern, Reindent-Modul mit Tests |
| Index veraltet, neues Template unsichtbar | mtime-Check pro Session, `:Blueprint reload`, optionaler `fs_event`-Watcher |
| Startup-Last durch Scan | `cmd`-lazy, asynchroner Scan, Disk-Index; nichts läuft bei `BufEnter` |
| Doppelte IDs über mehrere Sources | Definierte Präzedenz (spätere Source gewinnt), `check` meldet Kollisionen |
| Scope-Creep Richtung LuaSnip / Linter / Scaffolder | Phasen einhalten; Scaffolding erst Phase 3, Anti-Pattern-Scan default aus |
| Windows-Pfade in `sources` | ausschließlich `lib.nvim.cross`/`fs`, nie manuelle Konkatenation |

## Offene Fragen

1. **Name.** `blueprint.nvim` (neutral, passt auch für Scaffolding) vs.
   `patterns.nvim` (zu eng?) vs. `codebook.nvim` (betont Nachschlagewerk).
   Kollisionen auf GitHub vorher prüfen.
2. **Meta-Format.** `meta.lua` (typisierbar, nativ) — oder doch `meta.md` mit
   Front-Matter, damit die Beschreibung auf GitHub direkt lesbar ist? Denkbar:
   `meta.lua` verpflichtend, `README.md` im Template-Ordner optional als
   Langbeschreibung.
3. **Ort der Bibliothek.** `Notes`-Repo (git-synchron, aber Notes wird groß)
   vs. eigenes Repo `templates` vs. `stdpath("config")/templates`.
4. **Kategorie-Taxonomie.** Fix vorgeben (`patterns`, `perf`, `module`,
   `idioms`, `misc`) oder komplett frei? Frei ist erweiterbarer, fix ist
   auffindbarer. Vorschlag: frei, aber `check` warnt bei Kategorien mit nur
   einem Eintrag.
5. **Previewer in `pickers.nvim`** erweitern (bevorzugt) oder in
   `blueprint.nvim` eine eigene, dünne Engine-Schicht halten?
6. **Braucht `misc/` wirklich Platz im MVP** oder erst, wenn ein konkreter
   Nicht-Code-Bedarf auftaucht?

## Literatur und Referenzen

- Eigene Regelwerke:
  [`Arch&Coding-Regeln.md`](../MATERIALS/Arch&Coding-Regeln.md) ·
  [`Zentrale-Prinzipien.md`](../MATERIALS/Zentrale-Prinzipien.md) ·
  [`Checklist.md`](../MATERIALS/Checklist.md) ·
  [`NEW_PROJECT.md`](../MATERIALS/NEW_Project.md) · `REVIEW.md` · `PERFORMANCE.md`
  (`C:\repos\WKDBooks\Development\wkdbook-Lua\Checklists\`)
- Eigene Plugins: [`lib.nvim`](https://github.com/StefanBartl/lib.nvim) ·
  [`pickers.nvim`](https://github.com/StefanBartl/pickers.nvim) ·
  [`documentation.nvim`](https://github.com/StefanBartl/documentation.nvim) ·
  [`sandbox.nvim`](https://github.com/StefanBartl/sandbox.nvim) ·
  [`runtime-analysis.nvim`](https://github.com/StefanBartl/runtime-analysis.nvim) ·
  [`recommender.nvim`](https://github.com/StefanBartl/recommender.nvim)
- Verwandtes eigenes Konzept: [`polyglot-cmd.nvim`](./polyglot-cmd.nvim.md)
  (Intent-zu-Syntax-Baukasten; gleiche Denkfigur, andere Domäne)
- Neovim: `:h vim.snippet` · `:h vim.uv` · `:h nvim_buf_set_text` ·
  `:h vim.filetype`
- Prior Art zum Abgrenzen: `L3MON4D3/LuaSnip`,
  `cvigilv/esqueleto.nvim` (File-Templates), `glepnir/template.nvim`,
  `rafamadriz/friendly-snippets`
- Gamma, Helm, Johnson, Vlissides: *Design Patterns* (1994) — Quelle für die
  Pattern-Kategorie
- Ierusalimschy: *Programming in Lua*, 4. Aufl. — Kap. 11 (Datenstrukturen),
  17 (Weak Tables, GC)
