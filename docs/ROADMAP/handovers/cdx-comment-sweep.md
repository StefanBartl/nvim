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

### Häppchen 12 — `lua/plugins/` Top-Level + 3 kleine Ordner (22 Dateien)

**Status: erledigt.** `@types`, `colorscheme` (bis auf 2 Übersetzungen),
`essentials`, `completion`, `editing`, `snacks`, `telescope`, `textobjects`,
`ui` bereits sauber.

**Echter Bug direkt gefixt (Redundanz, keine Verhaltensänderung):**
`neotest.lua` rief `config.neotest.highlights.setup()` **zweimal** auf
(Copy-Paste-Artefakt) — Duplikat entfernt (Funktion ist idempotent).

**Weitere direkte Fixes:**
- `neotree.lua`: `} or nil` entfernt (Tabelle immer truthy, wirkungslos);
  toter auskommentierter Mappings-Merge-Versuch entfernt, der
  `config.neotree.keymaps.tests` referenzierte — bestätigt an zweiter
  Stelle, dass dieses Modul (Häppchen-11-Nebenfund) nie existierte.
- `fzf.lua`, `neotest.lua`: toter auskommentierter Code entfernt.
- `nvchad.lua`: stehengebliebener Tutorial-Platzhaltertext im Header durch
  akkurate Beschreibung ersetzt.
- Diverse deutsche Kommentare übersetzt (`colorscheme`, `experimental`,
  `git`, `markdown`, `misc`, `neotest`, `treesitter`, `ui_icons`).

**`--- CDX:` gesetzt:**
- `neotest.lua`: `opts.adapters`-Split-Brain (aus Häppchen 10 bekannt) —
  Pointer auf `docs/ROADMAP/IDEAS/test.md §2.1` ergänzt, **nicht neu
  bewertet** wie angewiesen.
- `workflow.lua`: 82-zeiliger auskommentierter `autolist.nvim`-Spec-Block +
  kleiner `wakatime`-Block — laut `docs/NOTES/ExternPlugins/Bindings/
  TODO.md` als „deaktiviert" bekannt, aber keine explizite
  Lösch-/Behalten-Entscheidung dokumentiert. Autorenentscheidung offen.

Ausgelagert nach WKDBooks (Commit `30d2824`): `webdev.lua`s
„Why not `ft = {...}`"-Abschnitt (lazy.nvim-Mechanik:
`ft`-Plugins landen trotz `lazy = true` im Start-Batch) →
`wkdbook-Neovim/MyNotes/lazynvim-ft-rtp-loaded-defeats-lazy.md` (neu).

stylua ok, luacheck 0/0 (21/22 — 2 `@types/*` vom Glob übersprungen).

Commits: nvim-config `aa9b5401b` + `10d9c105d`. Ohne Co-Authored-By,
gepusht + `pull --ff-only` bestätigt.

### Häppchen 13 — `lua/plugins/personal/` + `lua/plugins/ai/` (8 Dateien)

**Status: erledigt. `lua/plugins/` damit komplett durch**
(`github-stats/` ist reine Datenablage von github_stats.nvim, kein Code —
geprüft, übersprungen).

- **`personal/source.lua`** — bestätigter Häppchen-7-Fund: komplett deutsch,
  vollständig übersetzt, keine inhaltliche Änderung.
- **`personal/init.lua`** — **größter Fund:** der `hover.nvim`-Spec-Eintrag
  trug einen ~95-zeiligen deutschen Prosa-Kommentar (Web-Links, Zen,
  persist, Zoom-Historie, Messwerte). Geprüft, ob das Wissen schon woanders
  liegt — **ja**, praktisch wortgleich in hover.nvims eigenem
  `docs/configuration.md` + `docs/FEATURES/{ZOOM,ZEN,SHOT,RESIZE,QUIET}.md`
  inkl. derselben Messwerte. Kein Umzug nötig, nur auf ~20 Zeilen
  (Ladereihenfolge-Begründung + Pointer) gekürzt, Rest gelöscht als reine
  Duplikation. Diverse weitere Übersetzungen (lib.nvim, images.nvim,
  documentation.nvim, language.nvim-Blöcke). **Kurioser Nebenfund:**
  `mdview.nvim`-Block hatte garbled Tippfehler als Status-Marker
  (`FUNKTioNNERTT`, `FUnktnioert` — offenbar Diktier-/Chat-Artefakte für
  „funktioniert") → zu sauberem `-> works` übersetzt.
- **`personal/list.lua`** — überlange Rationale (12→8 Zeilen) gekürzt.
- **`personal/utils.lua`** — 1 deutsches Doc-Fragment übersetzt.
- **`personal/export.lua`** — 0 Änderungen, bereits sauber.
- **`ai/avante.lua`** — echter Fix: Header verwies auf `plugins.ai` (den
  eigenen Ordner) statt auf das tatsächliche Ziel `config.ai.anthropic` —
  klassisches Muster #4 (falscher require-Pfad im Doc).
- **`ai/gp.lua`, `ai/copilot.lua`** — 0 Änderungen. **Bestätigt
  Häppchen-8-Befund:** alle drei KI-Assistent-Specs sind bewusst/vollständig
  auskommentiert, nicht versehentlich verwaist — `gp.lua`s Header sagt das
  explizit.

Kein WKDBooks-Umzug nötig (einziger Kandidat lag schon am Zielort).
stylua ok (nach Reflow-Format), luacheck 0/0 (8/8 Dateien — Hinweis für
künftige Häppchen: Verzeichnis-Glob gab „Permission denied", Datei-Glob
`*.lua` funktionierte).

Commit: nvim-config `bc3376a6e`. Ohne Co-Authored-By, gepusht +
`pull --ff-only` bestätigt.

### Häppchen 14 — `lua/wkdoptions/` ohne `hl_config/` (26 Dateien)

**Status: erledigt.** Netto: 11 Dateien geändert, 20 Zeilen rein/192 raus,
2 Dateien komplett gelöscht.

**Zwei tote Module gelöscht (verifiziert: 0 Aufrufer im Repo):**
- `@types/commands.lua` — 7 Type-Klassen, verwaiste ältere Fassung, ersetzt
  durch die tatsächlich benutzten Varianten in `commands/@types/init.lua`.
- `commands/core.lua` (104 Z.) — `register.lua` hat dieselbe Logik lokal
  dupliziert statt diese Datei zu nutzen. **Bereits in einem als
  „erledigt" markierten Roadmap-Log** (`Merged_Finished.md:472`) als
  Redundanz zu lib.nvim identifiziert — nur nie physisch gelöscht.

**Weitere Fixes:** toter auskommentierter Duplikat-Klassenentwurf in
`@types/highlight.lua` gelöscht; `commands/@types/init.lua`: echter
Typ-Fix, `WKDOptions.Commands`-Klasse dokumentierte nur 3 von 5 realen
Funktionen; `set_diff_profile/@types/init.lua`: Tippfehler im
`---@module`-Pfad (`t@ypes` — `@` mitten im Wort) korrigiert; verwaiste
`---@description`-Tags (kein echtes LuaLS-Tag) durch normale
`---`-Kommentare ersetzt. Diverse deutsche Kommentare übersetzt
(`italic_keywords`, `options_config`, `ui/line_numbers` — inkl. eines
dramatisierten ASCII-Banners „DIE LÖSUNG: ..." auf einen Ein-Zeiler
gekürzt).

**`--- CDX:` gesetzt:** `qflist/init.lua` konfiguriert
`vim.diagnostic.config()`, das direkt danach im selben `M.setup()`-Durchlauf
von `set_diagnostic_signs()` fast komplett überschrieben wird — bisher
nirgends dokumentierte Überschneidung (nur die mit `lsp.core.diagnostics`
war bekannt).

**`config/` (9 Dateien), `init.lua`, `indent_per_ft/`** — 0 Änderungen,
bereits sauber.

**`doc/`/`docs/` waren entgegen der Bestandsaufnahme nicht leer** — Vimdoc
+ CHEATSHEET.md bereits sauber; `PERFORMANCE.md`/`colors.md`/
`highlights/breadcrumbs_ctx.md` sind deutsch und gehören inhaltlich zu
`hl_config/` — bewusst für den nächsten Häppchen aufgehoben, nicht
angefasst.

stylua ok, luacheck 0/0 (18 Dateien geprüft).

Commit: nvim-config `152db12c0`. Ohne Co-Authored-By, gepusht +
`pull --ff-only` bestätigt.

### Häppchen 15 — `lua/wkdoptions/hl_config/` (38 Dateien, ~4940 Z.)

**Status: erledigt. `lua/wkdoptions/` damit komplett durch.**
`breadcrumbs/@types/init.lua` war schon in `c2e413cb9` gemacht — übersprungen.

**Toter Code gelöscht** (0 Aufrufer im ganzen `lua/` + allen 31 Plugin-Repos):
- `breadcrumbs/ctx/utils/ts_helpers.lua`: das gesamte „Pre-compiled Pattern
  System" + „Common Pattern Presets" (`compile_pattern`, `exec_pattern`,
  `get_preset`, `PRESETS`, `PATTERN_CACHE`) + `clear_caches` — ~150 Z.
  Nie verdrahtete Perf-Infrastruktur; der Header pries sie als „bytecode
  cache" an. `Breadcrumbs.TSPattern`-Klasse mit raus.
- `breadcrumbs/ctx/utils/text_utils.lua`: `split_dotted`, `join_parts`,
  `build_container`, `extract_js_object_key` (JS-Pendant zu
  `extract_lua_field_key`, aber nie aufgerufen).
- `utils/winhighlight.lua`: `remove_keys` (Geschwister zu `set_pair`/`merge`,
  ungenutzt).
- `core/highlights.lua`: `get_hl_safe` (einziger ungenutzter Safe-Wrapper).
- `core/state.lua`: `reset` (Test/Reload-Helfer, kein Aufrufer, kein Testsetup).
- `breadcrumbs/ctx/init.lua`: `Breadcrumbs.ProviderContext`-Typ (verwaist,
  nachdem `Breadcrumbs.Provider.extract` von `(ctx)` auf die echte
  `(node, cfg)`-Signatur korrigiert wurde).
  Alle zugehörigen `@types`-Felder mitgezogen.

**Echte Annotation-Fixes (reine `@types`):**
- `breadcrumbs/ctx/@types/providers.lua`: `Breadcrumbs.Provider.extract`
  deklarierte `fun(ctx: Breadcrumbs.ProviderContext)`, die Provider
  implementieren aber `extract(node, cfg)` — korrigiert; `name`/`priority`
  (nie implementiert) entfernt.
- `features/@types/init.lua` Flash-Klasse: `enable_put` (existiert nicht mehr,
  die p/P-Mapping-Ära ist vorbei, siehe `flash.lua`-Kommentar) → durch die
  realen `put_flash_enabled`/`flash_put` ersetzt.
- `utils/@types/init.lua`: `LargeFile.invalidate` deklariert, `large_file.lua`
  hat keine solche Funktion → entfernt; `Winhighlight.remove_keys` (s.o.).
- `core/@types/init.lua`: `State.reset`/`Highlights.get_hl_safe` mitgezogen;
  augroup-Prefix-Beschreibung `"myopt."` → `"myopt"` (Code nutzt keinen Punkt).

**`--- CDX:` gesetzt (Urteilssache / Bug in passing):**
- `breadcrumbs/ctx/utils/text_utils.lua` `extract_lua_field_key` — der
  quoted-key-Zweig `text:match("^%[(['\"])(.-)%1%]%s*=")` hat **zwei**
  Captures; `return quoted` gibt das Anführungszeichen zurück, nicht den Key.
  `["foo"] =` löst zu `"`/`'` auf. (Aufgerufen aus `lang/lua.lua`.)
- `breadcrumbs/ctx/init.lua` `_build_context` — die Pipeline setzt nie
  `cfg._base_symbol`, das der `container`-Provider (und die
  `WKDOptionsBreadcrumbsCtx._base_symbol`-Doku) verlangt. Der
  `container`-Provider liefert im Live-Winbar **immer nil**; nur der
  `:WKDOptionsHLDebugCtx`-Pfad (`_ctx_with_container`) füttert ihn.
- `breadcrumbs/ctx/init.lua` `M.invalidate_caches` — plus `base.clear_cache`
  und `ts_helpers.invalidate_tick`: unverdrahtete Cache-Invalidierungs-API,
  0 Aufrufer. Aktuell harmlos (self-invalidating), aber die BufEnter-Wiring
  fehlt, falls das je gebraucht wird. Nicht gelöscht (Kaskade + evtl. gewollt).
- `cword_occurrences/init.lua:15` — `local H = C.cfg.highlight` wird **einmal
  beim Modul-Load** aufgelöst (nicht `C.get_cfg()`). Lädt das Modul vor
  `config.get_cfg()`, friert `H` auf `{}` ein und alle Feature-Config-Reads
  werden still zu No-ops.
- `features/mode_tint.lua:17` — `pcall(function() return vim.v.event end)`:
  überflüssige Zeremonie, Feldzugriff kann nicht werfen.

**Direkte Doc-/Kommentar-Fixes:**
- `hl_config/init.lua` + `docs/highlights/breadcrumbs_ctx.md` (11×): totes
  Kommando `:MyHlSet` → `:WKDOptionsHLSet` (der echte Name, überschreibt
  `WKDHighlightSet` in `hl_config/init.lua`). `:MyOptSet` (options-Seite)
  ist **echt** und bleibt.
- `text_utils.lua`: deutsches „wir brauchen nur result" → Englisch.
- `winhighlight.lua`: Tippfehler „undrscore" → „underscore".
- `path_cache/init.lua`: stale 2-Zeilen-`-- File:`-Header (falscher Pfad
  `path_cache.lua` statt `path_cache/init.lua`, dupliziert den `---@module`).
- Generische AI-Header eingedampft: `hl_config/init.lua` (Key-Principles-Block
  raus), `hl_config/@types/init.lua` (Architecture/Performance/Safety-Wüste),
  `ts_helpers.lua`, `skip.lua` (Example-Integration-Block, den `std_skip`
  wörtlich doppelt), `cword_occurrences/@types` (Verweis auf nicht
  existierende Datei `@types/cword_occurences.lua`).
- `breadcrumbs/ctx/init.lua`: „Backward Compatibility Exports / legacy export"
  → akkurate Beschreibung (es sind die `:WKDOptionsHLDebugCtx`-Provider-Proben).

**`docs/colors.md`** — geprüft gegen `config/data/highlight.lua`: alle Hex-Werte
und Gruppennamen exakt korrekt, kein Fix nötig (bleibt deutsch).

**Nicht angefasst (Nebenfunde):**
- `docs/PERFORMANCE.md` — fabrizierte Benchmarks (Apple M1 Pro, erfundene
  ms-Werte), stale Beispiel-Requires (`lib.memo` statt `lib.lua.memo`,
  `:WKDHighlightSet` statt `:WKDOptionsHLSet`). Wie in Häppchen 6/8 kalibriert:
  eigener Aufräum-Punkt, nicht im Sweep umgeschrieben.
- `breadcrumbs/@types/init.lua` (übersprungen): `WKDOptions.HL_CFG.Breadcrumbs.Ctx`
  ist dort **zweimal** als `@class` deklariert (einmal Config-Felder, einmal
  Modul-Struktur). Prior-Agent hat's stehen lassen.
- `config/init.lua:4` + `config/README.md:4`: stale `:MyHlSet` (außerhalb
  hl_config-Scope, config/ galt in Häppchen 14 als sauber).
- `fallback_object_when_empty` (config + beide `@types`): dokumentiertes
  Config-Feld, das **kein Provider liest** (die „object"-Fallback-Rolle
  übernimmt `lang_extra`/`use_lang_specific`). Vestigial.
- `LineNrDim` in `colors` definiert, aber von keinem Feature via winhighlight
  angewandt (`deactivate()` mappt `CursorLineNr → LineNr`).

stylua ok, luacheck 0/0 (11 `.lua`-Dateien geprüft; die `@types/*` vom
luacheck-Glob übersprungen wie in allen vorigen Häppchen, stylua deckt sie ab).

Commits: nvim-config `095769e0e` (breadcrumbs) + der Folge-Commit
(core/features/utils/top-level/docs/handover). Ohne Co-Authored-By, gepusht +
`pull --ff-only` bestätigt. Kein WKDBooks-Umzug (kein ortsunabhängiges
Mechanik-Wissen gefunden — die langen Blöcke waren entweder Bug-Rationale am
richtigen Platz oder AI-Boilerplate).

### Häppchen 16 — `lua/wkdnvchad/` (41 Dateien, ~4470 Z.)

**Status: erledigt. `lua/wkdnvchad/` damit komplett durch.**
Statusline-/Tabufline-/Theme-Switcher-Subsystem auf NvChad. Netto:
16 Dateien geändert, kein toter Code gelöscht (siehe unten warum nicht).

**Übersetzt (Deutsch → Englisch, reine Kommentare):**
- `ui/statusline/modules/lsp/symbols/treesitter.lua` — ~20 Kommentarzeilen
  (Guard, Knoten-Typen-Tabelle, 3-stufige `ts_identifier_of`-Heuristik).
- `ui/statusline/modules/highlighting/@types/init.lua` — alle 4 `@field`-Doc-
  Blöcke; zusätzlich `highlighting/init.lua`-Header (deutscher 10-Zeilen-Kasten,
  duplizierte @types + README) → 3-Zeilen-Summary + Pointer auf @types.
- `ui/statusline/modules/lsp/helpers/paths.lua` — 5 Inline-Kommentare.
- `ui/statusline/modules/neotest_module/init.lua` — 4 Kommentarzeilen.
- `config/statusline/custom.lua` (4×, u.a. casedesk-Kurzinfo-Block),
  `config/statusline/custom_minimal.lua` (2×),
  `mappings/tabufline/init.lua` (5×: „WICHTIG/KRITISCH"-Marker).
- `usrcmd/init.lua` — nur Tippfehler „odule" + redundante Import-Zeile raus.
  **Alle deutschen `notify`/`:UI help`/`desc`-Strings bewusst deutsch gelassen**
  (Regel 2: erreichen den User) — gilt auch für `usrcmd/themes/init.lua`.

**`--- CDX:` gesetzt (Urteilssache / Bug in passing):**
- `config/statusline/lspbased.lua:12` — `require("wkdnvchad.config.chadrc")`
  referenziert ein Modul, das **nicht existiert** (kein `chadrc.lua` unter
  `wkdnvchad/config/`); `register_statusline_modules` liegt in
  `config.statusline.custom_light`. Variant „lspbased" läuft dadurch immer in
  den `notify.error`-Zweig und registriert **null** Statusline-Module.
- `ui/statusline/modules/neotest_module/init.lua` — **tot + kaputt**: von
  keiner der 6 Statusline-Varianten required (sagt sein eigenes README), und
  `neotest.run.get_status()` ist **keine neotest-API** (der `run`-Consumer hat
  nur run/run_last/stop/attach/adapters/get_last_run) → nil-Call sobald es
  verdrahtet würde. Nicht gelöscht, weil das README es als bewussten
  „pending a closer look"-Keep markiert.
- `ui/statusline/modules/custom/` (init.lua) — der gesamte Subtree (init,
  breadcrumbs/helpers, breadcrumbs/render) hat **0 Aufrufer** in `lua/` + den
  Plugin-Repos (deckt sich mit `custom/README.md` „currently unreferenced …
  pending a closer look"). Zusätzlicher Fund für den Fall der Wiederbelebung:
  `breadcrumbs/render.lua` ist **intern kaputt** — ruft `M.repo_relative` /
  `M.symbol_context` / `M.ellipsize_middle` / `M.stl_escape` auf der eigenen
  Modultabelle auf, `require`t aber nie `breadcrumbs/helpers.lua`, wo die
  liegen → `render_breadcrumbs()` nil-called. Nicht gelöscht (dokumentierter
  Keep).
- `ui/statusline/modules/custom/breadcrumbs/helpers.lua:81` —
  `function M.ts_identifier_of(n)` ist **innerhalb** `M.symbol_context()`
  definiert, jeder Aufruf re-assignt das Modulfeld. Sollte `local function`
  sein (wie in `lsp/symbols/treesitter.lua`).
- `mappings/tabufline/init.lua` (`close_n_buffers`) — `lib.lua.lazy.require`
  löst **eager** auf (ruft sofort `.get()`), d.h. `nvchad_tabufline` ist schon
  beim Modul-`require` geladen und der `if not nvchad_tabufline`-Re-require-
  Zweig (+ sein „lazy-load only when closing"-Kommentar) ist tot.

**Reine Annotation-/Artefakt-Fixes (keine Laufzeitänderung):**
- `ui/statusline/cursor_ctl/renderer.lua:37` — zerhackter Tag
  `--- @ret M.urn string` → `--- @return string`.
- `ui/statusline/cursor_ctl/progress_calculators.lua:29` — stale Edit-Artefakt
  („Replace the previous compute_col_pct() with this …") entfernt.
- `ui/statusline/modules/lsp/symbols/document_symbols.lua` — 2× „(unchanged
  logic)"-Chat-Artefakt aus Kommentaren raus.
- `config/init.lua` — Varianten-Kommentarblock listete 4 von 6 Varianten
  (`custom_light`/`custom_minimal` fehlten) — ergänzt.
- `usrcmd/init.lua:193` — stale Datei-Ref `README-THEMES.md` in der (deutschen)
  `:UI help`-Ausgabe → `wkdnvchad/usrcmd/themes/README.md`.

**Kein toter Code gelöscht:** die drei Kandidaten (`modules/custom/`,
`modules/helpers/path.lua` + `nerd_fonts.lua`, `modules/neotest_module/`) sind
alle in ihren eigenen READMEs als bewusste „pending a closer look"-Keeps
dokumentiert (Triage-Notiz vom 2026-08-16). Rule 5 „Zweifel → CDX" +
dokumentierte Autorenabsicht → getaggt statt gelöscht.

**Nicht angefasst (Nebenfunde):**
- `lib.lua.lazy.require` ist trotz Namen **nicht lazy** (`LAZY.require` =
  `LAZY.module(name).get()`, sofortiger `require`). Betrifft viele
  Datei-Scope-`lazy.require`-Aufrufe in dieser Config, die „break circular
  dependencies" / „lazy-load heavy modules" kommentieren. lib.nvim-Sache,
  gehört in den lib-Plugin-Häppchen.
- `wkdnvchad/config/README.md` (deutsch) listet im Datei-Baum ein
  `chadrc.lua # Legacy chadrc-Kompatibilität (optional)`, das es unter
  `wkdnvchad/config/` nicht (mehr) gibt — passt zum lspbased-CDX. Deutscher
  Design-Doc, nur als Nebenfund notiert.
- `ui/statusline/modules/lsp/docs/instructions.md` — Titel „Einbindung in
  chadrc.lua", gleiche Baustelle.
- `usrcmd/themes/fix.md` — sieht wie eine Scratch-/Notizdatei aus.

stylua ok, luacheck 0/0 (15 `.lua`-Dateien geprüft; `@types/*` vom
luacheck-Glob übersprungen wie in allen vorigen Häppchen).

Commit: nvim-config `ba0231201`. Ohne Co-Authored-By, gepusht +
`git log origin/main` bestätigt. Kein WKDBooks-Umzug
(kein ortsunabhängiges Mechanik-Wissen — die langen Header waren
Bug-/Design-Rationale am richtigen Platz).

### Häppchen 17 — Kleinteile: `startup/`, `themes/`, `nvchad/`, `@types/`, `after/`, root `init.lua`, `scripts/`

**Status: erledigt. Damit ist der gesamte `lua/`-Baum der nvim-config durch.**

Fast alles bereits sauber & englisch. Winzige Änderungen:
- `init.lua:278` — deutscher Kommentar → Englisch; das eigene `-- TODO: gehört
  in meine options/` zu `--- CDX: belongs in options/, not here` vereinheitlicht.
- `lua/@types/aliases.lua` — 2 deutsche Sektionskommentare (`Generische
  Funktionstypen`, `Weitere nützliche Aliase`) → Englisch.
- `lua/nvchad/au.lua` — totes `-- vim.cmd("redraw!")` gelöscht.

Geprüft, nichts zu tun:
- `lua/startup/` (init.lua + report.lua) — vorbildlich kommentiert, echte
  Design-Rationale am richtigen Platz.
- `lua/themes/vim_default.lua`, `lua/@types/` (Rest — `archive.lua` ist ein
  bewusst als „NOT IN USE" markiertes Archiv, `vim_uv.lua` 953-Z.
  Type-Stub, beide sauber), `scripts/` (Dev-Probe-Tools, knappe engl.
  Header), `after/` (nur `.scm`/`.vim`, kein `.lua`).

stylua ok, luacheck 0/0.

Commit: nvim-config `<pending>`. Ohne Co-Authored-By.

### Häppchen 18 — recommender.nvim (Plugin-Repo 1/31)

**Status: erledigt.** Erstes Plugin-Repo. ~3100 Z. Lua, 32 Dateien, eigenes
`main` / Remote `StefanBartl/recommender.nvim`. Das Repo war bereits fast
durchgehend auf Sweep-Qualität — durchweg Englisch (kein einziges deutsches
Wort im ganzen `lua/`-Baum), Header mit echter ortsrelevanter Rationale,
keine AI-Boilerplate-Blöcke, keine Chat-Artefakte. `health.lua` war schon in
`e9a9177` gesweept, nicht erneut angefasst.

**Geänderte Dateien (8):** `lua/recommender/@types.lua`,
`lua/recommender/float/keymaps.lua`, `lua/recommender/float/autocmds.lua`,
`lua/recommender/project.lua`, `lua/recommender/util/lib.lua`,
`docs/architecture.md`, `docs/FEATURES.md`, `doc/recommender.txt`.

**Bereits sauber, 0 Änderungen:** `init.lua`, `config/init.lua`,
`config/DEFAULTS.lua`, `bindings/{init,keymaps,usrcmds,autocmds}.lua`, alle 5
`analyzers/*.lua`, `blacklist.lua`, `custom_aliases.lua`,
`float/rendering.lua`, `util/{notify,progress}.lua`, `health.lua`, beide
`plugin/*.lua`, alle `TESTS/*`.

**`--- CDX:` gesetzt (Urteilssache, nicht gefixt):**
- `float/keymaps.lua:91` — `state._pending_insert` wird gesetzt (und an 2
  Stellen auf `nil` geräumt), aber **nirgends im Repo gelesen**. Tote State
  von einem früheren Insert-Pfad; Replace-Mode-Insertion läuft heute über den
  `WinClosed`-Hook in `float/autocmds.lua`. Existiert seit dem Initial-Commit
  ohne je einen Reader gehabt zu haben.
- `float/autocmds.lua` (`register_replace_finish`) — die „Replace fertig"-
  Erkennung ist hart auf `filetype == "TelescopePrompt"` verdrahtet.
  replacer.nvim hat inzwischen **auch ein fzf-Picker-Backend**
  (`lua/replacer/pickers/fzf.lua`); mit dem feuert der `WinClosed` nie und
  die Replace-Mode-Insertion tut still nichts. **Nebenfund:** `docs/WORKFLOW.md`
  §88-89 dokumentiert diese Telescope-only-Limitierung bereits — `docs/commands.md:130`
  („No polling, no timers, no race conditions") und `docs/FEATURES.md:161` nicht.
- `@types.lua:42` — `Recommender.Suggestion` ist **nirgends referenziert**;
  jeder Analyzer und beide `float/`-Module schreiben die Form inline als
  `{chain:string, count:integer, alias:string}[]`. Entweder verdrahten (die
  ~8 Inline-Wiederholungen ersetzen) oder löschen — nicht selbst entschieden
  (Rule 5: „dokumentierter Type-Katalog" + Zweifel → taggen).

**Direkte Fixes (Kommentar/Doc, keine Verhaltensänderung):**
- `project.lua` — Modul-Header: die Schluss-Absatz-Rekapitulation
  („Together, `find_files_async` + `read_lines_async` …") wiederholte Absatz
  1 + 3; in Absatz 5 zusammengezogen (−5 Z.).
- `util/lib.lua` — `@brief` sagte „bridge to the **optional** `lib.nvim`",
  während der eigene `@description` erklärt dass `lib.nvim` seit der
  Composer-Migration **hart** benötigt wird. `@brief` an die Realität
  angepasst.

**Doc-Staleness gefixt (eigener Commit):** `bindings/which_key.lua` wurde in
`22d65e1` gelöscht (Gruppen-Label wanderte in die Keymap-Spec von
`keymaps.lua`) — `docs/architecture.md`, `doc/recommender.txt` und
`docs/FEATURES.md` listeten die Datei noch. Zusätzlich trug
`docs/architecture.md` noch das Design-Prinzip „**No hard `lib.nvim`
dependency**", das `installation.md` und dem Code widerspricht — korrigiert.
`float/`-Modulbeschreibungen in architecture.md / recommender.txt auf den
`kit.select`-Picker aktualisiert (die „open/close/highlight; stride"-
Formulierung war von vor der Migration).

**Kein toter Code gelöscht** (die 3 Kandidaten alle als `--- CDX:` getaggt —
`_pending_insert`, `Recommender.Suggestion`, plus der latente
`float/autocmds.lua`-Bug). **Kein WKDBooks-Umzug** — kein ortsunabhängiges
Neovim-/Lua-Mechanik-Wissen; die langen Header (`project.lua`,
`bindings/usrcmds.lua`, `analyzers/perf.lua`) sind funktions-/messwert-
Rationale am richtigen Platz und verweisen bereits auf das plugin-eigene
`docs/FEATURES.md`.

stylua `--check lua TESTS` ok, luacheck `lua TESTS` 0/0 (30 Dateien, `@types.lua`
mitgeprüft — luacheck 1.2.0 überspringt es hier **nicht**), `TESTS/run.lua`
headless grün (`RECOMMENDER_TESTS_OK`). CI-Pins (stylua v2.5.2, luacheck
1.2.0) lokal exakt gematcht.

Commits: recommender.nvim `6c0180c` (source) + `20d655a` (docs), gepusht auf
`origin/main` (`8fdbf98..20d655a`), `pull --ff-only` bestätigt „Already up to
date". Ohne Co-Authored-By.

### Häppchen 19 — sessions.nvim (Plugin-Repo 2/31)

**Status: erledigt.** ~2000 Z. Lua in `lua/sessions/` (13 Dateien + 4 Bindings-
Module), eigenes `main` / Remote `StefanBartl/sessions.nvim`. Wie
recommender.nvim war das Repo schon fast durchgehend auf Sweep-Qualität:
durchweg Englisch (ein einziges deutsches Fragment, s.u.), Header mit echter
ortsrelevanter Rationale, keine AI-Boilerplate. `lua/sessions/health.lua`
war schon in `e3f9592`/`0181dce`/`2edffa7` gesweept — nicht erneut angefasst.

**Remote-URL-Check:** `git remote -v` zeigt bereits `StefanBartl` (groß) —
kein `set-url` nötig. (Nebenfund: `doc/sessions.txt` Homepage-Zeile +
README-Specs schreiben `stefanbartl` klein; GitHub ist da case-insensitiv,
kein Bruch — nicht angefasst.)

**Geänderte Dateien (7):** `init.lua`, `statusline.lua`, `@types/init.lua`,
`bindings/keymaps/init.lua`, `bindings/autocmds/init.lua`, `core.lua`,
`git.lua`.

**Bereits sauber, 0 Änderungen:** `buforder.lua`, `layout.lua`, `meta.lua`,
`portable.lua`, `state.lua`, `picker.lua`, `config/init.lua`,
`config/DEFAULTS.lua`, `bindings/usercmds/init.lua`, `health.lua`, alle
`TESTS/*`.

**`--- CDX:` gesetzt (1, Urteilssache):**
- `bindings/autocmds/init.lua` (`M.enable`, bei den Struktur-Autocmds) — die
  Dirty-Tracking-Autocmds (`BufAdd`/`BufDelete`/`WinNew`/…) werden **nur
  innerhalb `if cfg.autosave then`** registriert. Mit `autosave = false`
  läuft `core.mark_dirty()` nie, also erscheint das Statusline-`dirty_icon`
  (`sessions.statusline`) nie — obwohl der Modul-Header das Wiring
  bedingungslos beschreibt und die Statusline-Komponente `dirty_icon`
  bedingungslos anbietet. Absicht oder Bug offen.

**Direkte Fixes (Kommentar/Doc, keine Verhaltensänderung):**
- `init.lua` — der `---@brief`-Header trug einen „Full config with all
  options"-Block, der **unvollständig/veraltet** war (fehlten
  `sessionoptions`, `relative_paths`, `root_remap`, `autosave_name`,
  `project_markers`, `restore_buffer_order`, `which_key`; `keymaps` nur mit
  4 von 11 Namen). Muster #4. `docs/configuration.md` ist die vollständige
  autoritative Referenz → auf Minimal-Usage + Pointer gekürzt.
- `statusline.lua` — Header verwies auf `LUA_NVIM.md "Metatables, schwache
  Tabellen, Memoisierung"` (deutscher Titel, Datei existiert im Public-Repo
  nicht — Rest einer persönlichen Notiz). Pointer entfernt; das Weak-Key-
  Schema ist ohnehin inline bei `_merged_cache` erklärt.
- `@types/init.lua` — die `Sessions.Keymaps`-`@class`-Doku sagte die
  „delete/rename nicht mappbar"-Begründung **dreimal** (3 Absätze) → auf
  eine Aussage zusammengezogen. (Dieselbe Rationale steht zusätzlich in
  `DEFAULTS.lua`, `bindings/keymaps/init.lua` Header **und** dessen
  `UNMAPPABLE`-Block — s.u.)
- `bindings/keymaps/init.lua` — Modul-`@description` (12 Z. zur selben
  delete/rename-Regel) auf 4 Z. gekürzt; die `UNMAPPABLE`-Rationale stand
  fast wortgleich an der Deklaration (Z. 41-45) **und** an der Benutzungs-
  stelle (Z. 99-101) — Muster #3, beide gestrafft, Dopplung raus.
- `bindings/autocmds/init.lua` — `hand_rolled_confirm`-Header: „the roadmap
  asks for an actual floating prompt" (Dev-Prozess-Sprache) raus, die
  technische „nicht `vim.ui.select`"-Begründung bleibt.
- `git.lua` (`M.sanitize`) — shoutende, den Doc-Block dopplende Inline-
  Kommentare (`WHITELIST:`/`FIRST`) eingedampft; kurioser `@param`-Meta-
  Kommentar („the first line of the body says so") → `nil or empty -> ""`.
- `core.lua` — zwei `resolve()`-Aufrufstellen-Kommentare korrigiert: der
  Load-Pfad-Kommentar sagte „use default_name (\"last\")", der Code
  bevorzugt aber die gemerkte last-loaded-Session (Muster #5).

**Kein toter Code** — alle Kandidaten sind über die Public API (`init.lua`),
`:Session`-Subcommands oder die dokumentierte `sessions.statusline.component`-
API erreichbar; extern (`C:/repos/*.nvim` + `E:/repos/*.nvim`) `require`t
nichts `sessions.*`-Interna (nur `casedesk.nvim/docs/SESSIONS.md`, reine
Doku). **Kein WKDBooks-Umzug** — kein ortsunabhängiges Mechanik-Wissen.

**CI/Gate:** `stylua --check lua TESTS` (v2.5.2) ok, `luacheck lua TESTS`
(1.2.0) 0/0 über **26 Dateien** (`@types/init.lua` mitgeprüft — luacheck
1.2.0 überspringt es hier nicht), `TESTS/run.lua` headless grün
(`SESSIONS_TESTS_OK`, lib.nvim als Sibling aus `E:/repos/lib.nvim`).

Commit: sessions.nvim `6c4422f`, gepusht (`160a97a..6c4422f`),
`pull --ff-only` „Already up to date", `git log origin/main` bestätigt.
Ohne Co-Authored-By.

### Häppchen 20 — dap.nvim (Plugin-Repo 3/31)

**Status: erledigt.** ~3140 Z. Lua (47 Dateien inkl. TESTS), eigenes `main` /
Remote `StefanBartl/dap.nvim`. Config-Layer auf mfussenegger/nvim-dap. Wie die
beiden vorigen Plugin-Repos war es schon fast durchgehend auf Sweep-Qualität:
durchweg Englisch (kein einziges deutsches Wort), Header mit echter
ortsrelevanter Rationale, keine AI-Boilerplate. `lua/wkddap/health.lua` war
schon früher in dieser Session gesweept — nicht erneut angefasst. Depends on
`lib.nvim` (bewusst, kein Fund).

**Geänderte Dateien (Source, 11):** `config/DEFAULTS.lua`,
`core/capabilities.lua`, `core/state.lua`, `registry.lua`, `utils/validation.lua`,
`languages/{assembly,browser,c,csharp,lua,rust,zig}.lua`.

**Bereits sauber, 0 Änderungen:** `init.lua`, `config/init.lua`, `@types/init.lua`,
`adapters/init.lua`, `configurations/init.lua`, `core/{init,setup,breakpoints}.lua`,
`bindings/*` (alle 4), `ui/*` (alle 8), `integrations/menu.lua`,
`utils/{executable,mason,notify,paths}.lua`, `languages/{go,javascript,python}.lua`,
`plugin/dap.lua`, alle `TESTS/*`.

**Direkte Fixes (Kommentar/Doc, keine Verhaltensänderung):**
- `config/DEFAULTS.lua` — der „Empty = all available"-Kommentar zählte eine
  falsche Sprachliste auf: die Aliase `typescript`/`cpp` als wären es
  Basissprachen, und `bash`/`csharp`/`browser` fehlten ganz. Auf die echte
  Liste korrigiert + Pointer auf `wkddap.registry` (die autoritative
  `SUPPORTED_LANGUAGES`).
- **6× identischer 4-Zeilen-Block** „nvim-dap resolves config functions inside
  coroutine.wrap() …" in `languages/{assembly,c,csharp,lua,rust,zig}.lua` — die
  Mechanik ist bereits vollständig in `docs/FEATURES/LANGUAGES.md` beschrieben
  (Muster #6). Auf einen Ein-Zeilen-Pointer eingedampft. `zig.lua`s zweiter
  Block („build first") auf das lokal-relevante Invariant (spawn-vor-yield ist
  sicher) gekürzt.
- **Doc-Staleness (eigener Commit):** `bindings/which_key/init.lua` wurde in
  `550a8d7` gelöscht (das Gruppenlabel ist jetzt ein Feld der Keymap-Spec),
  aber `docs/architecture.md`, `docs/BINDINGS.md` und
  `docs/FEATURES/CONTROLS.md` verwiesen noch auf das gelöschte Modul (CONTROLS
  beschrieb sogar dessen `setup`/`available` + „which-key v2/v3 APIs") — alle
  drei auf `bindings/keymaps/init.lua` umgebogen. Muster #4, exakt wie
  Häppchen 18 (recommender: `which_key.lua`).
- „eight languages" → „eleven" in `README.md` + `docs/FEATURES/README.md`
  (READMEs eigener Intro-Absatz sagt schon „eleven targets").
- `docs/architecture.md` `languages/`-Liste: `bash`/`browser`/`csharp` ergänzt.

**Toter Code gelöscht** (0 Aufrufer im Repo + TESTS + allen 30 anderen
Plugin-Repos; nicht in irgendeiner `docs/*`-API-Liste; interner Namespace):
- `utils/validation.lua` `M.validate_file` (18 Z.). `pick_process` (der einzige
  echte Nutzer des Moduls, aus `languages/javascript.lua`) bleibt; Modul-Header
  entsprechend eingedampft.

**`--- CDX:` gesetzt (Urteilssache, nicht gefixt):**
- `languages/browser.lua` (`load`) — der Kommentar behauptet gegenseitige
  Sicherheit („whichever loads second must not drop the other's entries"), aber
  `javascript.lua`s `load()` **assignt** `dap.configurations[ft]` statt zu
  appenden. Der Vertrag hält nur in der Default-Ladereihenfolge (javascript vor
  browser in `registry.SUPPORTED_LANGUAGES`); `languages = { "browser",
  "javascript" }` löscht die Browser-Configs wieder.
- `core/state.lua` — `set_session_active` hat **keinen** Aufrufer, also ist
  `session_active` immer `false`; `is_session_active()`/`is_initialized()`
  werden nie gelesen. Nur `init()` ist verdrahtet. Vestigiale API oder
  unfertiges Session-Tracking.
- `core/capabilities.lua` — `detect()` läuft (aus `core/setup.lua`) und füllt
  `_features`, aber nichts liest es: `has()` hat keine Aufrufer und `health.lua`
  macht seine eigenen `pcall(require, …)`-Proben. Ergebnis wird berechnet und
  verworfen.
- `registry.lua` `registered_languages()` — keine Aufrufer (Repo oder TESTS),
  nicht in der dokumentierten Registry-API
  (`docs/FEATURES/LANGUAGES.md`: register/register_all/is_enabled/validate/stats).

**Keine Annotation-Fixes nötig** (`@types/init.lua` deckt `Dap.Config` &
Untertypen korrekt ab; die Felder stimmen mit `DEFAULTS.lua` überein).
**Kein WKDBooks-Umzug** — das einzige ortsunabhängige Mechanik-Wissen (die
coroutine.wrap-Idiom) liegt bereits im plugin-eigenen `docs/FEATURES/LANGUAGES.md`.

**CI/Gate:** `stylua --check lua/ plugin/ TESTS/` (v2.5.2) sauber,
`luacheck lua plugin TESTS` (1.2.0) **0/0 über 47 Dateien**, plenary-Suite
headless grün (25/25: configurations 4, registry 6, usercmds 3, program_prompt
12; lib.nvim als Sibling aus `E:/repos/lib.nvim`). CI-Workflow nutzt Lua 5.1
für luacheck (Kommentar in `ci.yml`: 1.2.0 lädt unter 5.5 nicht).

Commits: dap.nvim `16a2440` (source) + `4f445c9` (docs), gepusht
(`66b4a92..4f445c9`), `pull --ff-only` + `git log origin/main` bestätigt.
Ohne Co-Authored-By.

**Nebenfund, nicht bearbeitet:** `bindings/keymaps/init.lua`s Header sagt „move
all fourteen or none" — `order` listet 13 Aktionen, aber `eval` bindet n+v, was
14 tatsächliche Mappings ergibt; vertretbar, nicht angefasst.

### Häppchen 21 — cmdlog.nvim (Plugin-Repo 4/31)

**Status: erledigt.** ~3900 Z. Lua (41 Dateien inkl. TESTS), eigenes `main` /
Remote `StefanBartl/cmdlog.nvim`. Config-Layer über Neovim-`:`-History + Shell-
History + Favoriten-Pickers (Telescope / fzf-lua). Wie die drei vorigen Plugin-
Repos schon fast durchgehend auf Sweep-Qualität: durchweg Englisch (**kein
einziges deutsches Wort** außer einem eigenen `--AUDIT:`-Marker), Header mit
echter ortsrelevanter Rationale, keine AI-Boilerplate. `lua/cmdlog/health.lua`
war früher gesweept — nur ein offensichtlicher Leftover angefasst (s.u.).
Depends on `lib.nvim` (bewusst, kein Fund).

**Muster #1 (which_key-Modul gelöscht, Docs stale) trifft hier NICHT zu** —
`integrations/which_key.lua` existiert und ist verdrahtet; Docs verweisen
korrekt darauf.

**Geänderte Dateien (24):** `@types/init.lua`, `bindings/{autocmds,init,keymaps,
picker_mappings,usrcmds}.lua`, `config/DEFAULTS.lua`, `core/{errors,
project_history,shell,stats,store,tags}.lua`, `health.lua`,
`integrations/which_key.lua`, `ui/{fzf-previewer,history_picker,
history_unique_picker,mappings,picker_utils,preview_policy,risky_test,
shell_picker,shell_unique_picker}.lua`.

**Bereits sauber, 0 Änderungen:** `init.lua`, `config/init.lua`,
`bindings/keymaps.lua`-Logik, `core/{extra_files,favorites,history,risky,
tracker,utils}.lua`, `ui/{all_picker,all_unique_picker,cycle,favorites_picker,
lua_picker,project_picker,stats_picker,telescope-previewer}.lua`, alle `TESTS/*`.

**Direkte Fixes (Kommentar/Annotation, keine Verhaltensänderung):**
- `core/shell.lua` — eigener deutscher `--AUDIT: Modularisieren, Annotationen
  klären` → englischer `--- CDX:`. Zusätzlich: der `M.get_shell_history`-Doc-
  Block stand ~40 Zeilen vor der Funktion (dazwischen ein `---@alias` + drei
  Helfer), LuaLS hängte ihn an `Cmdlog.ShellHistoryParser` statt an die
  Funktion — zurück an die Funktion gezogen, den Alias-Kommentar an Ort
  belassen und gestrafft.
- `core/project_history.lua` — toter Doc-Verweis `PERFORMANCE.md ->
  Cache-Regeln` (Datei existiert im Public-Repo nicht, deutscher Anker,
  Rest der nvim-config-internen Fassung) entfernt. Zweiter Fund in derselben
  Datei: `get_git_root`-Docstring sagte „to avoid spawning `git rev-parse`",
  der Code darunter macht seit einer Migration einen `vim.fs`-Walk und der
  Inline-Kommentar sagt das auch — Docstring angeglichen (Muster #5).
- `bindings/usrcmds.lua` — `M.register`-Docstring: „plus **two** routes
  (`export`/`import`)", registriert werden aber **drei** (`risky test`,
  `export`, `import`) direkt daneben. Muster #7 (unvollständige Command-Liste),
  wie Häppchen 7/10/18/20.
- `ui/mappings.lua` — Docstring-Parenthese zählte 5 von 9 behandelten Mapping-
  Keys auf → generalisiert („jeder Key aus `config.options.mappings`").
- `health.lua` (einziger Leftover): die Invalid-picker-Fehlermeldung nannte
  „expected 'telescope' or 'fzf'", die Prüfung eine Zeile darüber akzeptiert
  auch `fzf-lua` → ergänzt.
- Stale „used to / previously"-Historie gekürzt in `bindings/autocmds.lua`
  (Header „ging zweimal leer … 2026-08-27"), `core/store.lua`,
  `integrations/which_key.lua`, `ui/risky_test.lua`, `ui/fzf-previewer.lua`,
  `config/DEFAULTS.lua`.
- Die „ersetzte eine feste Keymap-Tabelle"-Notiz stand 3× (DEFAULTS.lua,
  bindings/keymaps.lua, @types) → je auf einen Satz eingedampft (Muster #3).
- `ui/{history,history_unique,shell,shell_unique}_picker.lua` — der
  identische 5-Zeilen-Block „delete_entry ist synchron / async-Kontrakt / hat
  gecrasht" stand 4× (Muster #3), auf 2–3 Zeilen gekürzt; dabei redundante
  Inline-`require`s auf schon am Modulkopf geladene Module entfernt (kein
  Verhaltenswechsel, `require` ist gecached — wie Häppchen 2).

**`--- CDX:` gesetzt (Urteilssache, nicht geändert):**
- `bindings/init.lua` — `catalog()` gibt `keymaps = …keymaps.catalog` zurück
  (**die Funktion**, nicht die aufgelöste Tabelle); die Geschwister-Einträge
  sind Daten, und `which_key.lua` ruft `.catalog()` mit Klammern. Wirkt wie
  ein Bug in der Introspektions-Hilfe.
- `ui/picker_utils.lua` — `open_picker` verzweigt nur bei `picker == "fzf"`
  zu fzf-lua; `health.lua` **und** `@types` akzeptieren zusätzlich
  `"fzf-lua"`, das dann still in den Telescope-Zweig fällt. Drei Stellen,
  drei verschiedene Wertelisten (analog zu dap.nvims DEFAULTS-Fund, Häppchen 20).
- `bindings/picker_mappings.lua` — `M.catalog` dokumentiert 4 von 10
  konfigurierbaren Picker-Keys, während `docs/BINDINGS.md` behauptet die Datei
  „mirrors" die vollständige Tabelle. Muster #7, aber als Daten-Katalog
  (fließt in `bindings.catalog()`) — daher getaggt statt selbst vervollständigt
  (Regel 9, keine Verhaltensänderung).
- `ui/preview_policy.lua` — `classify()`s `cmd:match("…e%d?dit…")`: das `%d?`
  matcht nichts Sinnvolles und das Muster akzeptiert nur das ganze Wort
  `edit`, also klassifizieren `:e file` / `:ed file` nie als „file"; `:split`
  / `:sp` fehlen ganz (nur `:vsp` / `:vs` sind da).
- `core/errors.lua` `get_error`, `core/tags.lua` `remove_tag`, `core/stats.lua`
  `all` — je 0 Aufrufer, nicht dokumentiert (die jeweiligen Geschwister
  `is_known_bad` / `add_tag`+`get_tags` / `by_frequency`+`describe` werden
  benutzt). Vestigiale Accessor-Hälften. **Nicht gelöscht** (plausible
  bewusste API-Fläche, Zweifel → taggen, Regel 5). `tags.filter` ist in
  `docs/FEATURES/FAVORITES.md` dokumentiert → bleibt unangetastet.

**Kein toter Code gelöscht** (alle Kandidaten getaggt statt gelöscht — s.o.).
**Kein WKDBooks-Umzug** — kein ortsunabhängiges Neovim-/Lua-Mechanik-Wissen;
die einzige LuaLS-Notiz (`(fun():T)|nil`-Union-Parsing in `shell.lua`) ist
kurz und spezifisch für den dortigen `@alias`.

**CI/Gate:** `stylua --check lua TESTS` (v2.5.2) sauber, `luacheck lua` (1.2.0)
**0/0 über 40 Dateien**, `nvim -l TESTS/smoke_spec.lua` (REPOS_DIR=E:/repos,
lib.nvim + telescope + plenary als Siblings) **72 passed / 0 failed / 1
skipped**. CI-Pins lokal exakt gematcht.

Commit: cmdlog.nvim `058f2b2` (`2b8b7be..058f2b2`), gepusht auf `origin/main`,
`pull --ff-only` „Already up to date", `git log origin/main -1` bestätigt.
Ohne Co-Authored-By.

**Nebenfund, nicht bearbeitet:** `all_picker.lua` / `all_unique_picker.lua`
sagen „Supports Telescope and fzf as picker backends" — knapp, nicht falsch
(fzf-lua-Backend existiert), gelassen.

### Häppchen 22 — emojis.nvim (Plugin-Repo 5/31)

**Status: erledigt.** ~3625 Z. Lua (`lua/` 24 Dateien + 10 `TESTS/*`), eigenes
`main` / Remote `StefanBartl/emojis.nvim`. Emoji-Toolkit (clear/replace/wrap,
Insert-Picker, Frecency-Overlay, Emoji-Checkboxen, async `cwd`-Suche). Wie die
vier vorigen Plugin-Repos schon fast durchgehend auf Sweep-Qualität: durchweg
Englisch (ein einziges deutsches Wort, s.u.), Header mit echter
ortsrelevanter Rationale, keine AI-Boilerplate, keine Chat-Artefakte.
`lua/emojis/health.lua` war früher gesweept — sauber, nicht angefasst.
Depends on `lib.nvim` hart (composer für `:Emojis`, `ui.kit` fürs Overlay) —
bewusst, kein Fund.

**Geänderte Dateien (11):** `lua/emojis/{search,actions,config/DEFAULTS,
core/patterns,core/checkbox,overlay/init,overlay/frecency}.lua`,
`docs/{architecture,FEATURES,keymaps}.md`, `doc/emojis.txt`.

**Bereits sauber, 0 Änderungen:** `init.lua`, `commands.lua`, `nav.lua`,
`picker.lua`, `@types.lua`, `config/init.lua`, `core/{ops,scope,insert}.lua`,
`bindings/*` (alle 4), `util/{lib,notify}.lua`, `health.lua`, beide
`plugin/*.lua`, alle `TESTS/*`.

**`--- CDX:` gesetzt (Urteilssache / Bug in passing, nicht gefixt):**
- `search.lua` `RG_PATTERN` — deckt nur **3 der 4** `core.patterns.RANGES` ab;
  der Misc-Technical-Block (U+2300-23FF: ⌚ ⏳ ⏰ …) fehlt, obwohl der
  Tokenizer ihn kennt (`patterns_spec.lua:27` testet `count("⌚") == 1`). Damit
  überspringt `:Emojis list/count/clear/replace cwd` still genau diese Glyphen,
  während jede buffer-scoped Aktion sie trifft. Der Modul-Header behauptete
  „mirrors the byte patterns used by `core.patterns`" — auf „lags by one range"
  korrigiert. Range ergänzen = Verhaltensänderung, daher nur getaggt.
  (Muster: Regex-Kommentar ≠ tatsächliches Verhalten.)
- `config/DEFAULTS.lua` `checkbox.default_set` — in DEFAULTS, `@types` **und**
  `docs/configuration.md` als „die Zyklus-Menge, die `:Emojis toggle` ohne
  Argument nutzt" dokumentiert, aber **kein Code-Pfad liest das Feld**:
  `config.checkbox_sets(nil)` durchsucht immer alle Sets. Entweder verdrahten
  oder Feld + Doc-Zeilen streichen. (Muster #5, Kommentar widerspricht Code.)
- `core/patterns.lua` `M.BASE` — Export ohne einen einzigen Leser (Repo, TESTS,
  alle Nachbar-Plugins), keine dokumentierte API, exponiert die kompilierten
  Per-Range-Lua-Patterns (Implementierungsdetail). Vestigial neben dem
  benutzten `M.VS16`. **Nicht gelöscht** (plausible bewusste API-Fläche,
  Zweifel → taggen, Regel 5).

**Toter Code gelöscht** (0 Aufrufer im Repo + TESTS + allen anderen
Plugin-Repos; nicht dokumentiert; expliziter Intern-Namespace):
- `overlay/init.lua` `M.MODES` — Kommentar „Exposed for command completion",
  aber `commands.lua` nutzt seine eigene lokale `OVERLAY_MODES`-Liste; war die
  **vierte** Kopie derselben Mode-Liste (dazu `overlay`-lokale `MODES`,
  `config.VALID_OVERLAY_MODES`, `commands.OVERLAY_MODES`). Nie ein Leser seit
  dem Initial-Overlay-Commit.
- `overlay/frecency.lua` `M._invalidate` — `_`-Präfix, Doc „Testing seam",
  0 Aufrufer; `set_path()` (nilt `_store` mit) und `reset()` sind, was die
  Tests nutzen.

**Direkte Fixes (Kommentar/Doc, keine Verhaltensänderung):**
- `actions.lua` `preview_spans` — stale „Previously this blocked the UI thread
  with `vim.wait` … It now schedules …"-Historie auf eine Präsens-Beschreibung
  eingedampft; der Inline-Zwilling bei `apply()` mitgestrafft (Muster #3 +
  „used to / previously"-Historie).
- `core/checkbox.lua` — deutsches „Hallo" im Header-Beispiel → „Hello" (das
  einzige deutsche Wort im Repo).
- **Doc-Staleness (Muster #1, eigener Commit):** `bindings/which_key.lua` wurde
  in `1d50050` gelöscht (das Gruppenlabel ist jetzt ein Feld der Keymap-Spec,
  `which_key = { group = "Emojis" }` in `bindings/keymaps.lua`), aber
  `docs/architecture.md`, `doc/emojis.txt`, `docs/FEATURES.md` (§„Which-key
  group labeling", inkl. `- **Module:**`) und `docs/keymaps.md` listeten das
  Modul noch. Alle vier auf `bindings/keymaps.lua` umgebogen. Exakt wie
  Häppchen 18/20 (recommender: `which_key.lua`, dap: `which_key/init.lua`).

**Keine Annotation-Fixes nötig** (`@types.lua` deckt alle Config-Untertypen
korrekt ab, Felder stimmen mit `DEFAULTS.lua` überein — inkl. der
`Picker.Engine`-Alias-Werte, die `picker.lua`/`health.lua` konsistent
behandeln; der cmdlog-Fund „drei Stellen, drei Wertelisten" trifft hier
**nicht** zu). **Kein WKDBooks-Umzug** — kein ortsunabhängiges Neovim-/Lua-
Mechanik-Wissen; die langen Header (`commands.lua` composer-forward,
`patterns.lua` Grapheme-Regeln, `overlay/init.lua` Grid-vs-kit) sind
ortsrelevante Design-Rationale und verweisen schon aufs plugin-eigene `docs/`.

**CI/Gate:** `stylua --check lua TESTS` (v2.5.2) sauber, `luacheck lua TESTS`
(1.2.0) **0/0 über 34 Dateien** (`@types.lua` mitgeprüft), TESTS-Suite headless
grün (`EMOJIS_TESTS_OK`, lib.nvim als Sibling aus `E:/repos/lib.nvim`).
CI-Pins lokal exakt gematcht.

Commits: emojis.nvim `45c25e2` (source) + `5c0e330` (docs), gepusht
(`a93462f..5c0e330`), `pull --ff-only` „Already up to date",
`git log origin/main -1` bestätigt. Ohne Co-Authored-By.

### Häppchen 23 — diff.nvim (Plugin-Repo 6/31)

**Status: erledigt.** ~2400 Z. Lua (`lua/diff/` 24 Dateien + 17 `TESTS/*`),
eigenes `main` / Remote `StefanBartl/diff.nvim`. Config-Layer über natives
`vim.diff`/diffmode: `:Diff` mit `source=`/`target=`/`base=` (Datei, Puffer,
`git:<rev>`, `http(s)://`, Clipboard, Verzeichnis-Baum), Three-Way, Inline/
Float/Split/Tab-Views, `:DiffOrig`, `:DiffExit`, Statusline-Komponente,
Bild-Vergleich via images.nvim. Wie die fünf vorigen Plugin-Repos schon fast
durchgehend auf Sweep-Qualität: **durchweg Englisch** (kein einziges deutsches
Wort in `lua/`/`TESTS/`), Header mit echter ortsrelevanter Rationale, keine
AI-Boilerplate. `lua/diff/health.lua` war früher gesweept (advice-args,
pre-setup-Guard → info) — nur eine offensichtliche Migrations-Leiche
angefasst (s.u.). Depends on `lib.nvim` hart (notify, validate, ui.kit,
bindings.composer) — bewusst, kein Fund.

**Muster #1 (which_key-Modul gelöscht, Docs stale) trifft NICHT zu** —
diff.nvim hatte nie ein which_key-Modul (`bindings/keymaps.lua` sagt explizit
„no leader-prefixed group to label"); `BINDINGS.md §which-key` /
`configuration.md` sind konsistent.

**Zwei stale Migrations-Wellen quer durch Code + Docs — direkt gefixt:**

1. **`git:<rev>` ist seit `77fd89a` async** (ein Three-Way löst zwei Seiten
   auf, `vim.system(...):wait()` blockierte zweimal). `M.resolve` +
   `core/init.lua` waren korrekt, aber **stale geblieben:**
   - `core/git.lua` Modul-Header beschrieb noch den synchronen `:wait()`-Pfad
     (widersprach der eigenen `M.resolve`-Docstring direkt darunter).
   - Docs: `commands.md`, `docs/FEATURES.md`, `docs/WORKFLOW.md`,
     `docs/url-sources.md` (die den Kontrast „git resolves synchronously"
     aktiv zog), `doc/diff.txt` — alle nannten `git show` synchron.
2. **Der Ziel/Quell-Picker-Fallback wanderte von `vim.ui.select` zu
   `lib.nvim.ui.kit`** (`78c8830`/`0b3152d`/`1e67629`, kit.confirm-Button-Row
   für die ≤4-Choice-Picker, kit.select für die Puffer-Liste, `respect_override`
   ehrt einen echten `vim.ui.select`-Override weiter). Nie nachgezogen in:
   `core/pickers_bridge.lua`-Header, `config/DEFAULTS.lua` (`use_pickers_nvim`-
   Kommentar), `health.lua:85` (**user-sichtbarer `:checkhealth`-String** —
   die eine „offensichtliche Leiche", die health rechtfertigte), `core/init.lua`
   (`kit_select_select`/`kit_confirm_select`-Docstrings verwiesen auf einen
   „vim.ui.select fallback", den es nicht mehr gibt, + 2 falsche above/below-
   Richtungsangaben), `configuration.md`, `docs/FEATURES.md`, `docs/WORKFLOW.md`,
   `doc/diff.txt` (Schritt 3 + Cancel-Notification-Referenz).

**Weitere direkte Fixes (Kommentar, keine Verhaltensänderung):**
- `core/url.lua` Header: implizierte, `curl --max-time` werde übergeben (wird
  es nicht — die argv enthält nur `--max-filesize`); der libuv-Timer ist die
  einzige Zeitschranke. Umformuliert.
- `features/image_compare.lua` Header: verwirrende Cross-Plugin-Prosa
  („`imports.graph.include_external`-style config (`diff.image_compare`) turns
  this off") → `diff.image_compare = false` turns this off entirely.
- `bindings/usrcmds.lua` Modul-Header 16 → 11 Z.: Dev-Prozess-Historie
  („the case that originally motivated Phase 7's kv support"), Wiederholung
  von „composer" raus; die lokale Rationale (kv-Schema nur für `<Tab>`,
  `values` statt `enum`) bleibt.

**`--- CDX:` gesetzt (1, Urteilssache):**
- `core/init.lua` `M.valid_lists()` — **0 Aufrufer** irgendwo (Repo, TESTS,
  Docs, andere Plugin-Repos); der Docstring sagt „for completion/health",
  aber `health.lua` und `bindings/usrcmds.lua`s `VALUE_LISTS` re-deklarieren
  die `VALID_VIEWS`/`VALID_OUTPUTS`-Listen beide selbst. Vestigiale
  Accessor-Hälfte — nicht gelöscht (plausible bewusste Introspektions-API,
  Zweifel → taggen, Regel 5).

**Kein toter Code gelöscht** (der einzige Kandidat getaggt). **Keine
Annotation-Fixes nötig** (`@types.lua` deckt `DiffNvim.Config` + Untertypen
korrekt ab, Felder ↔ `DEFAULTS.lua` stimmen; `DiffNvim.Opts`-Spiegel komplett;
keine Methoden-als-Feld-Fehler). **Kein WKDBooks-Umzug** — kein
ortsunabhängiges Neovim-/Lua-Mechanik-Wissen; die langen Header
(`core/render.lua` UTF-8-Codepoint-Word-Diff, `core/directory.lua`,
`features/native_diffthis.lua`) sind ortsrelevante Design-Rationale und
verweisen schon aufs plugin-eigene `docs/`.

**CI/Gate:** `stylua --check .` (v2.5.2) sauber, `luacheck lua plugin TESTS`
(1.2.0) **0/0 über 40 Dateien** (`@types.lua` mitgeprüft), Spec-Suite headless
grün (15/15, `DIFF_NVIM_TESTS_OK`, `LIB_NVIM_PATH=E:/repos/lib.nvim`). CI-Pins
lokal exakt gematcht.

Commits: diff.nvim `c170513` (source) + `089f945` (docs), gepusht
(`3435d2e..089f945`), `pull --ff-only` „Already up to date",
`git log origin/main -1` bestätigt. Ohne Co-Authored-By.

### Danach offen

**Der gesamte `lua/`-Baum + `init.lua` der nvim-config ist durch.** Verbleibend
im Sweep: **die 31 Plugin-Repos** (Liste unten), repo-für-repo, je 1 Agent.

Offene Aufräum-Punkte aus dem Sweep, die bewusst NICHT gefixt wurden (jeweils
`--- CDX:` im Code + im jeweiligen Häppchen dokumentiert) — eigene
Autorenentscheidung nötig, siehe Häppchen 8/9/10/12/15/16:
- `config/noice/init.lua` catch-all-Route dead-codet alle nachfolgenden Routes
- `config/neotest/whichkey/init.lua:69` `<leader>ntS` → nicht-existente Funktion
- `config/neotest/debug/init.lua` TS-Root-Detection läuft nie
- `config/harpoon/preview.lua` `require` auf nicht-existentes Modul
- `hl_config` 5 Bugs (u.a. `extract_lua_field_key` gibt Quote statt Key)
- `wkdnvchad` lspbased-Variante (`chadrc`-require kaputt), `neotest_module` tot+kaputt
- `lua/plugins/workflow.lua` 82-Z. auskommentierter `autolist.nvim`-Block
- `PERFORMANCE.md` (wkdoptions/docs) fabrizierte Benchmarks

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
