# language.nvim — Spell-, Grammar- & Translate-Werkzeug für Neovim

## Table of content

  - [Context](#context)
  - [Verbindliche Vorgaben (aus den Coding-Regeln)](#verbindliche-vorgaben-aus-den-coding-regeln)
  - [Architektur](#architektur)
    - [Domäne 1: Spell & Grammar](#domne-1-spell-grammar)
    - [Domäne 2: Translate — **nativ, ohne Fremd-Plugin-Dependency**](#domne-2-translate-nativ-ohne-fremd-plugin-dependency)
    - [Gemeinsame Infrastruktur](#gemeinsame-infrastruktur)
    - [Scoping-Modell (Kern-Anforderung)](#scoping-modell-kern-anforderung)
    - [Asynchronität & Cancellation (Kern-Anforderung)](#asynchronitt-cancellation-kern-anforderung)
    - [Config-Defaults (Auszug)](#config-defaults-auszug)
  - [Modul-Layout (neues Repo `e:\repos\language.nvim`)](#modul-layout-neues-repo-ereposlanguagenvim)
  - [Wiederverwendung aus lib.nvim](#wiederverwendung-aus-libnvim)
  - [Erkenntnisse aus Fremd-Plugin-Analyse (was wir mitnehmen)](#erkenntnisse-aus-fremd-plugin-analyse-was-wir-mitnehmen)
  - [Extraktions- & Cleanup-Plan (nvim-Config)](#extraktions-cleanup-plan-nvim-config)
  - [Umsetzungs-Phasen](#umsetzungs-phasen)
  - [Verifikation (End-to-End)](#verifikation-end-to-end)

---

## Context

Beim Schreiben (Prosa, Markdown, Code-Kommentare) fehlt in Neovim ein zentraler
Ort, an dem man **alle** Rechtschreib-/Grammatikprobleme eines Buffers oder des
gesamten `cwd` auf einen Blick sieht und **direkt abarbeitet**. Nvims Bordmittel
(`]s`, `z=`, `zg`) sind rein cursor-lokal; externe Tools (typos, cspell, harper,
ltex) liefern zwar Diagnosen, aber jede mit eigener UI und ohne einheitlichen
„Durcharbeiten"-Workflow.

Parallel dazu lebt in der bestehenden nvim-Config bereits eine ausgereifte
**Spell-Session** (`config/trouble/spell/`, 726 Zeilen) und eine **Translate-
Orchestrierung** um das externe Plugin `uga-rosa/translate.nvim`
(`config/translate/`, inkl. des vom User als „sehr nützlich" hervorgehobenen
`:TranslateReplace`). Beide sind thematisch verwandt (Sprachwerkzeuge für Text)
und sollen zu **einem** eigenständigen Plugin verschmelzen: `language.nvim`
unter `e:\repos\language.nvim` (Repo wird vom User separat neu angelegt;
danach wird direkt implementiert).

Nach Fertigstellung werden `config/trouble/spell/**`, `config/translate/**`
sowie ihre Verdrahtung in `plugins/trouble.lua` (SpellChecker-Setup-Block) und
`plugins/workflow.lua` (translate.nvim-Spec + `require("config.translate")`)
**aus der nvim-Config entfernt** und durch eine einzige lazy.nvim-Spec für
`language.nvim` ersetzt.

**Kernentscheidungen (mit User geklärt):**
- Name: **`language.nvim`** (kein Namenskonflikt in der nvim-Plugin-Landschaft
  gefunden — `LanguageClient-neovim` und `detect-language.nvim` sind
  themennah, aber keine exakten Treffer). Kurze Einschätzung: der Name ist
  etwas generisch und könnte in Discovery-Kontexten mit LSP-„Language
  Client"-Tools verwechselt werden — funktional aber unproblematisch, da nur
  in deiner eigenen Config verwendet.
- Umfang: **Spell + Grammar + Translate**, alle als gleichberechtigte Domänen
  im selben Plugin (kein Unterbau von spelldesk, sondern von Anfang an so
  benannt und geschnitten).
- Kommandos: **zwei eigenständige Top-Level-Commands**, kein gemeinsames
  Dachkommando: `:Spellcheck [lang] [%|cwd|clear|refresh]` und
  `:Translate [lang] [flags]`. Beide ersetzen ihre jetzigen Pendants
  (`:SpellChecker`/`:TroubleSpell` bzw. `:TranslateReplace`) 1:1 in der
  Grundfunktion; alte Namen fallen weg (keine Alias-Pflicht laut User).
- Provider-Prinzip bleibt: mehrere austauschbare Quellen pro Domäne, User
  wählt in der Config, sinnvoller Default vorgegeben.

---

## Verbindliche Vorgaben (aus den Coding-Regeln)

- `lib.nvim` ist **Dependency** und wird konsequent wiederverwendet:
  `require("lib.nvim.notify").create("[language]")`, `lib.nvim.map`,
  `lib.nvim.usercmd`, `lib.nvim.autocmd` / `augroup`, `lib.nvim.ui.kit` (picker/
  menu/select/preview/confirm), `lib.nvim.fs.*`, `lib.nvim.git`,
  `lib.nvim.cross.*` (run/platform/fs), `lib.lua.memo`, `lib.lua.lazy`,
  `lib.lua.tables`, `lib.lua.strings`, `lib.nvim.progress`.
  Require-Pfad-Konvention wie in bestehenden Plugins: `require("lib.nvim.<mod>")`.
- **Ein Modul = eine Verantwortung**; interne Helfer lokal (forward declaration),
  reine Funktionen bevorzugt, kein globaler State (State explizit übergeben).
- **Sicherheit:** `pcall` um alle API-/Provider-/Backend-Zugriffe, Type-Guards
  vor `vim.api.nvim_*`, `nvim_buf_is_valid`/`nvim_win_is_valid`, keine stillen
  Fehler (`ok, err`-Rückgaben). `notify` nur in UI-Schichten, nicht im
  Low-Level-Code.
- **Performance:** Buffer-Scan **debounced** (`vim.uv` Timer) und **async** für
  cwd (externe CLI via `lib.cross.run` / `vim.system`; native cwd-Scan
  koroutinen-/chunk-basiert, nicht blockierend). Ergebnis-**Cache** pro
  `bufnr`+`changedtick` (memoisiert, invalidierbar). Kein Treesitter für simple
  Pattern; Treesitter nur zur `@spell`/`@nospell`-Regionsbestimmung (optional).
  Hot-Path-Tabellen mit `t[i]=v` + Inline-Reserve, `table.concat` statt `..`.
- **Annotationen:** jede Datei `@module/@brief/@description`; jedes
  Unterverzeichnis ein `/@types`-Ordner (`return {}`), Klassen/Aliase dort
  detailliert. Naming englisch, konsistent snake_case.
- **Doku (nvim-config-Regel):** deutsche `README.md` **und** englische
  `doc/language.txt` (`:help`) + `docs/ROADMAP/`.
- **Cross-Plattform:** Windows + POSIX (alle Pfad-/Prozessaufrufe über
  `lib.nvim.cross.*`).

---

## Architektur

Zwei Domänen (`spell` inkl. Grammar, `translate`) teilen sich Infrastruktur
(Config, Notify, lib.nvim-Nutzung, Command-Registrierungsmuster), sind aber
funktional unabhängig — je eigener Provider-Registry, eigenes Datenmodell,
eigener Command. Kein künstliches gemeinsames Dachkommando (User-Entscheidung).

---

### Domäne 1: Spell & Grammar

Datenfluss: `Provider(s) → normalisierte Issue-Liste → Store (Cache) → Panel-UI
→ Actions → Buffer-Edit / Dictionary / Ignore → Re-Scan`.

Übernimmt die bewährte Session-Logik aus `config/trouble/spell/init.lua`
(1:1 als Referenzimplementierung, nicht neu erfunden) und erweitert sie um
ein echtes Multi-Provider-Panel statt reinem Trouble/Quickfix-Fallback:

```
---@class LanguageSpellIssue
---@field bufnr    integer|nil
---@field path     string
---@field lnum     integer       -- 1-basiert
---@field col      integer       -- 1-basiert, Byte-Spalte
---@field end_col  integer       -- exklusiv
---@field word     string        -- betroffenes Wort (bzw. Subwort bei CamelCase-Split)
---@field kind     "spell"|"grammar"|"style"|"rare"|"caps"
---@field source   "native"|"typos"|"codespell"|"cspell"|"harper"|"ltex"
---@field message  string|nil    -- Provider-Erklärung (Grammatik)
---@field rule     string|nil    -- Regel-ID (harper/ltex → „Regel abschalten")
---@field suggestions string[]|nil
---@field occurrences integer|nil -- Anzahl gleicher Fehler im Scope (Dedupe, aus vim-SpellCheck)
```

**Provider-Interface** (Strategy/Registry, `spell/providers/registry.lua`):

```
---@class LanguageSpellProvider
---@field name string
---@field available fun():boolean
---@field scan_buffer fun(ctx):LanguageSpellIssue[]
---@field scan_cwd fun(ctx, cb:fun(issues))
---@field suggest fun(issue):string[]
---@field supports table<"buffer"|"cwd"|"grammar", boolean>
```

- `spell/providers/native.lua` — **Referenz: bestehende Logik aus
  `config/trouble/spell/init.lua`** (`vim.spell.check` pro Zeile, `make_diag`,
  `collect_buf`, `collect_cwd` mit `TEXT_EXT`-Filter, `apply_lang` für
  spelllang-Override). Wird 1:1 als Kern übernommen, nur ins Provider-Interface
  gegossen. **Immer verfügbar (Basis).**
- `spell/providers/typos.lua` / `codespell.lua` / `cspell.lua` — externe CLIs,
  async über `lib.nvim.cross.run`.
- `spell/providers/lsp.lua` — erntet `vim.diagnostic` von `harper_ls`/`ltex`
  (Grammatik!), Fix via `vim.lsp.buf.code_action`.

**Core** (`spell/core/`): `context.lua` (einmaliges Kontext-Objekt statt
Mehrfach-`vim.fn.*`), `store.lua` (Cache pro `bufnr`+`changedtick`, `lib.lua.memo`),
`scan.lua` (Provider-Orchestrierung, Merge/Dedupe, Debounce), `actions.lua`
(`replace_at`, `replace_all_in_buffer`, `add_to_dict` — Analogon zu `zg`/
spellfile aus dem Original, `ignore_session`/`ignore_persist`, `disable_rule`).

**UI** (`spell/ui/`, primär `lib.nvim.ui.kit`): `panel.lua` (Picker mit
Live-Preview, Navigation, Filter — löst den reinen Trouble/Quickfix-Fallback
des Originals ab, **Fallback bleibt erhalten** wenn `ui.kit` nicht gewünscht
oder Trouble nicht installiert ist — Muster aus `open_list`/`set_qf` im
Original übernehmen), `item_menu.lua` (`kit.menu`: Vorschlag wählen, alle
ersetzen, ins Wörterbuch, ignorieren Sitzung/dauerhaft, Regel abschalten,
zum Ort springen), `highlights.lua`, `diagnostics.lua` (Publish als
`vim.diagnostic`, Namespace-isoliert wie im Original: `NS = nvim_create_namespace(...)`).

Aus dem Original **zu erhaltende Detail-Mechanik** (nicht neu erfinden):
- Per-Buffer-State (`_state[bufnr]`), Restore von `spell`/`spelllang` beim
  Deaktivieren (`M.clear`).
- `z=`-Flow: Vorschlagsmenü öffnen → `refresh()` → `goto_next()` (als
  `attach_keymaps`/`detach_keymaps` pro Buffer, konfigurierbare Keymaps).
- `BufDelete`-Autocmd zur State-GC (`lib.nvim.autocmd.augroup`).
- Sprach-/Scope-Parsing (`lang`, `%`|`cwd`) aus den Command-Args.

---

### Domäne 2: Translate — **nativ, ohne Fremd-Plugin-Dependency**

**Entscheidung (User, nach Tiefenanalyse von `uga-rosa/translate.nvim`):**
Das Plugin ist klein (paar Dutzend Dateien), seit 3–4 Jahren unmaintained.
Statt es als Peer-Dependency einzubinden, wird die Übersetzungs-Logik
**nativ in `language.nvim` reimplementiert und modernisiert** — Analyse des
Originals als Bauplan, nicht als Laufzeit-Abhängigkeit.

**Analyseergebnis `uga-rosa/translate.nvim` (Referenz, nicht Dependency):**
- `lua/translate/init.lua`: `translate(mode,args)` → `_parse_args` (Flag-
  Parsing: `-source=`, `-command=`, `-output=`, `-comment`) → `select.get()`
  (Positions-Objekt) → `_translate()`: baut Pipeline
  `parse_before → command (curl via luv.spawn) → parse_after → output`.
- `preset/command/google.lua`: POST an eine **private Google-Apps-Script-
  Relay-URL** (`script.google.com/macros/s/AKfycb.../exec`) — genau die Art
  fragiler Code, die nach Jahren ohne Wartung bricht (Owner kann die
  Apps-Script-Deployment jederzeit deaktivieren). Windows-Sonderfall via
  manuelles `cmd.exe /c`-Wrapping.
- `preset/command/deepl.lua`: offizielle DeepL-REST-API
  (`api-free.deepl.com/v2/translate` bzw. `api.deepl.com`), Header
  `Authorization: DeepL-Auth-Key <key>`, JSON-Body `{text, target_lang,
  source_lang}`, Key aus `vim.g.deepl_api_auth_key`.
- `preset/parse_after/google.lua`: trivial `vim.json.decode(text)`.
- `util/replace.lua`: `nvim_buf_set_lines(0, pos[1].row-1, pos[#pos].row,
  true, lines)` — die eigentliche „replace"-Mechanik ist simpel.
- `preset/output/floating.lua`: scratch buffer (`nvim_create_buf(false,
  true)`) + `nvim_open_win`, Auto-Close bei `CursorMoved`.
- `util/select.lua` + `util/utf8.lua`: mehrstufige Positions-Erkennung
  (normal/visual-char/visual-line/blockwise/Comment-via-Treesitter) mit
  UTF-8-Byte↔Zeichen-Konvertierung für spaltengenaue Ersetzung — deutlich
  aufwändiger als das, was `:TranslateReplace` heute nutzt (Zeilenbereiche
  über `opts.line1/line2`). **Bewusst nicht für v1 übernommen** (siehe unten).

**Modernisierungs-Entscheidungen für die native Implementierung:**
1. **Google-Provider ersetzt die Apps-Script-Relay durch den etablierten
   `translate.googleapis.com/translate_a/single?client=gtx&sl=..&tl=..&dt=t&q=..`
   Endpoint** (keine eigene Server-Komponente eines Dritten im Pfad; von
   translate-shell, vielen CLI-Tools genutztes Standardmuster). Response ist
   ein verschachteltes JSON-Array — eigener kleiner Parser nötig
   (`[1][*][1]`-Segmente konkatenieren).
2. **JSON via `lib.nvim.lua.json.encode/decode`** statt Handrollen (lib.nvim
   bringt das bereits mit — Wiederverwendung statt Neubau).
3. **Async-Exec via `lib.nvim.cross.run` / `cross.uv.spawn_command`** statt
   manuellem `luv.spawn` + Windows-`cmd.exe`-Sonderfall — die Cross-Plattform-
   Logik existiert in lib.nvim bereits und deckt das ab.
4. **API-Keys aus Config + ENV** (`deepl.api_key` oder `DEEPL_API_KEY`
   Umgebungsvariable) statt `vim.g.*`-Globals — verhindert versehentliches
   Einchecken von Keys in Dotfiles.
5. **Provider-Registry-Pattern (identisch zur Spell-Domäne)** statt der
   generischen, konfigurierbaren `parse_before/command/parse_after/output`-
   Pipeline des Originals — architektonisch konsistent zum Rest des Plugins,
   einfacher zu warten: jeder Provider bekommt Text + Zielsprache rein,
   liefert übersetzten Text zurück.

```
---@class LanguageTranslateProvider
---@field name string                                  -- "google"|"deepl"|"shell"
---@field available fun():boolean                      -- Key vorhanden? curl/trans im PATH?
---@field translate fun(text:string[], target:string, source:string|nil, cb:fun(ok:boolean, result:string[]|string))
```

- `translate/providers/google.lua` — **Default, kein Key nötig.** Modernisierter
  `gtx`-Endpoint (s. o.), async über `lib.nvim.cross.run`, eigener
  Response-Parser für das verschachtelte Array.
- `translate/providers/deepl.lua` — offizielle API (Free/Pro-Host je nach
  Key-Suffix erkennbar wie im Original), Key aus Config/ENV,
  `lib.nvim.lua.json.encode/decode`.
- `translate/providers/shell.lua` — optionaler `trans`-CLI-Wrapper
  (translate-shell) für User, die dessen Zusatz-Engines/Wörterbücher wollen;
  `available()` prüft `vim.fn.executable("trans")`.
- `translate/providers/registry.lua` — Registry + Default-Auswahl, analog
  `spell/providers/registry.lua`.

**Übernommen (1:1 als Basis, weil bereits gut und generisch genug):**
- `translate/filter.lua` — **Referenz: `config/translate/filter.lua`
  (`get_translatable_line_ranges`)**: reine Funktion, berechnet sichere
  Zeilenbereiche unter Ausschluss von Fenced-Code (```) und Zeilen mit
  Inline-Backticks. Unverändert reusable, kein lib.nvim-Bezug nötig.
- `translate/replace.lua` — **Referenz: `config/translate/replace.lua`**:
  bei `nocode=true` über `filter`-Ranges iterieren und je Range den
  gewählten Provider aufrufen, sonst einmal für den ganzen Range. Ersetzt
  im Original den `vim.cmd(string.format("...Translate..."))`-Aufruf durch
  einen direkten `provider.translate(...)`-Call — dadurch entfällt jedes
  Kommandonamens-Kollisionsrisiko von vornherein (kein fremdes `:Translate`
  mehr im Spiel).
- `translate/output/{replace,floating}.lua` — `replace` (Referenz:
  `util/replace.lua`-Mechanik, `nvim_buf_set_lines`) als Default-Output;
  `floating` (Referenz: `preset/output/floating.lua`-Mechanik) als
  Preview-Option ohne Buffer-Mutation. `split`/`insert`/`register` sind
  spätere Ausbaustufen (Idee aus dem Original vorgemerkt, kein MVP-Blocker).

**Nicht für v1 übernommen (vorgemerkte Idee für später):** spaltengenaue
Multi-Mode-Selection (Wort unter Cursor, Visual-charwise/-blockwise mit
UTF-8-Konvertierung wie `util/select.lua`+`util/utf8.lua`). v1 bleibt bei
Zeilenbereichen (Range-Command, Visual-Line reicht für den heutigen
Workflow) — deckt den vom User als „sehr nützlich" bezeichneten
`:TranslateReplace`-Anwendungsfall vollständig ab. Feingranulare Auswahl
(`viw:Translate ZH<CR>`-Stil aus dem Original) ist ein guter Kandidat für
eine spätere Phase, kein Grund den MVP zu verzögern.

**Command** `:Translate <lang> [--nocode] [--output=replace|float]`
(Default-Output = `replace`, damit das bisherige `:TranslateReplace`-
Verhalten die neue Standardbedienung ist, range-fähig wie zuvor).
Completion für Sprachcodes + Flags wie im Original
(`usercommands.lua`: `parse_args`-Logik als Vorlage).

---

### Gemeinsame Infrastruktur

- `config/DEFAULTS.lua` / `config/init.lua` — ein Config-Baum mit `spell = {…}`
  und `translate = {…}` Teilbäumen, Muster wie `project_insight/config`.
- `bindings/usrcmds.lua` — registriert `:Spellcheck` und `:Translate`
  getrennt (kein Dachkommando), Completion je Domäne wie oben beschrieben,
  Muster exakt wie `project_insight/bindings/usrcmds.lua`.
- `bindings/keymaps.lua` — optionale Default-Keymaps aus Config (z. B.
  `<leader>ss` Spellcheck-Panel, `<leader>tr` Translate-Replace visuell —
  ersetzt den bereits (auskommentiert) vorhandenen Wunsch-Keymap aus
  `config/translate/init.lua`).
- `bindings/autocmds.lua` — `BufDelete`-GC (Spell-State), optionaler
  Live-Scan (debounced), Filetype-Gate.
- `health.lua` — `:checkhealth language`: lib.nvim vorhanden? Spell-Provider
  verfügbar? `curl` im PATH (Google/DeepL-Provider)? DeepL-Key konfiguriert?
  `trans`-CLI vorhanden (optionaler shell-Provider)? `spelllang` gesetzt?
- `plugin/language.lua` — Guard `vim.g.loaded_language`, lazy, nur für
  `:checkhealth` ohne `setup()`.
- `lua/language/init.lua` — `setup(opts)`, öffentliche Fassade
  (`M.spellcheck`, `M.translate`, `M.open_panel`, …).

---

### Scoping-Modell (Kern-Anforderung)

Actions/Scans laufen nicht nur im aktuellen Buffer, sondern über ein
einheitliches, explizites **Scope-Objekt**, das beide Domänen teilen:

```
---@alias LanguageScopeKind "buffer"|"visible"|"cwd"|"path"|"selection"
---@class LanguageScope
---@field kind LanguageScopeKind
---@field bufnr integer|nil       -- buffer/visible/selection
---@field path  string|nil        -- path: Datei ODER Verzeichnis (rekursiv)
---@field range { s:integer, e:integer }|nil  -- selection/visible: Zeilenbereich
```

- **`buffer`** — ganzer aktueller Buffer (Default für `:Spellcheck`).
- **`visible`** — nur sichtbarer Fensterbereich (`line("w0")`..`line("w$")`).
  Perf-Modus für Live-Scan (Idee aus **spelunker**/**fastspell**).
- **`cwd`** — rekursiv über das Projektverzeichnis. Dateiauswahl via
  `lib.nvim.fs.ignore.list` (`.git`, `node_modules`, …) + Größenlimit; nur
  Textfiletypes (`TEXT_EXT`-Filter aus der Vorarbeit). **Immer async.**
- **`path`** — beliebige Datei oder beliebiges Verzeichnis als Argument
  (`:Spellcheck en path=~/notes` bzw. `:Translate DE path=README.md`).
- **`selection`** — Visual-Range (v. a. Translate: `:'<,'>Translate DE`).

Command-Oberfläche (einheitliches Parsing für beide Commands):
`:Spellcheck [lang] [buffer|visible|cwd|path=<p>]` /
`:Translate <lang> [--nocode] [--output=…] [buffer|cwd|path=<p>|selection]`.
Der Scope wird **einmal** in ein `LanguageScope`-Objekt geparst und durch
`core/scan.lua` / `translate/replace.lua` gereicht (Zentrale-Prinzipien §3:
Kontext statt Mehrfach-API-Zugriffe).

Für `cwd`/`path`-Scope mit vielen Dateien wird der **externe CLI-Provider
bevorzugt** (typos/cspell — ein Prozess über den ganzen Baum) statt jede Datei
in einen Scratch-Buffer zu laden; native Fallback lädt Dateien chunk-weise und
gibt zwischen Chunks per `vim.schedule` frei (kein Freeze).

---

### Asynchronität & Cancellation (Kern-Anforderung)

Regel: **jede Aktion, die länger als ein einzelner sichtbarer Buffer dauern
kann, läuft asynchron und ist abbrechbar.** Konkret:

- **Externe Prozesse** (typos/cspell/codespell, curl für Translate, `trans`)
  laufen über `lib.nvim.cross.run` / `cross.uv.spawn_command` (non-blocking,
  Callback), **nie** `vim.fn.system()` (das friert). Ergebnisse werden per
  `vim.schedule` zurück in den UI-Thread gebracht.
- **Native cwd/path-Scan** (kein CLI vorhanden): koroutinen-/chunk-basiert,
  N Dateien pro Tick, `vim.schedule`/`uv.new_timer` dazwischen; Fortschritt
  über `lib.nvim.progress` (Idee: sichtbares, nicht-blockierendes Feedback).
- **Debounce** für Live-Scan (`TextChanged`/`InsertLeave`), konfigurierbar
  (`scan_debounce_ms`); zusätzlich `visible`-Scope als Perf-Default für Live.
- **Cancellation-Token**: jeder Scan/Translate-Job bekommt eine Job-ID; ein
  neuer Trigger auf demselben Buffer **canceled den laufenden** (kill spawn,
  Timer stop, Callback verwerfen) → keine veralteten Ergebnisse, keine
  Job-Häufung (angelehnt an das async-Multithreading von **vim-translator**,
  aber mit sauberem Abbruch statt Race).
- **Timeout** pro externem Job (konfigurierbar) → hängende Prozesse
  (Netzwerk bei Translate!) werden abgeräumt, klare Notify statt Hänger.
- **In-Memory-Ergebnis-Cache** pro `bufnr`+`changedtick` (`lib.lua.memo`,
  Weak-Values) — Re-Open des Panels ohne Re-Scan, invalidierbar.

---

### Config-Defaults (Auszug)

```lua
{
  spell = {
    providers = {
      order  = { "native", "lsp", "typos", "cspell", "codespell" },
      buffer = { "native", "lsp" },
      cwd    = { "typos", "native" },      -- CLI bevorzugt für Baum-Scan
      native = { spelllang = nil },        -- nil = vim 'spelllang' übernehmen
      lsp    = { enable = true, servers = { "harper_ls", "ltex" } },
    },
    filetypes = { "markdown","text","gitcommit","tex","rst","asciidoc","help" },
    default_scope = "buffer",              -- buffer|visible|cwd|path
    live = false,                          -- opt-in Live-Scan
    live_scope = "visible",                -- Perf: Live nur im Sichtbereich (spelunker/fastspell)
    scan_debounce_ms = 400,
    -- Code-Identifier-Splitting (spelunker/fastspell/cspell): CamelCase &
    -- snake_case in Subwörter zerlegen, bevor gegen das Wörterbuch geprüft wird.
    word_split = { enable = true, min_length = 4 },  -- min_length aus spelunker
    -- Perf-/Safety-Caps (spelunker):
    max_highlights = 100,                  -- max hervorgehobene Fehler je Buffer
    max_file_lines = 20000,                -- oberhalb: kein Auto-/Live-Scan
    skip_readonly = true,                  -- readonly-Buffer nicht scannen (spelunker)
    -- Nur spellbare Regionen prüfen (Treesitter @spell / Prädikat wie vim-SpellCheck):
    regions = { treesitter_spell = true, skip_urls = true, skip_emails = true },
    programming_dict = false,              -- opt-in: vim-dirtytalk-artige Fachwortliste zu spelllang
    ui = { view = "picker", preview = true, group_by = "file", dedupe = true },
    dictionary = {
      ignore_file = vim.fn.stdpath("state") .. "/language/spell_ignore.txt",
      use_spellfile = true,
      replace_all = true,                  -- z=/Vorschlag global im Scope (spellrepall, vim-SpellCheck)
    },
    guard = { block_write_on_error = false },  -- opt-in: :w abbrechen bei Fehlern (vim-SpellCheck)
    keymaps = { panel = "<leader>ss", next = "]s", fix = "<leader>z=", fix1 = "<leader>z1" },
  },
  translate = {
    engine = "google",                     -- "google"|"deepl"|"shell"|<custom>
    fallback = { "google" },               -- Engine-Fallback-Kette (pantran graceful degradation)
    default_output = "replace",            -- "replace"|"float"|"notify"|"clipboard"|"insert"
    default_input = "selection",           -- selection|clipboard|input (niuiic)
    default_langs = { "EN", "DE", "FR", "ZH", "JA" },
    nocode_default = false,
    timeout_ms = 8000,                     -- Netzwerk-Timeout je Job
    deepl = { api_key = nil },             -- oder ENV "DEEPL_API_KEY"
    -- custom = { cmd = function(text, target) return {"trans", …} end, parse = fn },
  },
  commands = true,
}
```

---

## Modul-Layout (neues Repo `e:\repos\language.nvim`)

```
plugin/language.lua
lua/language/init.lua
lua/language/health.lua
lua/language/@types/init.lua
lua/language/config/{DEFAULTS.lua,init.lua,@types/init.lua}
lua/language/spell/@types/init.lua
lua/language/spell/core/{context,store,scan,actions}.lua
lua/language/spell/providers/{registry,native,typos,codespell,cspell,lsp}.lua
lua/language/spell/ui/{panel,item_menu,highlights,diagnostics}.lua
lua/language/translate/@types/init.lua
lua/language/translate/{filter,replace}.lua
lua/language/translate/providers/{registry,google,deepl,shell}.lua
lua/language/translate/output/{replace,floating}.lua
lua/language/bindings/{usrcmds,keymaps,autocmds}.lua
doc/language.txt                            -- englisch (:help)
docs/ROADMAP/ROADMAP.md
README.md                                    -- deutsch
stylua.toml
```

---

## Wiederverwendung aus lib.nvim

| Zweck | lib.nvim-Modul |
|---|---|
| Notify (UI-Schicht) | `lib.nvim.notify` |
| Keymaps/Usercmd/Autocmd/Augroup | `lib.nvim.map`, `.usercmd`, `.autocmd`, `.autocmd.augroup` |
| Panel/Menu/Select/Preview/Confirm | `lib.nvim.ui.kit` (picker,menu,select,preview,surface,confirm) |
| HL-Gruppen | `lib.nvim.ui.hl` |
| Externe Prozesse (async, cross) | `lib.nvim.cross.run`, `cross.uv.spawn_command` |
| Plattform-Detection | `lib.nvim.cross.platform.*` |
| Root/Repo | `lib.nvim.fs.find_root`, `lib.nvim.git` |
| Datei lesen/schreiben (Ignore-Liste) | `lib.nvim.fs.write.*`, `fs.is_readable_file` |
| Memoisierung/Cache | `lib.lua.memo` (+ lru) |
| Lazy-Load | `lib.lua.lazy` |
| Tabellen/Strings-Helfer (Hot-Path) | `lib.lua.tables`, `lib.lua.strings` |
| JSON encode/decode (Translate-API-Bodies) | `lib.lua.json` |
| Fortschritt cwd-Scan | `lib.nvim.progress` |

---

## Erkenntnisse aus Fremd-Plugin-Analyse (was wir mitnehmen)

**Eigene Vorarbeit**
- `config/trouble/spell/init.lua` — kompletter Session-/State-/Command-
  Mechanismus als Kern (Per-Buffer-State, `z=`-Flow, spelllang-Restore).

**Spell — Detektion & Datenmodell**
- **spellwarn.nvim** — zwei Detektionsmethoden (`cursor` via `]s`-Iteration vs.
  `iter` via Treesitter+API); Fehlerklassen `spellbad/spellcap/spelllocal/
  spellrare` → in `kind` übernehmen; `vim.diagnostic.set()` + Filetype-Filter +
  Zeilen-/Datei-Disable-Direktiven (`spellwarn:disable-line`). **Mitnehmen:**
  Klassen-Mapping, Inline-Disable-Direktiven, Filetype-Gate.
- **vim-SpellCheck** — Overview-als-Quickfix mit **Dedupe: erste Position +
  Occurrence-Count + Kontexttext**; `z=`/`zg`/`zw` **im Listenfenster** gemappt;
  `:spellrepall` (global im Scope ersetzen); **Prädikat-Filter nach Syntax-/
  Region-Gruppe** (nur Kommentare o. Ä.); Guard-Commands
  (`WriteUnlessSpellError`). **Mitnehmen:** `occurrences`-Feld + Dedupe,
  Listen-lokale Fix-Keymaps, `replace_all`-im-Scope, Region-Prädikat, opt-in
  `block_write_on_error`.
- **spelunker.vim** — **CamelCase/PascalCase/snake_case-Splitting** in Subwörter;
  Sprach-/Projekt-**Allowlists**; **nur sichtbaren Fensterbereich prüfen**
  (Perf); Caps `min_char_len` (4), `max_hi_words_each_buf` (100);
  **readonly-Buffer überspringen**; Korrektur-UI (Liste/manuell/„lucky"). URI/
  Email/Acronym/Backtick-Toggles. **Mitnehmen:** `word_split`, `max_highlights`,
  `max_file_lines`, `skip_readonly`, `visible`-Scope, URL/Email-Skip.
- **fastspell.nvim** — **persistenter Backend-Prozess statt Prozess-pro-Check
  (~100× schneller, ~100 MB RAM Trade-off)**; konfigurierbare Trigger-Events +
  Scan-Scope (visible / line+neighbors / whole / manual). **Mitnehmen:** für den
  cspell-Provider **einen langlebigen Prozess** halten (Spawn-Kosten sparen);
  Trigger-/Scope-Konfigurierbarkeit.
- **vim-dirtytalk** — kuratierte **Programmier-Wortliste** als zusätzliches
  `spelllang`-Dictionary; Kategorien (git/k8s/python) selektiv; Nerd-Font-
  Symbole als „rare" markiert. **Mitnehmen:** opt-in `programming_dict`, das
  eine mitgelieferte/generierte Wortliste an `spelllang` anhängt.
- **vim-lexical** — buffer-scoped Spell + **Thesaurus** (`C-x C-t`) + Dictionary-
  Completion (`C-x C-k`), buffer-lokal statt global. **Mitnehmen (später):**
  optionale Thesaurus-/Synonym-Aktion im Aktionsmenü; strikt buffer-lokale
  Options.

**Grammar**
- **vim-LanguageTool** — Grammar-Check mit **Scratch-Buffer voller Erklärungen**,
  Klick→Sprung, Loclist-Integration, Source-Highlight, **Range-Check**.
  **Mitnehmen:** Grammatik-Erklärung in der Panel-Preview, Range/Scope-Check,
  Loclist als Alternativausgabe.
- **harper-ls / ltex** (LSP) — Grammatik/Stil als Diagnostics + Code-Actions
  (add-to-dict, rule-off) → `providers/lsp.lua`.

**Suggest-UI**
- **Telescope `spell_suggest` / unite-spell-suggest** — Vorschläge im **Fuzzy-
  Picker**, Ersetzen bei `<CR>`, **live aktualisierend** beim Wortwechsel; weniger
  intrusiv als modales `z=`. **Mitnehmen:** `item_menu` „Vorschlag wählen…" als
  Picker statt modalem `z=`.

**Translate — Engines, Async, UX**
- **pantran.nvim** — **interaktives Floating-Window mit Live-Übersetzung beim
  Tippen**; 5 Engines (DeepL/Google/Yandex/Argos/Apertium); **graceful
  degradation** (freie Fallback-Endpoints ohne Key, rate-limited); **Motion-
  Mappings** (Textobjekte übersetzen); interaktiv + nicht-interaktiv (replace/
  append). **Mitnehmen:** `fallback`-Kette, `float`-Output, später ein
  interaktives Übersetzungs-Fenster + Motion-Support.
- **vim-translator (voldikss)** — **async, mehrere Engines nebenläufig**;
  Output echo/popup/replace/preview; **Proxy-Support**, **kein appid/appkey
  nötig**; **Query-History**; Reverse-Translate. **Mitnehmen:** nebenläufige
  Engine-Abfrage (mit sauberem Cancel, s. Async-Abschnitt), History, Reverse.
- **niuiic/translate.nvim** — **Command-basierte, frei definierbare Engine**
  (User liefert `cmd`-Generator + `parse`-Fn); **Input-Quellen** selection/
  clipboard/input; **Output** float/notify/clipboard/insert/replace; „never
  blocks". **Mitnehmen:** `translate.custom`-Engine (eigener Shell-Befehl),
  `default_input`, breite Output-Modi.
- **skanehira/translate.vim** — minimal, `!`-Modifier für **Reverse**-Übersetzung,
  Yank aus Popup. **Mitnehmen:** Reverse-Flag, Yank-Ergebnis.

---

## Extraktions- & Cleanup-Plan (nvim-Config)

Nach erfolgreicher Implementierung von `language.nvim`, **sobald es als
externes Plugin eingebunden ist**:

1. Löschen: `lua/config/trouble/spell/**`, `lua/config/translate/**`.
2. `lua/plugins/trouble.lua`: Block `require("config.trouble.spell").setup({…})`
   (Zeilen ~120–133) entfernen.
3. `lua/plugins/workflow.lua`: `uga-rosa/translate.nvim`-Spec-Block (Zeilen
   ~72–78, inkl. `require("config.translate")`) **vollständig entfernen** —
   `language.nvim` hat keine Translate-Fremd-Dependency mehr, nur `curl`
   muss auf dem System vorhanden sein (bereits Voraussetzung des Originals).
4. Prüfen/bereinigen: `bindings/mappings/sourrounding.lua` (nur Kommentar-
   Fehltreffer „Translate termcodes", keine Aktion nötig);
   `autocmds/git/{commit_ft.lua,defaults.lua}` **bleiben unverändert** (natives
   `vim.opt_local.spell` für Commit-Buffer ist ein anderes Feature, keine
   Extraktion).
5. Neue Spec-Grundgerüst (lazy.nvim) — `folke/trouble.nvim` bleibt optionale
   Soft-Dependency (nur für den Spell-Fallback, `pcall`-guarded), sonst
   **keine externen Plugin-Dependencies**:
   ```lua
   {
     "StefanBartl/language.nvim",
     dependencies = { "folke/trouble.nvim" },  -- optional, pcall-guarded
     event = "VeryLazy",
     config = function() require("language").setup({}) end,
   }
   ```

---

## Umsetzungs-Phasen

1. **Gerüst:** Repo, `plugin/`, `init.lua`, `config/`, `health.lua`, `@types`
   (inkl. `LanguageScope`). `setup()` lädt sauber, `:checkhealth` grün.
2. **Scope-Parser + Spell-Kern:** einheitliches Scope-Parsing (`buffer|visible|
   cwd|path`), `native`-Provider 1:1 aus `config/trouble/spell/init.lua`
   (Session-State, Trouble/Quickfix-Fallback identisch) — **funktionale Parität
   zum Status quo zuerst**. `:Spellcheck [lang] [buffer|cwd|clear|refresh]`.
3. **Translate-Kern:** nativer `google`-Provider (gtx-Endpoint, kein Key,
   **async via `lib.cross.run`**) + `filter.lua`/`replace.lua`, `:Translate
   <lang> [--nocode] [--output=…] [selection|buffer|path=…]`, Default `replace`
   (Parität zu `:TranslateReplace`, ohne Konfiguration nutzbar).
4. **Async-Fundament:** Cancellation-Token + Timeout + `lib.progress` für alle
   länger laufenden Jobs; native cwd/path-Scan chunk-basiert (kein Freeze).
5. **Panel-UI (Spell) über `lib.nvim.ui.kit`:** Picker + Preview (inkl.
   Grammatik-Erklärung) + Aktionsmenü (Vorschlag-Picker, replace-all-im-Scope,
   Dedupe/Occurrences, ins Wörterbuch, ignorieren).
6. **Perf-/Code-Features:** `word_split` (CamelCase/snake_case), `visible`-Live-
   Scope, Caps (`max_highlights`/`max_file_lines`/`skip_readonly`), Region-
   Prädikat (Treesitter `@spell`, URL/Email-Skip), opt-in `programming_dict`.
7. **Weitere Provider:** Spell typos/cspell (**persistenter Prozess**, fastspell-
   Idee)/codespell + LSP-Grammar; Translate `deepl` (Key aus Config/ENV),
   `shell`/`custom`-Engine, `fallback`-Kette, weitere Output-Modi.
8. **Cleanup in nvim-Config** gemäß Abschnitt oben.
9. **Doku & Politur:** README dt., `doc/language.txt` en, ROADMAP, `stylua`.

Spätere Ausbaustufen (vorgemerkt, nicht MVP): interaktives Translate-Float mit
Live-Übersetzung + Motion-Support (pantran), Thesaurus-Aktion (vim-lexical),
spaltengenaue Multi-Mode-Selection, Query-History/Reverse-Translate.

---

## Verifikation (End-to-End)

- **Laden:** `language.nvim` per lazy.nvim einbinden, `:checkhealth language`
  → lib.nvim + Backend-Erkennung fehlerfrei.
- **Spell-Parität:** `:Spellcheck en %` in Testbuffer mit Tippfehlern →
  identisches Verhalten zum bisherigen `:SpellChecker` (Trouble/qf, `z=`-Fix,
  `]s`, Session-Cleanup bei 0 verbleibenden Fehlern).
- **Scoping:** `:Spellcheck en cwd` (rekursiv, ignore-Liste greift) und
  `:Spellcheck en path=<dir>` → aggregierte Liste über mehrere Dateien, Sprung
  öffnet Datei an Ort; `visible`-Scope prüft nur den Sichtbereich.
- **Async/Freeze-Test:** cwd-Scan über großes Verzeichnis blockiert die UI
  nicht (Progress sichtbar, Tippen bleibt möglich); ein zweiter Trigger
  während eines laufenden Scans **canceled den ersten** (keine Doppelergebnisse);
  ein künstlich hängender Translate-Job läuft in den Timeout mit klarer Notify.
- **Code-Splitting:** `word_split` erkennt `getUserName`/`user_name` als
  Subwörter; `max_file_lines`/`skip_readonly`/Caps greifen wie konfiguriert.
- **Translate-Parität:** `:Translate EN` über eine Visual-Range mit Markdown
  (Fenced-Code enthalten) + `--nocode` → nur Prosa wird ersetzt, Code bleibt
  unangetastet; ohne `--nocode` wird der ganze Range übersetzt. Läuft ohne
  jede Konfiguration (Google-Default, kein Key, kein Fremd-Plugin geladen).
- **Translate-Provider-Matrix (Phase 5):** `deepl`-Provider mit gültigem/
  fehlendem Key testen (klare Fehlermeldung bei fehlendem Key statt Crash);
  `shell`-Provider mit/ohne installiertes `trans` (Fallback-Verhalten).
- **Panel (später, Phase 4):** Multi-Provider-Overview, Vorschlag übernehmen,
  ins Wörterbuch, ignorieren.
- **Cross-Plattform-Smoke:** Windows-Pfade/Prozessaufrufe über `lib.cross`.
- **Cleanup-Verifikation:** nach Config-Bereinigung `:checkhealth` der
  Gesamt-Config weiterhin grün, keine verwaisten Requires auf
  `config.trouble.spell` / `config.translate`.

---

