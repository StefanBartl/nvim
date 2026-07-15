# language.nvim — Spell-, Grammar- & Translate-Werkzeug für Neovim

- natives rekursives Directory-Walking für Spell ohne CLI-Provider. -was meinst du damit genau?




> **[UMGESETZT WIE GEPLANT]** — keine Abweichung
> - **[ANDERS ALS GEPLANT]** — existiert, aber anders benannt/geschnitten
> - **[NICHT UMGESETZT]** — im Plan vorgesehen, im Code nicht vorhanden
> - **[NEU, NICHT GEPLANT]** — im Code vorhanden, stand nicht im ursprünglichen Plan

## Table of content

  - [Zusammenfassung der wichtigsten Abweichungen](#zusammenfassung-der-wichtigsten-abweichungen)
  - [Context](#context)
  - [Verbindliche Vorgaben (aus den Coding-Regeln)](#verbindliche-vorgaben-aus-den-coding-regeln)
  - [Architektur](#architektur)
    - [Domäne 1: Spell & Grammar](#domne-1-spell-grammar)
    - [Domäne 2: Translate](#domne-2-translate)
    - [Gemeinsame Infrastruktur](#gemeinsame-infrastruktur)
    - [Scoping-Modell](#scoping-modell)
    - [Asynchronität & Cancellation](#asynchronitt-cancellation)
    - [Config-Defaults (tatsächlicher Stand)](#config-defaults-tatschlicher-stand)
  - [Modul-Layout (tatsächlicher Stand)](#modul-layout-tatschlicher-stand)
  - [Wiederverwendung aus lib.nvim](#wiederverwendung-aus-libnvim)
  - [Bekannte Lücken / totes Config](#bekannte-lcken-totes-config)
  - [Umsetzungs-Historie](#umsetzungs-historie)
  - [Verifikation](#verifikation)

---

## Zusammenfassung der wichtigsten Abweichungen

**Größer als geplant (zusätzliche Features, die als „spätere Ausbaustufe“ vorgemerkt waren, aber gebaut wurden):**
- Interaktives Translate-Fenster (`:Translate!`) mit Live-Übersetzung, Reverse/Round-Trip (`<C-r>`), History (`<C-h>`) — im Original explizit „nicht für v1“.
- Motion-/Visual-Übersetzungs-Mappings (`translate/motion.lua`) inkl. **spaltengenauer** (char-wise) Übersetzung via `getregionpos` — im Original explizit „nicht für v1“.
- Thesaurus/Synonyme (`thesaurus/init.lua`) — Datamuse-API statt der geplanten vim-lexical-Anlehnung.
- **Persistenter cspell-Sidecar** (`node/cspell_server.js` + `spell/providers/cspell_server.lua`) — genau die im Plan als „später/fastspell-Idee“ vorgemerkte Optimierung, tatsächlich als Node-Subprozess gebaut und live gegen echtes `cspell` getestet.
- Windows-Fix im Job-Runner: npm-`.cmd`-Shims (cspell, codespell) werden über `cmd.exe /c` gestartet — im Plan nicht vorhergesehen, war ein echter Blocker.

**Kleiner / anders als geplant:**
- Kein separates `spell/core/context.lua`, `store.lua` — stattdessen `spell/core/collect.lua` (Scan-Orchestrierung ohne Cache) + `ignore.lua` + `split.lua` + `regions.lua`.
- Kein `spell/ui/highlights.lua`, `diagnostics.lua` — stattdessen ein einziges `spell/ui/list.lua` (Diagnostics-Publish + Trouble/qf).
- Kein `spell/providers/registry.lua` — Dispatch läuft über eine inline `CLI_MODULES`-Tabelle in `collect.lua` (Translate hat dagegen ein echtes `translate/providers/registry.lua`).
- Provider-Interface heißt `scan_scope(scope, cfg)` / `scan_async(scope, cfg, cb)`, nicht `scan_buffer(ctx)` / `scan_cwd(ctx, cb)`.
- `:Spellcheck`-Scope-Syntax ist `buffer` (nicht `%`) plus zusätzlich `visible` und `path=<p>`.
- `:Translate` hat **kein** `cwd`/`path`-Scope trotz Completion-Angebot — zur Laufzeit abgelehnt (`"Translate over cwd/path is not supported yet"`).

**Geplant, aber nicht gebaut (siehe [Bekannte Lücken](#bekannte-lcken-totes-config)):**
- Kein In-Memory-Cache/Memoization (`lib.lua.memo`, `bufnr+changedtick`).
- Kein `lib.nvim.progress`-Feedback bei cwd/path-Scans.
- Kein generisches Cancellation-Token für Spell-CLI-Scans (nur Translate hat das).
- `guard.block_write_on_error` und `dictionary.replace_all` sind deklariert, aber nirgends verdrahtet (totes Config).
- Keine Inline-Disable-Direktiven (`language:disable-line`).

---

## Context

Beim Schreiben (Prosa, Markdown, Code-Kommentare) fehlte in Neovim ein
zentraler Ort, an dem man **alle** Rechtschreib-/Grammatikprobleme eines
Buffers oder des gesamten `cwd` auf einen Blick sieht und **direkt
abarbeitet**. Nvims Bordmittel (`]s`, `z=`, `zg`) sind rein cursor-lokal;
externe Tools (typos, cspell, harper, ltex) liefern zwar Diagnosen, aber jede
mit eigener UI und ohne einheitlichen „Durcharbeiten“-Workflow.

Die bestehende nvim-Config enthielt eine ausgereifte Spell-Session
(`config/trouble/spell/`) und eine Translate-Orchestrierung um das externe
Plugin `uga-rosa/translate.nvim` (`config/translate/`). Beide wurden zu einem
eigenständigen Plugin verschmolzen: `language.nvim`, `e:\repos\language.nvim`.
**[UMGESETZT WIE GEPLANT]**

`config/trouble/spell/**` und `config/translate/**` wurden nach
Fertigstellung aus der nvim-Config entfernt; die Verdrahtung in
`plugins/trouble.lua` und `plugins/workflow.lua` durch eine eigene
`plugins/language.lua` ersetzt. **[UMGESETZT WIE GEPLANT]** — mit einem
Zwischenfall: die neue `plugins/language.lua` ging beim ersten Cleanup-Commit
verloren und musste in einem Folge-Commit (`ba47a088`) wiederhergestellt
werden.

**Kernentscheidungen:**
- Name: `language.nvim`. **[UMGESETZT WIE GEPLANT]**
- Umfang: Spell + Grammar + Translate + (neu hinzugekommen) Thesaurus als
  gleichberechtigte Domänen. **[ANDERS ALS GEPLANT]** — Thesaurus war im
  Original nur eine Randnotiz unter Spell, ist tatsächlich ein eigenständiges
  Top-Level-Modul (`lua/language/thesaurus/`).
- Kommandos: zwei Top-Level-Commands, kein Dachkommando. **[UMGESETZT WIE
  GEPLANT]**, aber `:Translate` hat zusätzlich ein **Bang** (`:Translate!`)
  für das interaktive Fenster — im Original nicht vorgesehen.
- Provider-Prinzip: mehrere austauschbare Quellen pro Domäne. **[UMGESETZT WIE
  GEPLANT]**, siehe Interface-Abweichung oben.

---

## Verbindliche Vorgaben (aus den Coding-Regeln)

Unverändert gültig und eingehalten:
- `lib.nvim` als Dependency (`notify`, `map`, `usercmd`, `autocmd`/`augroup`,
  `ui.kit`). **[UMGESETZT WIE GEPLANT]**
- Ein Modul = eine Verantwortung, lokale Helfer, kein globaler State.
  **[UMGESETZT WIE GEPLANT]**
- `pcall` um API-/Provider-Zugriffe, `ok/err`-Rückgaben, `notify` nur in der
  UI-Schicht. **[UMGESETZT WIE GEPLANT]**
- Async statt blockierend, `vim.uv`-Debounce. **[UMGESETZT WIE GEPLANT]** —
  aber ohne den geplanten Cache-Layer (s. u.).
- `@module/@brief/@description`, `/@types`-Ordner pro Verzeichnis.
  **[UMGESETZT WIE GEPLANT]**
- Deutsche `README.md` + englische `doc/language.txt` + `docs/ROADMAP/`.
  **[UMGESETZT WIE GEPLANT]**
- Cross-Plattform. **[UMGESETZT WIE GEPLANT]**, mit dem nachträglich
  gefundenen Windows-`.cmd`-Fix im Job-Runner (`util/job/init.lua`:
  `resolve_argv` routet alles außer `.exe`/`.com` über `cmd.exe /c`).
  **[NEU, NICHT GEPLANT]** — war ein echter Bug, kein Feature.
- `lib.lua.json` als geplante JSON-Abhängigkeit: **[NICHT UMGESETZT]** —
  tatsächlich wird durchgehend `vim.json.encode/decode` verwendet (Neovim
  eingebaut), `lib.lua.json` wird nirgends importiert.

---

## Architektur

Zwei Domänen (`spell` inkl. Grammar, `translate`) plus eine dritte,
ursprünglich nicht als eigene Domäne geplante (`thesaurus`). Kein
gemeinsames Dachkommando. **[UMGESETZT WIE GEPLANT, + thesaurus NEU]**

---

### Domäne 1: Spell & Grammar

Datenfluss tatsächlich: `Provider(s) → Issue-Liste → Ignore-Filter/Dedupe →
Panel-UI/Diagnostics → Actions → Buffer-Edit/Dictionary/Ignore → Re-Scan`.
**[ANDERS ALS GEPLANT]** — der geplante `Store (Cache)`-Schritt existiert
nicht; jeder Scan läuft frisch.

Issue-Modell (`spell/@types/init.lua`) — **[UMGESETZT WIE GEPLANT]**, Felder
stimmen exakt mit dem Original-Entwurf überein:

```lua
---@class LanguageSpellIssue
---@field bufnr       integer|nil
---@field path        string
---@field lnum        integer
---@field col         integer
---@field end_col     integer
---@field word        string
---@field kind        "spell"|"grammar"|"style"|"rare"|"caps"
---@field source      "native"|"typos"|"codespell"|"cspell"|"harper"|"ltex"
---@field message     string|nil
---@field rule        string|nil
---@field suggestions string[]|nil
---@field occurrences integer|nil
```

**Provider-Interface** — **[ANDERS ALS GEPLANT]**, kein `registry.lua`,
Interface-Namen weichen ab:

```lua
---@class LanguageSpellProvider
---@field name        string
---@field available   fun(): boolean
---@field scan_scope  fun(scope: LanguageScope, cfg: LanguageSpellCfg): LanguageSpellIssue[]   -- sync
--- oder für externe CLIs / den Sidecar:
---@field scan_async  fun(scope, cfg, cb: fun(issues)): Language.Job|nil                       -- async
---@field suggest     fun(issue): string[]
```

Tatsächliche Provider (`spell/providers/`):
- `native.lua` — `vim.spell.check`, **[UMGESETZT WIE GEPLANT]** als Kern,
  zusätzlich mit `word_split` (CamelCase/snake_case-Splitting, ausgelagert in
  `spell/core/split.lua`) und Treesitter-`@spell`-Regionsfilter
  (`spell/core/regions.lua`) — beide im Original als Ideen vorgemerkt,
  tatsächlich implementiert. **[UMGESETZT, teils sogar über Plan hinaus]**
- `typos.lua`, `codespell.lua`, `cspell.lua` — externe CLIs, async über einen
  eigenen `util/job`-Runner (nicht `lib.nvim.cross.run`, s. u.).
  **[ANDERS ALS GEPLANT]**
- `cspell_server.lua` — **[NEU, NICHT GEPLANT]** persistenter Node-Sidecar
  (`node/cspell_server.js`), hält `cspell-lib` warm, code-aware,
  live-tauglich. Das war im Original nur die vage „fastspell-Idee“ unter
  „spätere Ausbaustufe“.
- `lsp.lua` — erntet `vim.diagnostic` von `harper_ls`/`ltex`.
  **[UMGESETZT WIE GEPLANT]**, Fix via `vim.lsp.buf.code_action` (Aktion
  „Apply LSP fix…“ im Item-Menü) statt der geplanten granularen
  „Regel abschalten“-Aktion.
- `util.lua` — **[NEU, NICHT GEPLANT]** geteilte Pfad-/Buffer-Helfer für die
  CLI-Provider (DRY-Extraktion, kein funktionaler Unterschied).

**Kein** `lib.nvim.cross.run` / `cross.uv.spawn_command`: **[ANDERS ALS
GEPLANT]** — stattdessen ein eigener `language/util/job/init.lua`
(argv-basiert, kein Shell-String, mit Windows-`.cmd`-Fix, Timeout,
Cancellation). Grund: `lib.nvim.cross.run` nimmt einen Shell-String entgegen,
was bei beliebigem Übersetzungstext ein Injection-/Quoting-Risiko wäre.

**Core** (`spell/core/`) — **[ANDERS ALS GEPLANT]**:
- `collect.lua` (statt `context.lua`+`store.lua`+`scan.lua`) — orchestriert
  Provider, merged native+LSP synchron (`scan`) bzw. async inkl. CLI-Provider
  und cspell-Sidecar (`gather`), Ignore-Filter + Dedupe. **Kein Cache.**
- `ignore.lua` — Session-/persistenter Ignore-Store. **[NEU benannt]**, war im
  Plan Teil von `actions.lua`.
- `actions.lua` — `replace_at`, `replace_all_in_buffer`, `add_to_dict`.
  **[UMGESETZT WIE GEPLANT]**
- `split.lua`, `regions.lua` — **[NEU, eigene Module]**, im Plan nur als
  Konfig-Ideen unter `native.lua` erwähnt.

**UI** (`spell/ui/`) — **[ANDERS ALS GEPLANT]**:
- `panel.lua` — interaktiver Picker via `lib.nvim.ui.kit.select` (Chooser),
  nicht der geplante `kit.picker` mit Live-Preview-Slot. Zeigt eine
  formatierte Zeilenliste, keine separate Preview-Pane.
- `item_menu.lua` — `kit.menu` mit Aktionen (Vorschlag wählen, alle ersetzen,
  ins Wörterbuch, ignorieren Sitzung/dauerhaft, **Apply LSP fix…** bei
  Grammatik, zum Ort springen). **[UMGESETZT, LSP-Fix-Aktion ist neu ggü. der
  vage geplanten „Regel abschalten“]**
- `list.lua` — **[ANDERS ALS GEPLANT]** ersetzt die geplanten getrennten
  `highlights.lua` + `diagnostics.lua`: publiziert Diagnostics
  (Namespace-isoliert wie geplant) und liefert den Trouble/Quickfix-Fallback.
  **Keine Buffer-Extmark-Highlights** (`highlights.lua` existiert nicht) —
  Sichtbarkeit läuft ausschließlich über `vim.diagnostic`.

Aus dem Original erhaltene Detail-Mechanik — **[UMGESETZT WIE GEPLANT]**:
Per-Buffer-Session-State, `spell`/`spelllang`-Restore bei `M.clear()`,
`z=`-Flow (Vorschlagsmenü → `refresh()` → `goto_next()`),
`BufDelete`-Autocmd zur State-GC.

**Live-Scan** — **[NEU, eigenes Modul, nicht im Original geplant]**:
`spell/live.lua` ist vollständig von der Session entkoppelt (der Original-Plan
sah Live-Scan als Teil der aktiven Session vor). Läuft unabhängig, gated über
Filetype-Liste + `max_file_lines` + `skip_readonly`, Default-Scope `visible`
mit Viewport-Folgen bei `WinScrolled`.

---

### Domäne 2: Translate

Die im Plan ausführlich dokumentierte Analyse von `uga-rosa/translate.nvim`
(Apps-Script-Relay-Fund, Modernisierungs-Entscheidungen: gtx-Endpoint statt
Relay, `vim.json` statt Handrollen, API-Keys aus Config/ENV,
Provider-Registry-Pattern) — **[UMGESETZT WIE GEPLANT]**, vollständig wie
dokumentiert.

**Provider-Interface** — **[UMGESETZT WIE GEPLANT]**, inkl. echtem
`translate/providers/registry.lua` (im Gegensatz zu Spell tatsächlich als
eigenes Modul gebaut, mit `resolve(cfg)` → Fallback-Kette):

```lua
---@class LanguageTranslateProvider
---@field name      string
---@field available fun(cfg): boolean
---@field translate fun(lines, target, source, cfg, cb): Language.Job|nil
```

Provider: `google.lua` (Default, keyless gtx-Endpoint), `deepl.lua`
(offizielle API, Key aus Config/`$DEEPL_API_KEY`), `shell.lua`
(`trans`-CLI-Wrapper), `custom.lua` (User-CLI via `cmd`/`parse`).
**[UMGESETZT WIE GEPLANT]**

`filter.lua` (Fenced-/Inline-Code-Ranges) — **[UMGESETZT WIE GEPLANT]**, 1:1
aus der Vorarbeit portiert. `output/init.lua` (statt geplanter
`output/{replace,floating}.lua`-Aufteilung) — **[ANDERS ALS GEPLANT]**, ein
Modul mit `M.apply(mode, lines, ctx)` für `replace`/`float`/`notify`/
`clipboard`/`insert`. Alle fünf Modi sind implementiert — im Plan waren
`insert`/`register` noch „spätere Ausbaustufe“.

**Command**: `:Translate <lang> [--nocode] [--output=<mode>] [scope]` —
**[UMGESETZT WIE GEPLANT]** für den Grundfall, aber:
- `scope` unterstützt **kein** `cwd`/`path` (Completion bietet `cwd` an,
  Laufzeit lehnt mit Warnung ab). **[ANDERS ALS GEPLANT]** — der Plan sah
  `cwd|path=<p>` explizit als gültige Translate-Scopes vor.
- `:Translate!` (Bang) öffnet das interaktive Fenster. **[NEU, NICHT
  GEPLANT]**

**Explizit als „nicht für v1“ vorgemerkte Features — tatsächlich alle
gebaut:**
- Spaltengenaue Multi-Mode-Selection: **[NEU, NICHT GEPLANT für v1]** —
  `translate/motion.lua` übersetzt char-wise Motions/Visual-Selections exakt
  (Byte-genau, multibyte-sicher via `vim.fn.getregionpos`) statt nur
  zeilenweise. Line-/Block-wise fallen weiter auf Zeilenbereiche zurück.
- Interaktives Floating-Window mit Live-Übersetzung: **[NEU, NICHT GEPLANT
  für v1]** — `translate/window.lua`, zwei Floats (editierbarer Input +
  read-only Output), debounced Live-Übersetzung, `<C-l>` Retarget, `<C-r>`
  Reverse/Round-Trip, `<C-h>` History, `<C-y>` Copy. Aktionen bewusst nur im
  **Normal-Mode** gebunden, damit Insert-Mode-Tasten (`<C-h>`=Backspace etc.)
  nicht überschrieben werden — eine Design-Entscheidung, die im Plan nicht
  vorkam.
- Query-History/Reverse-Translate: **[NEU, NICHT GEPLANT für v1]** —
  `translate/history.lua`, newest-first Ring mit Dedupe nach
  `(input,target)`, optionale JSON-Persistenz.
- Motion-Mappings (Textobjekte übersetzen): **[NEU, NICHT GEPLANT für v1]** —
  `g@`-Operator + Visual-Map, opt-in via `translate.keymaps.{operator,visual}`.

---

### Gemeinsame Infrastruktur

- `config/DEFAULTS.lua` / `config/init.lua` — **[UMGESETZT WIE GEPLANT]**,
  Config-Baum mit `spell`/`translate`-Teilbäumen, **plus** einem dritten
  `thesaurus`-Teilbaum. **[ANDERS ALS GEPLANT]**
- `bindings/usrcmds.lua` — **[UMGESETZT WIE GEPLANT]**, Muster wie
  `project_insight`.
- `bindings/keymaps.lua` — **[ANDERS ALS GEPLANT]**: registriert nicht nur den
  Spell-Panel-Keymap, sondern auch die Translate-Motion/Visual-Maps und den
  Thesaurus-Keymap. Alle opt-in (Default `false`).
- `bindings/autocmds.lua` — **[ANDERS ALS GEPLANT]**: kein Live-Scan-Trigger
  mehr direkt hier drin (nur noch `BufDelete`-GC + Weiterleitung an
  `spell/live.lua`, wenn `spell.live = true`); die eigentliche Live-Logik
  wanderte in ein eigenes Modul.
- `health.lua` — **[UMGESETZT WIE GEPLANT]**, zusätzlich: Node/cspell-Sidecar-
  Status. **[NEU, NICHT GEPLANT]**
- `plugin/language.lua` — **[UMGESETZT WIE GEPLANT]**
- `lua/language/init.lua` — Fassade. **[ANDERS ALS GEPLANT]** — tatsächliche
  Funktionen: `setup`, `spellcheck`, `translate`, `translate_window`,
  `translate_history`, `synonyms`, `open_panel`. Die geplante `M.spellcheck`
  existiert, `M.translate`/`M.open_panel` auch — plus drei ungeplante:
  `translate_window`, `translate_history`, `synonyms`.

---

### Scoping-Modell

`LanguageScope`-Objekt (`buffer|visible|cwd|path|selection`), einmal geparst
in `language/scope/init.lua`, durch Spell **und** Translate gereicht.
**[UMGESETZT WIE GEPLANT]** für Spell vollständig; für Translate mit der oben
genannten Einschränkung (kein `cwd`/`path`).

Für `cwd`/`path` bei Spell: externer CLI-Provider bevorzugt (`providers.cwd`),
sonst nativer Fallback über geladene Buffer. **[ANDERS ALS GEPLANT]** — der
Plan sah einen chunk-basierten nativen Scan über **alle** Dateien im Baum vor
(inkl. ungeladener); tatsächlich scannt der native cwd/path-Fallback nur
**bereits geladene** Buffer unter dem Pfad (`native.lua`s
`collect_loaded_under`), plus bei `path=<file>` das direkte Einlesen einer
einzelnen Datei. Kein rekursives Directory-Walking im nativen Fallback — dafür
ist man auf einen CLI-Provider (typos/cspell/codespell) angewiesen.

---

### Asynchronität & Cancellation

- Externe Prozesse laufen async über den eigenen `util/job`-Runner (nie
  `vim.fn.system`), Timeout konfigurierbar. **[UMGESETZT WIE GEPLANT]**
- Debounce für Live-Scan. **[UMGESETZT WIE GEPLANT]**
- **Cancellation-Token**: **[ANDERS ALS GEPLANT]** — nur bei **Translate**
  implementiert (`active`-Liste in `translate/init.lua`, ein neuer Lauf
  cancelt laufende Jobs). Bei **Spell** (cwd/path-CLI-Scans, cspell-Sidecar)
  gibt es zwar pro Job ein `.cancel()`, aber `collect.gather` trackt/cancelt
  **nicht** automatisch einen vorherigen Scan, wenn ein neuer getriggert wird
  — ein erneuter Trigger auf demselben Buffer läuft parallel statt den alten
  abzulösen. Beim Live-Scan verhindert nur der Debounce-Timer-Restart
  überlappende **Trigger**, nicht überlappende **laufende Requests** (der
  cspell-Sidecar bekommt bei schnellem Tippen ggf. mehrere offene Requests
  gleichzeitig, die alle beantwortet werden — kein Datenverlust, aber auch
  kein Abbruch alter Anfragen).
- **In-Memory-Ergebnis-Cache** (`lib.lua.memo`, pro `bufnr+changedtick`):
  **[NICHT UMGESETZT]** — jeder Scan/jedes Panel-Öffnen läuft komplett neu.
- **`lib.nvim.progress`-Feedback** bei cwd-Scans: **[NICHT UMGESETZT]** — nur
  eine abschließende `notify` mit Trefferzahl, kein Fortschrittsbalken
  während des Laufs.

---

### Config-Defaults (tatsächlicher Stand)

Verifiziert gegen `lua/language/config/DEFAULTS.lua`:

```lua
{
  spell = {
    providers = {
      order  = { "native", "lsp", "typos", "cspell", "codespell" },
      buffer = { "native", "lsp" },        -- "cspell_server" hier opt-in ergänzbar
      cwd    = { "typos", "native" },
      native = { spelllang = nil },
      lsp    = { enable = true, servers = { "harper_ls", "ltex" } },
    },
    filetypes = { "markdown","text","gitcommit","tex","rst","asciidoc","help" },
    default_scope = "buffer",
    live = false, live_scope = "visible", scan_debounce_ms = 400,
    word_split = { enable = true, min_length = 4 },
    max_highlights = 100, max_file_lines = 20000, skip_readonly = true,
    regions = { treesitter_spell = true, skip_urls = true, skip_emails = true },
    programming_dict = false,
    ui = { view = "picker", preview = true, group_by = "file", dedupe = true },
    dictionary = {
      ignore_file = vim.fn.stdpath("state") .. "/language/spell_ignore.txt",
      use_spellfile = true,
      replace_all = true,        -- ⚠ deklariert, aber nirgends verwendet (totes Config)
    },
    guard = { block_write_on_error = false }, -- ⚠ deklariert, aber nirgends verwendet
    keymaps = { panel = "<leader>ss", next = "]s", fix = "<leader>z=", fix1 = "<leader>z1" },
  },
  translate = {
    engine = "google", fallback = { "google" },
    default_output = "replace", default_input = "selection",
    default_langs = { "EN", "DE", "FR", "ZH", "JA" },
    default_target = nil,        -- NEU ggü. Plan: fixe Zielsprache für Motion/Visual-Maps
    nocode_default = false, timeout_ms = 8000,
    deepl = { api_key = nil },
    custom = nil,
    history = {                  -- NEU ggü. Plan
      enable = true, max = 50, persist = false,
      file = vim.fn.stdpath("state") .. "/language/translate_history.json",
    },
    keymaps = { operator = false, visual = false },  -- NEU ggü. Plan
  },
  thesaurus = {                  -- NEU, eigener Top-Level-Baum, im Plan nicht vorgesehen
    enable = true, source = "datamuse", max = 20, timeout_ms = 6000,
    keymap = false,
  },
  commands = true,
}
```

---

## Modul-Layout (tatsächlicher Stand)

Verifiziert per Glob über `lua/language/**/*.lua` (43 Dateien):

```
plugin/language.lua
lua/language/init.lua
lua/language/health.lua
lua/language/@types/init.lua
lua/language/scope/init.lua                              -- geteilter Scope-Parser
lua/language/util/job/init.lua                            -- eigener argv-Job-Runner (statt lib.cross.run)
lua/language/config/{DEFAULTS,init,@types/init}.lua

lua/language/spell/@types/init.lua
lua/language/spell/init.lua                               -- Session/Facade
lua/language/spell/live.lua                                -- NEU: entkoppelter Live-Scan
lua/language/spell/programming_dict.lua
lua/language/spell/data/programming.lua
lua/language/spell/core/{collect,actions,ignore,split,regions}.lua   -- statt context/store/scan
lua/language/spell/providers/{native,typos,codespell,cspell,cspell_server,lsp,util}.lua
lua/language/spell/ui/{panel,item_menu,list}.lua           -- statt panel/item_menu/highlights/diagnostics

lua/language/translate/@types/init.lua
lua/language/translate/init.lua
lua/language/translate/{filter,motion,window,history}.lua  -- motion/window/history NEU
lua/language/translate/output/init.lua                     -- ein Modul statt replace.lua+floating.lua
lua/language/translate/providers/{registry,google,deepl,shell,custom}.lua

lua/language/thesaurus/init.lua                             -- NEU, eigene Top-Level-Domäne

lua/language/bindings/{usrcmds,keymaps,autocmds}.lua

node/cspell_server.js                                       -- NEU: Node-Sidecar

doc/language.txt
docs/ROADMAP/ROADMAP.md
README.md
stylua.toml
.luarc.json                                                  -- NEU, im Plan nicht erwähnt
.gitignore                                                   -- NEU (schließt doc/tags aus)
```

---

## Wiederverwendung aus lib.nvim

**[ANDERS ALS GEPLANT]** — deutlich schmaler als ursprünglich vorgesehen.
Tatsächlich genutzt:

| Zweck | lib.nvim-Modul |
|---|---|
| Notify | `lib.nvim.notify` |
| Keymaps/Usercmd | `lib.nvim.map`, `lib.nvim.usercmd` |
| Panel/Menu/Select | `lib.nvim.ui.kit` (`select`, `menu`) |

**Nicht verwendet, obwohl geplant:** `lib.nvim.cross.run`/`cross.uv.spawn_command`
(eigener Job-Runner statt), `lib.lua.json` (`vim.json` statt), `lib.lua.memo`
(kein Cache gebaut), `lib.nvim.progress` (kein Fortschrittsbalken gebaut),
`lib.nvim.fs.*`, `lib.nvim.git`, `lib.nvim.autocmd.augroup` (rohe
`vim.api.nvim_create_augroup` verwendet), `lib.nvim.ui.hl`,
`lib.nvim.window.*`, `lib.nvim.buf_win_tab.*`.

---

## Bekannte Lücken / totes Config

Explizit für Nachvollziehbarkeit festgehalten (kein Aufruf zum sofortigen
Nachbauen — nur Dokumentation des Ist-Zustands):

1. **`spell.guard.block_write_on_error`** — Config-Feld existiert, keine
   `BufWriteCmd`/Autocmd prüft es. Schreiben mit offenen Spellcheck-Issues
   wird nie blockiert.
2. **`spell.dictionary.replace_all`** — Config-Feld existiert, wird nirgends
   gelesen. Das faktische Verhalten „Vorschlag auf alle Vorkommen anwenden“
   existiert nur als **eigener Menüpunkt** („Replace all in buffer…“), nicht
   als automatisches Verhalten hinter diesem Flag.
3. **Kein Ergebnis-Cache.** Jeder Panel-Open/Refresh scannt neu. Bei sehr
   großen cwd-Scopes ohne CLI-Provider kann das spürbar sein.
4. **Kein Progress-Indicator** für lang laufende cwd/path-Scans — nur ein
   abschließendes `notify`.
5. **Kein generisches Cancellation für Spell-Scans** — siehe
   [Asynchronität & Cancellation](#asynchronitt-cancellation).
6. **Keine Inline-Disable-Direktiven** (z. B. `language:disable-line`).
7. **`:Translate` bietet `cwd` in der Completion an, lehnt es aber zur
   Laufzeit ab** — kleine UX-Inkonsistenz (Completion vs. tatsächliches
   Verhalten).
8. **Kein natives rekursives Directory-Walking** für Spell-`cwd`/`path` ohne
   externen CLI-Provider — nur bereits geladene Buffer werden erfasst.

---

## Umsetzungs-Historie

Tatsächlicher Ablauf (Commits auf `language.nvim` main), zum Abgleich mit den
ursprünglich geplanten 9 Phasen:

1. Gerüst + Scope-Parser + Spell-Kern (native) + Translate-Kern (Google) —
   entspricht Plan-Phasen 1–4, in einem Rutsch umgesetzt statt einzeln.
2. Panel-UI + Async-Fundament (Job-Runner) — Plan-Phase 5.
3. Perf-/Code-Features (word_split, Treesitter-Regionen, Caps,
   programming_dict) — Plan-Phase 6.
4. Weitere Provider (deepl/shell/custom, typos, LSP-Grammar-Harvest) —
   Plan-Phase 7.
5. Config-Cleanup in der nvim-Config — Plan-Phase 8 (mit dem oben erwähnten
   Zwischenfall: `plugins/language.lua` ging verloren, Folge-Commit
   `ba47a088`).
6. Doku (`doc/language.txt`, ROADMAP, README) — Plan-Phase 9.
7. **Nicht geplante Erweiterungsrunde** (auf Anfrage nachträglich
   priorisiert): cspell/codespell-CLI-Provider → LSP-Grammatik-Fixes im Panel
   → Live-Scan (entkoppelt) → Translate-Motion/Visual-Maps → interaktives
   Translate-Fenster → Reverse/Round-Trip → Query-History →
   spaltengenaue Übersetzung → Thesaurus → **persistenter cspell-Sidecar**
   (inkl. Windows-`.cmd`-Fix als Nebenfund).

Alle Schritte der Erweiterungsrunde waren im ursprünglichen Plan entweder gar
nicht vorgesehen oder explizit als „spätere Ausbaustufe“ zurückgestellt.

---

## Verifikation

Die im Original geplanten Verifikationsschritte wurden headless durchgeführt
(nicht interaktiv im echten Editor) — mit einer Ausnahme:

- **Spell-Parität, Scoping, Code-Splitting, Panel/Actions, Live-Scan,
  Translate-Parität, Provider-Matrix (Google/DeepL/Fallback):** alle headless
  gegen echte Testbuffer verifiziert. **[UMGESETZT WIE GEPLANT]**
- **cspell/codespell/cspell-Sidecar:** zusätzlich **live gegen echtes
  installiertes `cspell` 10.0.1 + Node v26** verifiziert (nicht nur simuliert)
  — ging über die ursprüngliche Planung hinaus, da zum Planungszeitpunkt kein
  `cspell` auf der Maschine installiert war.
- **Async/Freeze-Test „zweiter Trigger cancelt ersten“:** **[NICHT WIE
  GEPLANT VERIFIZIERT]** — da das Cancellation-Token für Spell-Scans nie
  gebaut wurde (s. o.), konnte dieser Testfall so nie bestehen; er wurde
  nicht in dieser Form durchgeführt.
- **Progress-Sichtbarkeit bei cwd-Scans:** **[NICHT VERIFIZIERT]** — da kein
  Progress-Feedback implementiert wurde.
- **Cross-Plattform-Smoke:** durchgeführt, und dabei den echten
  Windows-`.cmd`-Bug gefunden und gefixt (s. o.) — der ursprüngliche Plan
  ("Pfad-/Prozessaufrufe über `lib.cross`") hätte diesen Bug so nicht
  aufgedeckt, da der eigene Job-Runner das Problem erst einführte (und
  gleich mitfixte).
- **Cleanup-Verifikation:** durchgeführt, mit dem oben dokumentierten
  Zwischenfall (verlorene Datei, per Folge-Commit behoben).

---

