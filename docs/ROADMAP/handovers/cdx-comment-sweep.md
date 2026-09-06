# Handover — CDX-Kommentar-Sweep über nvim-config + alle Plugins

## Table of content

  - [Ziel](#ziel)
  - [Vorgehen (User-Entscheidungen)](#vorgehen-user-entscheidungen)
  - [Der `--- CDX:`-Tag](#der----cdx-tag)
  - [Wohin welches Wissen](#wohin-welches-wissen)
  - [Fortschritt](#fortschritt)
  - [Relocation-Log](#relocation-log)
  - [Wiederkehrende Fund-Muster](#wiederkehrende-fund-muster)

---

## Ziel

Jede Datei in der nvim-config und in allen 31 Plugin-Repos durchgehen. Im
Source-Code soll in den Kommentaren **nur stehen, was für genau diesen Platz
wichtig ist**. Alles andere:

- **Auffällig, aber Urteilssache** → `--- CDX:`-Tag setzen (nicht sofort fixen)
- **Klarer Fehler / Redundanz / Sprachverstoß** → direkt fixen
- **Wichtiges Wissen, das nicht in den Source gehört** (Design-Begründung,
  Messwerte, Neovim-/Lua-Mechanik) → **direkt umziehen** in Plugin-`docs/`
  bzw. WKDBooks, dann im Code nur ein Ein-Zeilen-Pointer

## Vorgehen (User-Entscheidungen)

- **Kalibrier-Häppchen zuerst:** ein Bereich komplett nach meinem Urteil, dann
  User-Review + Kalibrierung, dann Rest. Erstes Häppchen: `lua/autocmds/`.
- **Direkt umziehen:** Wissen wandert gleich in die Ziel-Datei, Commit/Push
  auch in die WKDBooks. Handover verweist dann nur noch drauf.
- Nie mehr als 1 Agent gleichzeitig. Antworten deutsch, Code/Kommentare englisch.
- Nach jedem Häppchen: stylua/luacheck (falls vorhanden), commit, push auf `main`.
- Keine Claude-Co-Authorschaft in Commits.

## Der `--- CDX:`-Tag

Format: `--- CDX: <kurze Beschreibung des Funds>` (englisch, drei Striche =
LuaLS-Doc-Kommentar), an der auffälligen Stelle.

**User-Kalibrierung (nach Häppchen 1):**
- **`--- CDX:` einheitlich** — bestehende eigene Marker (`-- FIX:`, `-- AUDIT:`,
  `-- SUPERSEDED:`) werden zu `--- CDX:` umbenannt **und** ins Englische
  übersetzt. Ausnahme: `SUPERSEDED:` bleibt sinnvoll wo es echt „ersetzt durch
  X" heißt — dann `--- CDX: SUPERSEDED …`.
- **Trimm-Härte: moderat** — klare Redundanz/Doppelung/Sprachverstöße fixen,
  überlange Rationale kürzen aber Substanz behalten, USAGE-Blöcke zu
  Parameter-Listen eindampfen, Zweifelsfälle taggen.
- **Toter Code: gleich löschen wenn eindeutig** (kein Aufrufer im ganzen Repo,
  keine externe API). Zweifel → taggen. Im Commit vermerken.
- **Redundante Kommentarzeilen entfernen** wenn sie nichts über Nachbar-Zeilen
  (Sektionskopf, `desc`, Funktionsname) hinaus sagen.

## Wohin welches Wissen

Alle drei WKDBooks-Ziele liegen im **selben Repo** `StefanBartl/WKDBooks`
(`E:/repos/WKDBooks/`), ein Commit deckt alle ab.

| Wissensart | Ziel |
| --- | --- |
| Plugin-spezifische Design-Begründung, Messwerte, „warum so gebaut" | `E:/repos/WKDBooks/Development/wkdbook-myplugins/<plugin>.nvim/NOTES/` **oder** das Plugin-eigene `docs/` |
| Neovim-Mechanik (Event-Timing, API-Eigenheiten, `on_key`, `:split`-Semantik …) | `E:/repos/WKDBooks/Development/wkdbook-Neovim/MyNotes/` |
| Lua-/LuaLS-Mechanik | `E:/repos/WKDBooks/Development/wkdbook-Lua/` (passende Unterordner: `LuaLanguageServer/`, `Async/`, …) |
| Nicht-`vim.health`-relevante Config-Interna | nvim-config `docs/` |

wkdbook-Neovim/MyNotes-Stil: deutsch, informell, Emoji-Header erlaubt,
verknüpft das Allgemeinwissen mit dem konkreten Auslöser-Fall.

---

## Fortschritt

### Häppchen 1 — `lua/autocmds/` (16 Dateien)

**Status: erledigt, wartet auf User-Kalibrierung.**

Direkt gefixt:
- 4× `defaults.lua`: `-- AUDIT: Optionen beschreiben` (deutsch) → `--- CDX:` englisch
- `general/defaults.lua`: `enable = true, -- Disabled by default` — Widerspruch entschärft
- `init.lua`: 2 deutsche `AUDIT/FIX`-Marker → englische `CDX:`; die 6-Zeilen-
  `SUPERSEDED:`-Einzeiler-Wüste bei `no_name_guard` auf 4 knappe Zeilen
- `git/init.lua`: deutscher `FIX:` → englischer `CDX:`
- `auto-center-fexplorer.lua`: 27-Zeilen-Header (mit falschen `require`-Pfaden
  `auto-center-explorer`, deutschen Wörtern) → 11 Zeilen; `on_key`-Kommentar
  7 → 5 Zeilen
- `explorer-singleton.lua`: Header-Absatz raus, der den Inline-Kommentar
  wörtlich doppelte; „Known imprecision" 9 → 6 Zeilen; Inline-WinEnter-Kommentar
  7 → 4 Zeilen; **0 Code-Änderungen**
- `text/init.lua` + `terminals/init.lua`: 6× `-- Description:`-Zeilen raus
  (doppelten `desc =`); doppeltes `autocmd_lib`/`Autocmd`-Local zusammengelegt
- `text/init.lua`: Smart-Quotes → ASCII

Nach Kalibrierung nachgezogen: `general/helpers.lua` `M.snorm_pattern`
**gelöscht** (toter Code, kein Aufrufer im ganzen Repo, „markdown"-Default =
Copy-Paste-Rest).

`--- CDX:` gesetzt (Urteilssache, nicht gefixt):
- 4× `defaults.lua` — Felder undokumentiert
- `init.lua` — Submodul-Setup-Calls in eigene Module; `no_name_guard` nach
  filetree.nvim migrieren (Liste 1)
- `git/init.lua:38` — true/false/nil-Branches wegstrukturieren

Umgezogen: siehe [Relocation-Log](#relocation-log).

stylua ok. luacheck: nur die 106 vorbestehenden `vim`-global-Warnungen
(kein `.luacheckrc` in diesem Kontext), 0 errors, nichts von mir verursacht.

### Häppchen 2 — `lua/bindings/mappings/` (23 Dateien, ~2400 Z.)

**Status: erledigt.** `lua/bindings/` gesamt ist riesig (87 Dateien, 22.774 Z.) —
in Sub-Häppchen. `mappings/` war das erste.

Direkt gefixt:
- **Toter kommentierter Code gelöscht** (Kalibrierung: „gleich löschen"):
  `general.lua` (`<C-s>`-Block + 2 Zeilen), `nvchad.lua` (`<leader>ch`),
  `telescope.lua` (9 Zeilen), `terminal.lua` (~30-Zeilen-Block
  `toggle_vterm_one_third`), `buf_win_tab.lua` (`<tab>`), `init.lua`
  (`view_scroll`).
- Deutsch → Englisch: `editing.lua:298` + `general.lua` (3 Kommentare, 2 `desc`
  User-sichtbar!).
- `buffer_jump.lua`: sinnloses `if type(map) ~= "function"` Re-require raus;
  „matches the tabufline implementation **you quoted**" (Chat-Artefakt) gefixt.
- `init.lua`: kaputte Doku-Referenz `PersonelPlugins/BINDINGS/Keymaps/
  Collisions.md` → `docs/NOTES/CrossPlugin/Keymaps-Collisions.md`.
- Lange Header/Doc-Blöcke moderat gekürzt: `editing.lua` (Header 29→11,
  3 Doc-Blöcke halbiert), `treesitter_structure.lua` (Header **58→18**),
  `terminal.lua`, `explorer`-Sachen.

`--- CDX:` gesetzt:
- `snacks.lua` — ganze Datei tot (nie required); `GD` doppelt gemappt
- `sourrounding.lua` — Dateiname-Tippfehler (→ `surrounding`)
- `smart_del_key.lua` — `map_cr`/`set_cr`-Mismatch, `<CR>`-Map nie implementiert
- `toggle_comment.lua` — Annotation-Branching zwischen 2 Funktionen kopiert
- `buffer_jump.lua` — 5 Fallback-Strategien + spekulatives `go_to`
- `general.lua` — `<leader>date` auch in buffer-ctx.nvim

stylua ok, luacheck 0/0 (mit `.luarc`/`.luacheckrc`).

### Häppchen 3 — `lua/bindings/usrcmds/bindings_explorer/` (13 Dateien, ~6000 Z.)

**Status: erledigt** (bis auf `drift.lua`, s.u.). Der Subtree war
**durchgängig deutsch kommentiert** — vor allem ein Übersetzungs-Job.

- **Alle Code-Kommentare Deutsch → Englisch** in allen 13 Dateien (config,
  init, live, ui, search, browse, records, plugin_scope, status, report;
  source/repo/drift waren schon Englisch). −72 Netto-Zeilen.
- **User-sichtbare Strings bleiben Deutsch** — `:Bindings` gibt bewusst und
  durchgängig deutsch aus (siehe status.lua/report.lua). `--- CDX:` in
  `init.lua`: „behalten oder auf Englisch wie der Rest?"
- **`--- CDX:` in `config.lua`**: `BND-05` hat `docs/NOTES/PersonelPlugins/
  BINDINGS/` **gelöscht** (verifiziert: Ordner weg), aber `M.roots()` gibt ihn
  weiter als `roots()[1]` zurück. Der Korpus-Walk ist durch `isdirectory`-
  Guards harmlos, aber **`:Bindings path personal` kopiert einen toten Pfad**.
  Funktionaler Entscheid nötig: `roots()` auf Extern-only kürzen?
- Stale Refs gefixt: gelöschte `docs/ROADMAP/personal/bindings-explorer.nvim.md`
  → `docs/FEATURES.md` (init, config, browse); `plugin.lua`/`plugin.resolve`
  → `plugin_scope` (search, browse).
- Header von init/live/ui/search moderat gekürzt.

stylua --check + luacheck grün (13 Dateien).

**`drift.lua` (2812 Z.) noch offen** — bereits Englisch, keine Chat-Artefakte,
aber sehr lange Prosa-Blöcke. Eigener Trim-Pass sinnvoll (kein dringender
Regelverstoß).

### Häppchen 4 — `lua/bindings/usrcmds/case/` (39 Dateien, 11.295 Z.)

**Der Brocken. Status: erledigt.** casedesk (HandOverCase) ist ein
**deutsch-domänen** Support-Ticket-Tool: viele Kommentare deutsch, viele
Ausgabe-Strings bewusst deutsch, plus deutsche Domänen-Daten (SLA-Begriffe,
Solution.md-Überschriften-Maps).

**Runde 1** (Commit f579694cc): `config.lua`, `solution.lua`, `similar.lua`,
`init.lua` (Teil), `sla/init.lua`.

**Runde 2 (rest, dieser Commit):** alle noch deutschen Code-Kommentare in den
verbleibenden Dateien übersetzt:
- `ui.lua` — 6 Kommentarblöcke (`:Case solution`/`solutions` Header,
  `SOLUTION_PREVIEW_LINES`, `cursor_below_heading`, `solution_row`, 2 Inline-
  Kommentare in `M.solution`, der `do_move` „solution verlorengeht"-Block) +
  `<paket>` → `<package>` in einem Beispiel-Kommentar.
- `solution.lua` — 2 Reste (`M.path` Doc, `parse_keywords` Doc).
- `extract/stream.lua` („Vollständigkeits-Check" → "Completeness check"),
  `extract/facts.lua` („Richtung 1" → "direction 1"),
  `extract/supportinfo.lua` („Kopfzeile 4"/„Parser-Falle" → englisch),
  `extract/doclinks.lua` (englischer Gloss hinter dem Zitat),
  `commands.lua` („+N Zeilen" → "+N line-count").
- `doctor.lua`, `init.lua` (Rest), sowie alle übrigen ~24 Dateien
  (terminology, ki, query, ocr, …) waren bereits vollständig englisch —
  keine Änderung nötig.

**Kein `--- CDX:` gesetzt, kein toter Code entfernt** — alles war saubere
Übersetzung oder bewusster Keep.

**Behalten (User-Kalibrierung):**
- Deutsche String-Literale (User-UI von `:Case`/`:Cases`: `notify`, Header,
  `:format`-Ausgaben, Picker-Spalten wie `"[wörtlich]"`, `"Schlagworte: …"`).
- Deutsche Daten-Maps/Werte (`ALIASES`, `solution_statuses`, Stoppwörter,
  SLA-`label`s `Rückmeldung`/`Korrekturmaßnahme`, Dateiname
  `SummaryTemplateBefüllt.md`).
- Attribuierte deutsche Doc-Zitate in englischen Kommentaren (EXTRACTION.md
  §2/§3/§8/§13 „…", SLA.md §6B/§6C „…", ROADMAP.md „marking system wie in
  filetree.nvim", „LÖSCHEN"). Bei zweien einen kurzen englischen Gloss ergänzt.
- **`Paket N`** als Doc-Struktur-Referenz (EXTRACTION.md/SLA.md/SESSIONS.md
  gliedern die Arbeit in „Pakete", analog zu `§13`) — bewusst **nicht**
  übersetzt, sonst desynct die Referenz. ~15 Vorkommen.
- Deutsche Beispiel-Prosa in `links.lua:78` („ändern Sie den Wert von …") —
  illustriert die Art Fließtext, die der Parser in den (deutschen) Case-Docs
  antrifft; wie ein attribuiertes Zitat behandelt.

stylua ok, luacheck 0/0 (39 Dateien).

### Häppchen 5 — `drift.lua` (Prosa-Trim, 2812 Zeilen)

**Status: erledigt.** Reiner Trim-Pass, keine Übersetzung nötig (war schon
Englisch, keine Chat-Artefakte).

- **Modul-Header 210 → 46 Zeilen** (von mir direkt, vor dem Agenten-Pass):
  der Header duplizierte praktisch vollständig, was ausführlicher in
  `docs/FEATURES.md` (Abschnitt „Drift-Bericht") auf Deutsch steht, nur mit
  mehr Historie/Datumsangaben/Messwerten. Gekürzt auf das, was ein
  Code-Leser tatsächlich braucht, plus Pointer auf FEATURES.md.
- **Rest der Datei** (Agent, 2665 → 2558 Zeilen, −220 netto): der Header
  hatte recht — der restliche Code war bereits überwiegend knapp und
  ortsrelevant. Keine Chat-Artefakte, kein Deutsch, keine
  Kommentar-Code-Widersprüche gefunden, daher **kein** `--- CDX:` gesetzt und
  **kein** toter Code entfernt (`M.source_check` sieht unbenutzt aus, ist
  aber explizit als eigenständige Public API dokumentiert — bewusst
  belassen). Gekürzt wurden gezielt Dopplungen: `stem_plugin`/
  `subroute_exists`/`script_path`/`command_owner`-Docs (letzterer stand
  sogar **zweimal fast wortgleich im Code selbst**), die SECTIONS-Tabellen-
  Notiz, die Autocmds-Achse-Einleitung, der Repo-Scan-Reset-Kommentar — alle
  dupliziert bereits Abschnitte aus FEATURES.md.
- stylua ok, luacheck 0/0.

Commits: nvim-config `364118c25`, WKDBooks `0ca6a86` (Relocation, s.u.).
Beide ohne Co-Authored-By, beide gepusht + `pull --ff-only` bestätigt.

### Häppchen 6 — `usrcmds/`-Rest + `telemetry.lua` (6 Ziele, ~1620 Zeilen)

**Status: erledigt.**

- `context_open/`, `who_locks/`, `update_repos/` — keine Änderungen, bereits
  sauber (Englisch, kein toter Code, keine Widersprüche).
- `autocmd_docs/` + `usrcmds/init.lua` — deutsche notify/desc-Strings ins
  Englische übersetzt. **Judgement-Call:** anders als `case`/
  `bindings_explorer` (bewusst deutsch-domänig) ist beides generisches
  Dev-Tooling neben rein-englischen Geschwister-Kommandos — als
  Sprachversehen behandelt, nicht als bewusste Deutsch-UX. `usrcmds/init.lua`
  zusätzlich: redundante Boilerplate-Zeile raus, eigener `--FIX:`-Marker
  (Tippfehler „Funktoinert") zu `--- CDX:` vereinheitlicht.
- **`lua/config/telemetry.lua`** — Handover-Listenfehler korrigiert: liegt
  unter `lua/config/`, nicht `usrcmds/`.
  - **Fund:** die Datei zitierte Einzeldezimal-Kostenwerte
    (0.014/0.619/0.394 µs/call) aus `runtime-analysis.nvim`s eigenem
    README — das README selbst nennt genau solche Werte „false precision"
    und verweist auf sein reproduzierbares Bench-Script. Die Config-Datei
    widersprach also der eigenen zitierten Quelle. Gekürzt zu einem Pointer.
  - **Fund:** toter Link `docs/COMMANDS.md` → `docs/commands.md` (Datei
    existiert nur lowercase; auf Windows unsichtbar, bricht auf
    case-sensitiven Systemen) — gefixt.
  - Allgemeine lazy.nvim-Mechanik (`FileType` feuert vor `User LazyLoad`)
    ausgelagert, s. Relocation-Log.
- Kein toter Code gefunden (anfänglicher Verdacht zu `who_locks`/
  `update_repos` widerlegt — beide werden direkt aus root-`init.lua`
  aktiviert, nicht über `usrcmds/init.lua`).
- stylua ok, luacheck 0/0 (9 Dateien).

Commits: nvim-config `7bff3c7f6`, WKDBooks `09888c3`. Beide ohne
Co-Authored-By, gepusht + `pull --ff-only` bestätigt.

### Häppchen 7 — `usrcmds/plugin_repos/` (3 Dateien, 1641 Zeilen)

**Status: erledigt. `lua/bindings/` damit vollständig durch (87/87 Dateien,
22.774 Zeilen).**

- Alle 3 Dateien bereits komplett Englisch — keine Übersetzung nötig.
- `init.lua`: Modul-Header 68→20 Zeilen — duplizierte fast vollständig das
  bereits existierende, gute `README.md` im selben Ordner (271 Z.). Diesmal
  kein Umzug nötig, das Wissen lag schon am richtigen Ort, nur der Code
  kopierte es zusätzlich.
- **Fund:** `M.enable()`s Docstring zählte nur **4 von 10** registrierten
  Subcommands auf (`clone|remove|mode|list` — `fetch|pull|update|reclone|
  dashboard|picker` fehlten), offenbar nie nachgezogen als neue
  Subcommands dazukamen. Klarer Kommentar-Code-Widerspruch → direkt
  gefixt (Verweis auf Header statt eigene Dritt-Aufzählung).
- Kein toter Code, kein `--- CDX:`-Tag nötig.
- stylua ok, luacheck 0/0.

**Notiert für später, nicht in diesem Häppchen behoben:**
- `lua/plugins/personal/source.lua` (referenziert `:MyPlugins mode`) ist
  komplett deutsch kommentiert — Kandidat für den `lua/plugins/`-Häppchen.

Commit: nvim-config `c0fbdc6b7`. Ohne Co-Authored-By, gepusht +
`pull --ff-only` bestätigt.

### Häppchen 8 — `lua/config/` kleine Ordner + `ui_open.lua` (16 Ziele, ~2670 Zeilen)

**Status: erledigt.** `@types`, `lazygit`, `telescope` bereits sauber, keine
Änderung. Bei allen anderen: deutsche Kommentare übersetzt, eigene
`FIX:`/`AUDIT:`-Marker zu `--- CDX:` vereinheitlicht, redundante
Kommentare (dopplen Funktionsnamen) entfernt, überlange Rationale gekürzt.

**⚠️ Echter Funktionsbug gefunden, nicht gefixt (außerhalb Sweep-Scope):**
`lua/config/noice/init.lua` — eine catch-all-Route
(`{ filter = { event = "msg_show" }, view = "mini" }`) matcht **jede**
`msg_show`-Nachricht; `noice.message.router.lua` bricht beim ersten Match
ab (`opts.stop` default `true`). Damit sind **alle danach folgenden
Routes tot**: „search hit BOTTOM/TOP"-Verstecken, mehrere
emsg-Hides (E23/E20/E37/E31/E351/E418), „No signature help", der
`search_count`-Hide — keines davon feuert je. Mit `--- CDX:` markiert
(eine Reihenfolge-Änderung wäre eine Logikänderung, nicht Teil dieses
Sweeps) — **Autorenentscheidung nötig, ob das gefixt werden soll.**

**Weitere Funde:**
- Alle drei nebeneinanderliegenden KI-Assistent-Configs
  (`config/ai/anthropic` [Avante], `config/copilot`, `config/gp_config`
  [gp.nvim]) sind **aktuell verwaist** — die zugehörigen
  `lua/plugins/ai/{avante,copilot,gp}.lua`-Specs sind komplett
  auskommentiert. `copilot/nes_guard.lua` war zusätzlich toter Code (0
  Aufrufer) → gelöscht. `copilot/cmp.lua`s Bridge-Fragment läuft noch,
  ist aber ein No-op ohne installiertes Copilot-Plugin.
- `menu/`: ein nutzloser Ternary (`ok_gs and "gitsigns" or "gitsigns"` —
  beide Branches identisch) → `--- CDX:`.

Ausgelagert nach WKDBooks (Commit `c9fdbe7`):
- `lua/config/lazy/init.lua` → `wkdbook-Neovim/MyNotes/
  lazynvim-checker-git-fetch-storm.md` (neu) — Checker-Mechanik,
  EDR-Fetch-Sturm, Messwerte.
- `lua/config/snacks/picker/init.lua` → `wkdbook-Lua/LuaLanguageServer/
  Annotations/inline-table-fun-swallows-fields.md` (neu) — LuaLS-Quirk:
  inline `fun(): T` in Tabellentyp verschluckt nachfolgende Felder.
- `lua/config/ui_open.lua` → `wkdbook-Neovim/nvim-lua-api/
  LuaModule-vim.ui.md` (neue Sektion) — Windows-cmd.exe-`&`-URL-
  Truncation-Bug.

stylua ok (16 Dateien). luacheck 0/0 auf 15/16 (1 Datei von luachecks
eigenem `@`-Präfix-Glob übersprungen — vorbestehend, stylua deckt sie ab).

Commit: nvim-config `20204478c`. Ohne Co-Authored-By, gepusht +
`pull --ff-only` bestätigt.

### Häppchen 9 — `lua/config/harpoon/` (12 Dateien, 1943 Zeilen)

**Status: erledigt.** Ordner war schon fast durchgehend auf Sweep-Qualität
(9 von 12 Dateien 0 Änderungen) — nur `types/init.lua`, `health.lua`,
`preview.lua` hatten etwas.

**Echte Typ-Fixes in `types/init.lua`** (reine Annotation, keine
Laufzeit-Logik-Änderung):
- `Cfg.Harpoon.HardeningState` deklarierte nur 3 von 5 tatsächlichen Feldern
  aus `hardening.lua` — fehlten `wrapped_ui`/`augroup`. Genau die Falle, vor
  der der Nachbar-Kommentar bei `Cfg.Harpoon.List` selbst warnt. Gefixt.
- `Cfg.Harpoon.Api` gelöscht (toter Typ, nirgends referenziert, zusätzlich
  schon veraltet — fehlte das `.config`-Feld).
- Verwaiste `---@type uv uv`-Zeile ohne zugehörige Deklaration gelöscht.
- `HardeningOpts`-Tuning-Doku (SSD/Netzwerk-Debounce-Werte) ausgelagert nach
  `docs/NOTES/Harpoon.md` §6 „Tuning" (bereits die autoritative Referenz für
  dieses Modul — kein WKDBooks-Umzug nötig).

**`--- CDX:` gesetzt (Zweifelsfälle, nicht gefixt):**
- `preview.lua`s `resolve_layout()`: `require("config.harpoon.preview_layout")`
  referenziert ein Modul, das **nirgends im Repo existiert** (auch vom
  eigenen `docs/map`-Tool als `require-not-declared` geflaggt) — fällt
  immer auf Fallback-Layout zurück. Erweiterungshaken oder toter Verweis,
  Entscheidung offen.
- `Cfg.Harpoon.NormKeyOpts` — nirgends per `@param`/`@cast` verdrahtet.

stylua/luacheck: beide grün, 0/0 auf allen 12 Dateien.

**Nebenfunde, nicht bearbeitet (außerhalb Scope, keine `.lua`-Dateien):**
- `harpoon/docs/GoodToKnow.md` ist massiv veraltet und stellenweise
  korrupt (Text bricht mitten im Satz ab) — beschreibt eine überholte
  Modulstruktur. Eigener Aufräum-Punkt wert.
- `harpoon/docs/ROADMAP.md` (3 Punkte) wirkt größtenteils schon erledigt.

Commit: nvim-config `7c2a847ba`. Ohne Co-Authored-By, gepusht +
`pull --ff-only` bestätigt.

### Häppchen 10 — `lua/config/neotest/` (21 Dateien, 1836 Zeilen)

**Status: erledigt.**

**Wichtigster Kontext-Fund:** `docs/ROADMAP/IDEAS/test.md` (bereits
existierend, nicht Teil des Scopes) dokumentiert bereits vollständig ein
„Adapter-Split-Brain"-Problem: `plugins/neotest.lua`s `opts.adapters` ist
hartcodiert auf `plenary/vitest/go`, ignoriert `adapters/factory.lua` +
`init/utils.lua`s `build_adapters()` komplett — Python/Rust/TypeScript sind
installiert, aber nie aktiv. Da der Plan die Konsolidierung bewusst über
eine Migration vorsieht (nicht stückweises Wegräumen vorher), habe ich dort
**nicht gelöscht**, nur mit `--- CDX:` auf den Plan verwiesen. Umgekehrter
Fall zur „Roadmap veraltet"-Lektion: hier war der Punkt noch **aktuell**.
Eine Lücke im bestehenden Plan gefunden: `neotest-vim-test` ist als
Dependency gelistet, hat aber gar keinen Adapter-Builder — im bestehenden
Doc nicht erwähnt, jetzt ergänzt.

**⚠️ Zwei echte Laufzeitbugs gefunden, nur getaggt (nicht gefixt,
Logikänderung außerhalb Sweep-Scope):**
- `whichkey/init.lua:69` — `<leader>ntS` ruft `actions.stop_tests()` auf,
  aber `actions/init.lua` definiert nur `M.stop()`. Crasht bei Auslösung
  ("attempt to call a nil value").
- `debug/init.lua` (`:NeotestDebugRoot`) — liest `ts_config.adapter.root`,
  aber `adapters/typescript.lua` exportiert nur `M.create()`, kein
  `.adapter`-Feld. Bedingung ist immer `false`, TS-Root-Detection läuft nie.

**Direkte Fixes (Annotation/Redundanz, keine Logikänderung):**
- `@types/neotest.lua`: `---@module`-Tippfehler `NeoTest`→`neotest`.
- `commands/init.lua`: Header listete 10 von 11 Usercommands
  (`:NeotestClearAll` fehlte) — gleiches Muster wie Häppchen 7.
- `neotree/init.lua`: doppelter `---@module`-Block zusammengelegt.
- `docs/COMMANDS.md`: toter TOC-Chat-Artefakt-Rest entfernt, Hinweis
  ergänzt dass Auto-Discovery aktuell inaktiv ist.

**Übersetzt:** `adapters/typescript.lua`, `autocmds/auto_discovery.lua`,
`debug/init.lua` (`KORREKTUR:`/`KRITISCH:`-Marker), `init/checks/adapter.lua`,
`init/icons.lua`, `neotree/init.lua`, `utils/validate_consumer.lua`
(komplett deutsch, wie zuvor bei bindings_explorer/case).

Kein toter Code direkt gelöscht — alle Kandidaten (`AdapterConfig`/
`Position`/`Result`/`RunOpts`-Typen, `autocmds/auto_discovery`,
`init/checks/adapter`) sind Teil des bereits dokumentierten
Migrationsplans, dafür `--- CDX:` mit Verweis auf `test.md`.

stylua ok, luacheck 0/0 (19/21 — 2 `@types/*`-Dateien vom luacheck-Glob
übersprungen, wie schon bei harpoon). Kein WKDBooks-Umzug nötig.

Commit: nvim-config `b0b3b8648`. Ohne Co-Authored-By, gepusht +
`pull --ff-only` bestätigt.

### Häppchen 11 — `lua/config/neotree/` (29 Dateien, 1923 Zeilen)

**Status: erledigt. `lua/config/` damit komplett durch** (Häppchen 6, 8,
9, 10, 11 zusammen).

**Echte Typ-Fixes (reine Annotation):**
- `@types/node.lua`: `is_directory`/`get_parent_id` waren als `boolean`-Felder
  typisiert, sind aber Methoden (belegt durch eigene tote Stub-Funktionen im
  selben File **und** `@types/README.md`) — auf `fun(self): ...` korrigiert,
  dabei bisher undokumentierte `is_file`/`get_path`/`get_name` ergänzt.
- `@types/config.lua`: `Cfg.NeoTree.InitOpts` fehlten `window_debug`/
  `window_open`, beide real gesetzt in `init.lua`/`plugins/neotree.lua`.

**Toter Code gelöscht** (verifiziert: 0 Aufrufer im ganzen Repo + allen 31
Plugin-Repos):
- `utils/init.lua`: `get_current_position()`, `is_neotree_open()`.
- `@types/utils.lua`: 5 veraltete Type-Klassen für Submodule
  (buffer/path/platform/tree/selective_callback_guard), die in diesem
  Ordner gar nicht mehr existieren — `checkhealth/utils.lua`s eigener
  Kommentar dokumentiert deren Entfernung bereits, die Typen waren nie
  nachgezogen worden.

**`--- CDX:` gesetzt (Urteilssache):**
- `@types/config.lua`: `SetupModule.busy_guard` als Methode deklariert, die
  `M` nie implementiert — Namenskollision mit dem tatsächlichen
  `InitOpts`-Wert `busy_guard = false`.
- `init.lua`: `window_debug`/`window_open` werden angenommen, aber
  `M.setup()` liest keins von beiden je.

**Ausgelagert nach WKDBooks** (Commit `eb4863b`): `window/open/keymaps/
only_lhs.lua`s ~60-Zeilen `neo-tree.command.execute()`-Optionstutorial
(Modul nutzt nur 4 von 8 Optionen) → `wkdbook-Neovim/MyNotes/
neotree-command-execute-options.md` (neu).

**Überraschender Fund, direkt gefixt:** `event_handlers/README.md`
beschrieb vier Event-Handler, die nirgends mehr im Code existieren (nur
noch einer übrig, `neo_tree_preview_buffer_enter`) — komplett neu
geschrieben, jetzt deckungsgleich mit dem Code.

stylua ok, luacheck 0/0 (21/29 — 8 `@types/*`-Dateien vom Glob übersprungen,
gleiches Muster wie harpoon/neotest).

**Nebenfund, nicht bearbeitet:** `docs/NOTES/ExternPlugins/Bindings/
Keymaps/NeoTree.md:300` referenziert `config.neotree.keymaps.tests`, das
es nie gab — außerhalb des Scopes (keine `.lua`-Datei in diesem Ordner).

Commit: nvim-config `0e64b4b4d`. Ohne Co-Authored-By, gepusht +
`pull --ff-only` bestätigt.

### Danach offen

`lua/config/` ist komplett. Weiter mit `lua/plugins/`, `lua/startup/`,
`lua/wkdoptions/`, `lua/themes/`, `lua/nvchad/` + `lua/wkdnvchad/`,
`lua/@types/`, `after/`, `init.lua`, `scripts/`. Danach die 31 Plugin-Repos.

Dann restliche `lua/`-Bereiche (359 Dateien gesamt): `lua/config/` (~100, groß:
harpoon/neotest/neotree), `lua/plugins/`, `lua/startup/`, `lua/wkdoptions/`,
`lua/themes/`, `lua/nvchad/` + `lua/wkdnvchad/`, `lua/@types/`, `after/`,
`init.lua`, `scripts/`.

Danach die 31 Plugin-Repos (Liste unten), repo-für-repo, je 1 Agent möglich.

<details><summary>Plugin-Liste</summary>

buffer-ctx, cascade, casedesk, cmdlog, color_my_ascii, dap, debugging, diff,
documentation, emojis, fileops, filetree, github_stats, gopath, hover, images,
insights, language, lib, lsp, markdown, mdview, open, pdfport, pickers,
recommender, replacer, reposcope, runtime-analysis, sandbox, sessions, spotlight
(alle unter `C:/repos` bzw. `E:/repos`). Nativ zusätzlich: docmap-desktop.

</details>

---

## Relocation-Log

Format: `Quelle → Ziel — was`

- `lua/autocmds/explorer-singleton.smoke.lua` (+ `explorer-singleton.lua` Header)
  → `wkdbook-Neovim/MyNotes/WinEnter-frisches-Fenster-Timing.md` (neu) — die
  Mechanik „`WinEnter` sieht bei frisch erstellten/gesplitteten Fenstern kurz
  den Buffer des Vorgängerfensters; `:split` klont erst den fokussierten
  Buffer". Stand vorher als ~12-Zeilen-Kommentar 2× im Code, jetzt 3-Zeilen-
  Pointer auf die Note. Commit in `StefanBartl/WKDBooks`.
- `lua/bindings/mappings/editing.lua` (Header + 3 Doc-Blöcke)
  → `wkdbook-Neovim/MyNotes/Paste-Register-Clipboard-vim.paste.md` (neu) —
  Register-Clipboard-Umleitung (`getreg` folgt ihr nicht), Bracketed Paste
  läuft an Register+Keymap vorbei → `vim.paste`-Wrap, `vim.paste`-Phasen
  −1/1/2/3 + „Chunk-Grenze ≠ Zeilenumbruch". Header 29→11 Z.
- `lua/bindings/mappings/treesitter_structure.lua` (Header 58→18 Z.)
  → `wkdbook-Neovim/MyNotes/treesitter-textobjects-block-outer-erweitern.md`
  (neu) — `@block.outer` pro Sprache via `after/queries/*/textobjects.scm`
  erweitern, unbekannter Knotenname bricht die ganze Query.
  → **`docs/NOTES/CrossPlugin/Keymaps-Collisions.md`** neue Sektion
  „Bracket-pair motions (`[x`/`]x`)" mit dem Owner-Inventar (Neovim/lsp.nvim/
  snacks/config) + der `[b]`/`]b`-Story.

---

## Wiederkehrende Fund-Muster

Aus Häppchen 1, als Kalibrier-Referenz für die nächsten Bereiche:

1. **Deutsch in englischen Kommentaren** — v.a. eigene `AUDIT:`/`FIX:`-Marker
   und einzelne Wörter (`Debounce-Verzögerung`). → übersetzt.
2. **`-- Description:`-Zeilen, die `desc = "…"` doppeln** — direkt darüber steht
   schon eine `-- N) …`-Sektionsüberschrift, darunter das `desc`-Feld. Die
   mittlere Zeile trägt nichts bei. → entfernt.
3. **Header-Kommentar dupliziert Inline-Kommentar** — dieselbe Begründung
   einmal im `---@module`-Block und nochmal an der Code-Stelle. → Header-Version
   raus, Inline bleibt (dort gehört sie hin).
4. **Falsche `require`-Pfade in USAGE-Beispielen** — Modulname im Doc-Block
   weicht vom echten Rückgabepfad ab. → korrigiert.
5. **Kommentar widerspricht dem Code** — `enable = true, -- Disabled by default`.
   → Kommentar an den Code angepasst.
6. **Neovim-Mechanik-Tutorial im Kommentar** — `keytrans() converts raw
   terminal bytes to a readable name …`, `:split` klont den fokussierten Buffer
   … . Allgemeinwissen, nicht ortsgebunden. → gekürzt auf den ortsrelevanten
   Kern, Rest ins Relocation-Log / nach wkdbook-Neovim.
7. **Undokumentierte Config-Felder** — `defaults.lua`-Tabellen ohne
   Feld-Beschreibungen, teils schon vom User als `AUDIT: Optionen beschreiben`
   markiert. → als `--- CDX:` belassen (Beschreiben ist eigene Aufgabe).
