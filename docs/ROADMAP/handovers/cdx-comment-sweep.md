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

> **Häppchen 1–33 sind abgeschlossen und archiviert.** Die vollständigen
> Fund-Protokolle (Details, Datei-Listen, jede `--- CDX:`-Begründung, alle
> Commit-Hashes) liegen in
> [`cdx-comments-docs.md`](../personal/All/FINISH/ERLEDIGT/cdx-comments-docs.md).
> Hier nur ein Ein-Zeiler pro Häppchen, damit dieses Handover schlank bleibt.
> Laufende Arbeit (aktuell lib.nvim, Häppchen 34) steht wie gewohnt unten in
> voller Länge, solange sie nicht abgeschlossen ist.

**Standing-Reminder (aus dem früheren „Danach offen"-Zwischenstand):** bei
jedem Plugin-Repo-Häppchen die which-key/machine-readable-Phrasen in
`keymaps.md`/`README.md`/`FEATURES/*`/`doc/*.txt` mitprüfen — der
`BINDINGS.md`-Cleanup selbst war zum Zeitpunkt von Häppchen 25 für alle
14 relevanten Repos bereits erledigt.

1. **`lua/autocmds/`** (16 Dateien) — AUDIT/FIX-Marker vereinheitlicht;
   nach User-Kalibrierung 1 toter Fn gelöscht (`snorm_pattern`).
2. **`lua/bindings/mappings/`** (23 Dateien) — toter auskommentierter Code
   an 6 Stellen gelöscht, Deutsch→Englisch an user-sichtbaren Stellen.
3. **`lua/bindings/usrcmds/bindings_explorer/`** (13 Dateien, außer
   `drift.lua`) — komplett Deutsch→Englisch (−72 Z.); 1 toter Pfad getaggt
   (`BND-05`, Funktionsentscheid offen).
4. **`lua/bindings/usrcmds/case/`** (39 Dateien, 11.295 Z., casedesk) —
   alle noch deutschen Code-Kommentare übersetzt; deutsche User-Strings/
   Datenmaps/„Paket N"-Referenzen bewusst behalten.
5. **`drift.lua`** (2812 Z., reiner Prosa-Trim) — Header 210→46 Z., Rest
   2665→2558 Z., keine `--- CDX:`-Tags nötig.
6. **`usrcmds/`-Rest + `telemetry.lua`** (6 Ziele) — Deutsch→Englisch, 2
   stale Doc-Refs gefixt (falsche Präzisionswerte, toter Link).
7. **`usrcmds/plugin_repos/`** (3 Dateien) — Header dedupliziert,
   `M.enable()`-Docstring fehlten 6 von 10 Subcommands (gefixt).
   **`lua/bindings/` damit komplett durch (87/87 Dateien, 22.774 Z.).**
8. **`lua/config/` kleine Ordner + `ui_open.lua`** (16 Ziele) — **echter
   Funktionsbug getaggt, nicht gefixt:** eine noice-catch-all-Route killt
   alle nachfolgenden Routes; 3 KI-Assistent-Configs bestätigt verwaist
   (bewusst auskommentiert); 3 Wissens-Umzüge nach WKDBooks.
9. **`lua/config/harpoon/`** (12 Dateien) — `HardeningState`-Typ fehlten 2
   reale Felder (gefixt), 1 toter Typ gelöscht, 1 Tuning-Doku nach
   `docs/NOTES/Harpoon.md` ausgelagert.
10. **`lua/config/neotest/`** (21 Dateien) — **2 echte Laufzeitbugs
    getaggt, nicht gefixt** (crasht bei `<leader>ntS`; TS-Root-Detection
    läuft nie). Adapter-Split-Brain war bereits als Plan dokumentiert, nur
    eine Lücke ergänzt.
11. **`lua/config/neotree/`** (29 Dateien) — 2 tote Module gelöscht, 2
    `@types`-Fixes (Methoden fälschlich als `boolean`-Felder typisiert),
    `event_handlers/README.md` komplett neu geschrieben (beschrieb 4
    Handler, nur 1 existiert noch). **`lua/config/` damit komplett durch.**
12. **`lua/plugins/` Top-Level + 3 kleine Ordner** (22 Dateien) —
    doppelter `setup()`-Call entfernt (`neotest.lua`), toter
    auskommentierter Code entfernt, 1 Wissens-Umzug nach WKDBooks.
13. **`lua/plugins/personal/` + `lua/plugins/ai/`** (8 Dateien) — größter
    Fund: 95-zeiliger deutscher Duplikat-Kommentar (hover.nvim-Spec) auf
    20 Z. gekürzt; falscher `require`-Pfad in `avante.lua` gefixt.
    **`lua/plugins/` damit komplett durch.**
14. **`lua/wkdoptions/` ohne `hl_config/`** (26 Dateien) — 2 tote Module
    gelöscht (eines bereits in `Merged_Finished.md` als Redundanz
    dokumentiert, nie physisch entfernt), 1 echter `@types`-Fix.
15. **`lua/wkdoptions/hl_config/`** (38 Dateien, ~4940 Z.) — ~150 Z. toter
    „Pre-compiled Pattern System"-Code gelöscht, mehrere `@types`-Fixes,
    **2 echte Bugs getaggt** (Regex-Capture-Verwechslung in
    `extract_lua_field_key`, nie gesetztes `cfg._base_symbol`).
    **`lua/wkdoptions/` damit komplett durch.**
16. **`lua/wkdnvchad/`** (41 Dateien, ~4470 Z., Statusline/Tabufline/
    Theme-Switcher) — **3 echte Bugs getaggt, nicht gefixt** (totes
    lspbased-Statusline-Modul; kaputter `custom/`-Subtree; eager-`require`
    macht einen Lazy-Load-Kommentar falsch). **`lua/wkdnvchad/` damit
    komplett durch.**
17. **Kleinteile** (`startup/`, `themes/`, `nvchad/`, `@types/`, `after/`,
    root `init.lua`, `scripts/`) — winzige Fixes. **Gesamter `lua/`-Baum
    der nvim-config damit durch.**
18. **recommender.nvim** (Repo 1/31) — 8 Dateien geändert, 3 `--- CDX:`
    (u.a. Telescope-only-Limitierung bricht mit replacer.nvims
    fzf-Backend), 2 Doc-Staleness-Fixes.
19. **sessions.nvim** (Repo 2/31) — 7 Dateien geändert, 1 `--- CDX:`
    (Dirty-Tracking nur aktiv wenn `autosave = true`).
20. **dap.nvim** (Repo 3/31) — 1 toter Fn gelöscht, 4 `--- CDX:` (u.a.
    Browser/JS-Config-Ladereihenfolge-Abhängigkeit, tote
    Session-Tracking-API), Doc-Staleness (`which_key.lua` gelöscht, Docs
    nicht nachgezogen).
21. **cmdlog.nvim** (Repo 4/31) — 24 Dateien geändert, mehrere
    „N statt N+1"-Doc-Fixes, mehrfach duplizierte Rationale gestrafft.
22. **emojis.nvim** (Repo 5/31) — ~3625 Z. Lua, sauber durchgegangen.
23. **diff.nvim** (Repo 6/31) — ~2400 Z. Lua, sauber durchgegangen.
24. **fileops.nvim** (Repo 7/31) — ~4940 Z. Lua, sauber durchgegangen.
25. **open.nvim** (Repo 8/31) — Agent während der Apply-Phase gestoppt,
    seine 13 Änderungen verifiziert + committet, danach vollständiger
    Nachcheck (24 Dateien). **Vollständig abgeschlossen.**
26. **debugging.nvim** (Repo 9/31) — *[Ausnahme-Session: 2×3 parallele
    Agents]* tote Typfamilie gelöscht, 2 `--- CDX:` (u.a.
    `if considered_relevant or true` = wirkungslose Prüfung).
27. **filetree.nvim** (Repo 10/31) — 130 Lua-Dateien geprüft, **3 echte
    Funktionsbugs gefixt** (u.a. „Enter committet Suche als Filter"
    funktionierte nie); Liste 1 (`NVIM_CFG_CLEANUP`) für filetree.nvim
    damit inhaltlich abgeschlossen.
28. **github_stats.nvim** (Repo 11/31) — **1 echter Bug gefixt**
    (Fehlerhandler zeigte immer „nil"); komplette tote
    Dashboard-Architektur (88 Z.) + ein zweites totes
    Last-Fetch-Tracking-System gelöscht.
29. **hover.nvim** (Repo 13/31) — außergewöhnlich sauberes Repo, nur
    Doc-Staleness-Fixes (u.a. „Two ways" → tatsächlich drei seit einem
    alten Fix-Commit, der die Doku-Zeile nie nachzog).
30. **gopath.nvim** (Repo 12/31) — ergiebigstes Häppchen der
    Ausnahme-Session: **6 echte Bugs gefixt** (u.a. nie greifende
    Glob-Pattern-Root-Marker, Cache unter Literal-Key `0` statt echter
    Buffer-Nr., Off-by-one bei Cursor-Spalte); 1 totes Modul komplett
    gelöscht. *Ausnahme-Session (2×3 parallele Agents) damit
    abgeschlossen, zurück zu 1 Agent gleichzeitig.*
31. **images.nvim** (Repo 14/31) — ungewöhnlich gut gepflegt, kleiner
    Ertrag; 1 echter Fund (stale Tool-Dependency in `docs/install.json`).
32. **insights.nvim** (Repo 15/31) — Vorgänger-Agent brach am
    Sitzungslimit ab, 13 unkommittete Dateien verifiziert + 1
    Agentenfehler korrigiert (Java-Regex-Pattern) + verbucht. Doku-Nachzug:
    13 statt „fünf Tools".
33. **language.nvim** (Repo 16/31) — Build ist fertig; Hauptertrag waren
    stehengebliebene „Phase-N"-Bauzeit-Notizen, die dem fertigen Code
    widersprachen. 2 `--- CDX:` (immer-konstante Debounce-Ternaries).

### Häppchen 34 — lib.nvim (Plugin-Repo 17/31) — **`lua/`-Baum + TESTS/ komplett durch (Sub 1–11/13). PAUSIERT — Fortsetzung bei Sub 13 (docs/, letzter Schritt)**

lib.nvim ist mit **283 Quell-Dateien** (+ 49 Tests, 51 Docs) das größte Repo.
Wird wie `lua/bindings/` in Sub-Häppchen abgearbeitet, je 1 Agent. Plan:
1. ✅ `lua/lib/lua/` + Top-Level/@types/config/nvim_usrcmds/strategies
2. ✅ `lua/lib/nvim/bindings/` (composer)
3. ✅ `lua/lib/nvim/cross/`
4. ✅ `lua/lib/nvim/fs/`
5. ✅ `lua/lib/nvim/buf_win_tab/` + `window/` + `buffer/`
6. ✅ `lua/lib/nvim/ui/` (kit, 29 Dateien — Plan-Schätzung „20" war veraltet)
7. ✅ `lua/lib/nvim/{deps,logger,system,health,lua_ls,core}/` (34 Dateien,
   ~4540 Z.)
8. ✅ `lua/lib/nvim/{harvest,progress,markdown,lastcmd,cache,net,neotree,
   notify}/` (32 Dateien, ~4600 Z.)
9. ✅ `lua/lib/nvim/{normalize,safe_api,treesitter,frecency,git,debounce,
   async,selection,image_preview,dev,count,require,store,contextmenu,
   terminal,dotrepeat,token,json}/` (18 Dateien-Ordner, ~4350 Z.)
10. ✅ `TESTS/` Teil 1 — die 9 größten Spec-Dateien (`composer_spec`,
    `deps_spec`, `ui_kit_spec`, `autocmd_dispatcher_spec`,
    `nvim_helpers_spec`, `keymap_registry_spec`, `lua_helpers_spec`,
    `curl_spec`, `async_spec`; ~6710 Z.)
11. ✅ `TESTS/` Teil 2 — die restlichen 40 Dateien (kleinere Specs +
    `run.lua`/`harness.lua`; ~5580 Z.) — Plan-Schätzung „41" war knapp
    daneben: `TESTS/` hat tatsächlich 49 Dateien, nicht 50 (9 in Sub 10,
    40 hier)
12. ✅ `doc/` — 17 Vimdoc-Dateien, ~4560 Z. (gegen echte `@types`/Usercmds
    geprüft, wie in den nvim-config/Plugin-Häppchen üblich)
13. `docs/` — 51 Markdown-Dateien, ~5200 Z.  ← **HIER WEITER**

> **Nachtrag 2026-09-06:** derselbe Fehler wie schon bei Plan-Punkt 7 —
> „TESTS/ + doc/ + docs/" als ein Punkt war eine unvermessene
> Sammelschätzung (~22.000 Z. über 118 Dateien, das 5-fache eines
> normalen Sub-Häppchens). In vier Teile (10–13) aufgeteilt, TESTS/
> in zwei nach Größe gebildete Hälften, `doc/`/`docs/` je eigener Schritt.
> Gleiche Lektion wie in `plugin-roadmaps-verify-before-building`:
> Plan-Beschreibungen vor dem Bauen an der echten Größe prüfen — hier
> hätte auch der erste Split-Nachtrag schon `TESTS/`/`doc/`/`docs/`
> mitzählen sollen, statt sie unangetastet zu lassen.

**Sub-Häppchen 12 — erledigt** (`doc/` — alle 17 Vimdoc-Dateien gegen den
aktuellen `lua/`-Stand geprüft; Commit `99ea1b8`, gepusht, Re-Fetch
bestätigt HEAD == origin/main):

Direkte Fixes (echte Staleness, "N dokumentiert, N+1 real" oder faktisch
falsch — nach Sweep-Konvention immer direkt gefixt, kein CDX):
- **`lib.nvim-composer.txt`**: 3 reale Top-Level-Funktionen fehlten
  komplett in FUNCTIONS (`check_all`/`checkhealth`/`notify_check_all` —
  5 dokumentiert, 8 real). Größerer Fund: das USAGE-Beispiel rief
  `require("replacer").prompt()`/`.buffer()`/`.surround()` — keine davon
  existiert in replacer.nvims echter Public API (nur `setup`/`run`); auf
  `require("myplugin")` umgestellt, damit das Beispiel keine erfundene
  API mehr behauptet (der Lead aus dem Handover war noch offen, jetzt
  verifiziert und gefixt).
- **`lib.nvim-fs.txt`**: `polymorphic_rootresolver`s `cfg.resolve`
  (Alternative zu `cfg.markers`, echte Nutzung im Code) fehlte komplett
  in den Options. Vier ganze Submodule ohne jede Doku ergänzt:
  `globbable`, `watch`, `chdir`, `dir_guard` — alle real und substanziell.
  Die im Handover erwähnte "28 Submodule"-Zahl existierte im aktuellen
  Text gar nicht mehr (schon vorher entfernt) — nichts zu tun.
- **`lib.nvim-kit.txt`**: `kit.popup`s "Implemented"-Liste und die
  Alias-Kommentarzeile fehlten `compare` (echter Eintrag in der
  COMPONENTS-Dispatch-Tabelle); `kit.sync` (reale Funktion) fehlte
  komplett — beide ergänzt, plus Roadmap-Phasen 12/13. Der im Handover
  vermutete "Phantom-Aggregat"-Fund bestätigte sich NICHT: `require("lib.
  nvim.ui.kit")` ist ein echtes, funktionierendes Aggregat-Modul mit
  allen dokumentierten Methoden — stattdessen fehlte dem Modul komplett
  sein eigener Bare-Tag `*lib.nvim-kit*` (jeder `|lib.nvim-kit|`-Verweis
  aus anderen Dateien war dadurch tot); ergänzt.
- **`lib.nvim-deps.txt`**: `deps.detect` (das PATH-Probe-Modul hinter dem
  im Text bereits erklärten "gs vs. gswin64c"-Konzept) war komplett
  undokumentiert; ergänzt, plus die `require("lib.nvim.deps")`-
  Convenience-Wrapper (`plugins`/`show`/`install_for`).
- **`lib.nvim-logger.txt`**: `M.setup`/`is_enabled`/`tags`/`loggers`
  (global) und `inst.is_enabled` (pro Logger) existierten im Code, aber
  nicht in SWITCHES; ergänzt.
- **`lib.nvim-window.txt`**: `open_named_scratch` wurde nur beiläufig
  erwähnt, nie als eigene Funktion dokumentiert; `is_usable_window`/
  `target_window` (`find_usable.lua`) und `ensure_bottom`/
  `make_focusable`/`force_focus`/`focus_and_bottom` (`focus_helpers.lua`)
  fehlten komplett — 7 reale Public-Funktionen ohne jede Doku, jetzt
  ergänzt.
- **`lib.nvim.txt`** (Modul-Index): der `lib.nvim.cache`-Eintrag hatte
  einen fehlplatzierten `|lib.nvim-selection|`-Querverweis (Copy/Reflow-
  Fehler) — zum richtigen `selection`-Eintrag verschoben. `lib.lua.class`
  und `lib.lua.context_manager` fehlten in der `lib.lua`-Namespace-
  Tabelle; `count`/`debounce`/`dotrepeat`/`frecency`/`image_preview`/
  `json`/`lastcmd`/`net.curl`/`safe_api`/`token`/`async` fehlten in der
  `lib.nvim`-Tabelle — alles reale Module ohne Eintrag im Übersichts-
  Index, jetzt ergänzt (`dev` bewusst ausgelassen: internes Wartungs-
  Tool, keine Consumer-API).
- Tote `|tag|`-Querverweise gefixt (Ziel existierte nirgends in `doc/`):
  `|lib.nvim.ui.kit|`, `|lib.nvim.core|`, `|lib.lua.yaml|`,
  `|lib.nvim.cache.disk|` in `lib.nvim-deps.txt`; `|lib.nvim.normalize|`
  in `lib.nvim-composer.txt`; `|lib.nvim-notify|` in `lib.nvim-logger.txt`
  (dort außerdem der fehlende Bare-Tag `*lib.nvim-logger*` ergänzt);
  `|lib.nvim-cache|` in `lib.nvim-treesitter.txt`; `|lib.nvim-lib.nvim|`
  (sollte `|lib.nvim-modules|` sein) in `lib.nvim-spawn_env.txt`; zwei
  kaputte Tags in `lib.nvim-fs.txt` (`|lib.nvim.fs.normkey|` →
  `|lib.nvim-fs-normkey|`, `|lib.nvim.debounce|` de-linked, kein
  Doc-File dafür). Per Skript gegen jeden in `doc/*.txt` definierten
  `*tag*` geprüft — danach keine toten Links mehr in allen 17 Dateien.

`CDX:` gesetzt (Judgment Call, nicht gefixt):
- `lib.nvim-composer.txt`, direkt nach dem korrigierten USAGE-Beispiel:
  ob das Beispiel stattdessen 1:1 aus replacer.nvims echter `:Replace`/
  `:Surround`-Registrierung destilliert werden sollte (dort nur
  `path = {}`-Root-Routes, weniger illustrativ für Subcommand-Routing)
  oder wie jetzt gefixt ein `require("myplugin")`-Platzhalter bleibt.

Kein Wissens-Umzug nach WKDBooks nötig diesmal (kein Vimdoc-Text, der
eher als Markdown-Prosa gehört hätte, oder umgekehrt).

Verifiziert: `TESTS/run.lua` meldet weiterhin `LIB_TESTS_OK` (kein
`lua/`-Code in diesem Schritt angefasst); `doc/tags` bewusst nicht
committet (`.gitignore`-Eintrag, nie getrackt — lokale `:helptags`-
Regenerierung nur zur Verifikation genutzt, nicht Teil des Commits).
Ohne Co-Authored-By.

**Sub-Häppchen 11 — erledigt** (`TESTS/` Teil 2 — die restlichen 40
Spec-Dateien: `selection_spec`, `lastcmd_spec`, `keymap_modifier_spec`,
`markdown_table_spec`, `cwd_spec`, `autocmd_spec`, `spawn_env_spec`,
`harvest_spec`, `mutate_spec`, `system_job_spec`, `count_spec`,
`statusline_spec`, `neotree_watch_spec`, `frecency_spec`, `async_walk_spec`,
`logger_spec`, `polymorphic_rootresolver_spec`, `cache_spec`,
`usercmd_registry_spec`, `run.lua`, `keymap_portability_spec`,
`autocmd_docs_spec`, `normkey_spec`, `lock_spec`, `context_spec`,
`ui_list_spec`, `contextmenu_spec`, `run_spec`, `git_spec`,
`is_subpath_spec`, `bindings_audit_spec`, `dev_duplicates_spec`,
`watch_spec`, `project_store_spec`, `globbable_spec`,
`telemetry_wrap_spec`, `window_spec`, `run_argv_spec`, `wslpath_spec`,
`harness.lua`; Commit `ae11d24`, gepusht, Re-Fetch bestätigt identisch).
**Damit ist `TESTS/` komplett durch (alle 49 Dateien über Sub 10+11).**

Zähl-Diskrepanz zum Plan: der Plan-Punkt 11 schätzte „41 Dateien"
(ausgehend von „50 Dateien total, 9 in Sub 10 erledigt"). Eigener
`find TESTS -name "*.lua" | wc -l` ergab 49, nicht 50 — die Sub-10-Liste
(9 Dateien) stimmte, nur der Gesamt-Schätzwert war einen Tick zu hoch.
40 Dateien tatsächlich bearbeitet, laut eigener Zählung, nicht laut
Plan-Text.

40 Dateien gelesen (~5580 Zeilen), 1 geändert. Wie schon Sub 10: andere
Art von Durchgang als Sub 1–9 (Test-Code statt Bibliotheks-Quelltext),
angepasste Sweep-Regeln — Kommentare only, keine Test-Logik/Assertions/
Fixtures angefasst, ein gefundener echter Test-Bug wäre nur getaggt,
nicht gefixt worden.

Praktisch der gesamte Rest war bereits auf demselben ungewöhnlich hohen
Niveau wie Sub 10: kein Deutsch, keine Ad-hoc-`FIX:`/`AUDIT:`/
`SUPERSEDED:`-Marker, keine Kopf/Inline-Dopplung, keine KI-Boilerplate.

- **Direkte Fixes:**
  - `TESTS/git_spec.lua` (Kopfkommentar) — verwies auf „telemetry_spec.lua"
    als Fundstelle für den Kontext zum `M.info()`-Feld. Diese Datei wurde
    in Commit `4330924` („feat(telemetry)!: move to runtime-analysis.nvim")
    komplett gelöscht, als `lib.nvim.telemetry` nach runtime-analysis.nvim
    auszog — das „info"-Feld-Konzept, auf das verwiesen wurde, lebt jetzt
    in `runtime-analysis.telemetry`, laut lib.nvim's eigener
    `lua/lib/nvim/git/README.md`. Toten Verweis entfernt, das eigentliche
    Modul benannt, inhaltliche Begründung (warum `M.info` hier eine echte
    Assertion verdient) unverändert gelassen.
- **Echte Test-Bugs: keine gefunden.** Keine tote/unerreichbare
  Test-Logik, keine Assertion, die nie fehlschlagen kann, keine
  Fixture-Inkonsistenz — trotz gezielter Suche (u.a. `count_spec.lua`'s
  bewusst nicht zurückgesetztes `unsubscribed`-Flag ist im Kommentar
  selbst als Absicht erklärt, kein Bug).
- **`--- CDX:` gesetzt: keine** — kein Fund erreichte die Schwelle für
  einen Judgment-Call-Tag.
- **Nichts für WKDBooks ausgelagert** — keine Design-Rationale/Benchmark-
  Erzählung in diesem Scope war lang oder allgemeingültig genug, um vom
  eigenen Call-Site sinnvoll getrennt zu werden.

stylua ok, luacheck 0/0 (nur die geänderte Datei betroffen), volle
`TESTS/run.lua`-Suite `LIB_TESTS_OK` (alle 49 Specs grün). Ohne
Co-Authored-By.

**Sub-Häppchen 10 — erledigt** (`TESTS/` Teil 1 — `composer_spec`,
`deps_spec`, `ui_kit_spec`, `autocmd_dispatcher_spec`, `nvim_helpers_spec`,
`keymap_registry_spec`, `lua_helpers_spec`, `curl_spec`, `async_spec`;
Commit `d044401`, gepusht, Re-Fetch bestätigt identisch). 9 Dateien gelesen
(~6710 Zeilen), 1 geändert. Andere Art von Durchgang als Sub 1–9: Test-Code
statt Bibliotheks-Quelltext, also nach den angepassten Sweep-Regeln
behandelt — Kommentare only, keine Test-Logik/Assertions/Fixtures
angefasst, ein gefundener echter Test-Bug wäre nur getaggt, nicht gefixt
worden.

Alle neun Dateien waren bereits auf einem ungewöhnlich hohen Niveau: kein
Deutsch, keine Ad-hoc-`FIX:`/`AUDIT:`/`SUPERSEDED:`-Marker, keine
Kopf/Inline-Dopplung, keine KI-Boilerplate-Blöcke à la „Features:"/„Design
decisions:", und jeder `require(...)`-Pfad in den Kommentaren löst gegen
den echten, von Sub 1–9 bereits durchgesweepten `lua/`-Baum auf (Stichprobe:
alle in `deps_spec`/`nvim_helpers_spec` genannten Module verifiziert,
`docs/INSTALL.md`-Referenz in `deps_spec.lua` gegen `lua/lib/nvim/deps/
README.md`s eigene Konvention geprüft — korrekt, kein lib.nvim-eigener
Pfad, sondern die dokumentierte Pro-Plugin-Konvention).

- **Direkte Fixes:**
  - `TESTS/ui_kit_spec.lua` (zwei Stellen, Z. 538 und 631) — beide
    verwiesen auf „UI-KIT-CONCEPT.md §13a"/„§13b", ein Roadmap-Konzeptdokument,
    das in Commit `be9673e` („docs cleaup", 2026-08-14) gelöscht wurde,
    nachdem das Feature fertig gebaut war. Toten Abschnittsverweis entfernt,
    die inhaltliche Erklärung daneben unverändert gelassen.
- **Echte Test-Bugs: keine gefunden.** Keine tote/unerreichbare
  Test-Logik, keine Assertion, die nie fehlschlagen kann, keine
  Fixture-Inkonsistenz.
- **`--- CDX:` gesetzt: keine** — kein Fund erreichte die Schwelle für einen
  Judgment-Call-Tag; alles war entweder eindeutig richtig oder eindeutig zu
  fixen (s.o.).
- **Nichts für WKDBooks ausgelagert** — keine Design-Rationale/Benchmark-
  Erzählung in diesem Scope war lang oder allgemeingültig genug, um vom
  eigenen Call-Site sinnvoll getrennt zu werden.
- Zwei weitere, gleichartige tote `UI-KIT-CONCEPT.md §13b`-Verweise
  gefunden, aber außerhalb dieses Scopes (in bereits von Sub 6/9
  durchgesweepten `lua/lib/nvim/ui/kit/@types/init.lua` und
  `lua/lib/nvim/ui/kit/select.lua`) — als separater Background-Task
  geflaggt statt hier mitgefixt, da nicht Teil des TESTS/-Auftrags.

stylua ok, luacheck 0/0 (nur die geänderte Datei betroffen), volle
`TESTS/run.lua`-Suite `LIB_TESTS_OK`. Ohne Co-Authored-By.

**Sub-Häppchen 9 — erledigt** (`lua/lib/nvim/{normalize,safe_api,treesitter,
frecency,git,debounce,async,selection,image_preview,dev,count,require,store,
contextmenu,terminal,dotrepeat,token,json}/` + das lose `lua/lib/nvim/init.lua`,
Commit `db94330`, gepusht, Re-Fetch bestätigt identisch). 44 Dateien gelesen
(~4350 Zeilen), 13 geändert. Größter Teil dieses Scopes (`safe_api/`,
`frecency/`, `git/`, `debounce/`, `async/`, `selection/`, `count/`, `token/`,
`json/`, `treesitter/guard/`) war bereits auf demselben hohen Niveau wie die
saubersten Teile aus Sub 7/8: keine Redundanz, keine Boilerplate-Header,
`@types` deckungsgleich mit der echten `M`-Tabelle — komplett unangetastet
gelassen.

- **Direkte Fixes:**
  - `normalize/@types/init.lua` — das echte `normalize/init.lua` gibt
    `---@type Lib.Normalize` zurück, aber diese Klasse deklarierte nur die
    Felder `utils`/`validators`, die es auf der echten `M`-Tabelle gar nicht
    gibt (M ist die flache Vereinigung aller Utils+Validators-Funktionen).
    Die korrekte Form lag ungenutzt unter einer separaten `Lib.Normalize.All`-
    Klasse, selbst eine wortgleiche Dopplung der Feld-Docs aus
    `normalize/@types/{utils,validators}.lua`. Gefixt durch
    `Lib.Normalize : Lib.Normalize.Utils, Lib.Normalize.Validators`
    (Mehrfachvererbung, ein an anderer Stelle im Repo bereits etabliertes
    Muster) statt der ~120-zeiligen doppelten Prosa. Zusätzlich einen
    generischen „this module defines all type annotations…"-Boilerplate-
    Header gekürzt.
  - `safe_api/@types/init.lua` — `is_valid_buffer`/`is_valid_window` waren als
    `(bufnr: integer)` typisiert, obwohl die echten Funktionen bewusst `any`
    nehmen — der Inline-Kommentar direkt daneben erklärt, warum ein
    `nil`-Handle am Call-Site kein Typfehler werden darf. Typen jetzt passend.
  - `git/@types/init.lua` — `in_git_repo` war mit Pflicht-`git_cmd: string`
    typisiert, die echte Funktion hat ihn optional. `?` ergänzt.
  - `treesitter/parser_policy/init.lua` — eine doppelte
    `---@type Lib.Treesitter.ParserPolicy`-Zeile (zweimal hintereinander vor
    `return M`) gelöscht.
  - `require/init.lua` — `M.dir` trug einen ~35-zeiligen AI-Boilerplate-
    `--[[ ]]`-Block, der die bereits vollständigen `@param`/`@return`-Docs der
    Funktion nochmal restatete, inklusive einer Behauptung („the function is
    exported directly, not wrapped in a table"), die dem umgebenden Code
    widerspricht (`M.dir` ist ein Tabellenfeld). In den Doc-Kommentar über der
    Funktion eingedampft.
  - `terminal/@types/init.lua` — `Lib.Terminal` (referenziert vom
    Top-Level-`Lib`-Facade-Feld `terminals`) und `Lib.Terminal.ALL` (was
    `terminal/init.lua` tatsächlich zurückgibt) dupliziierten dieselben drei
    Felder wortgleich, wobei `Lib.Terminal` zusätzlich `is_kitty` fehlte —
    das Facade-eigene Type wusste also nichts von einer echten, exportierten
    Funktion. Zu einer `Lib.Terminal`-Klasse mit allen vier Feldern
    zusammengeführt, `.ALL` gelöscht, Return-Annotation aktualisiert.
    Zusätzlich einen „succes"-Tippfehler/vagen Feld-Doc sowie eine
    verwaiste Nicht-Doc-Kommentarzeile (Dopplung des Feld-Docs direkt
    daneben) gefixt.
  - `store/project/init.lua` — `---@internal` steckte mitten in einem Satz
    im Doc-Kommentar von `resolve()` und zerriss ihn in zwei Blöcke. An den
    Anfang verschoben.
  - `contextmenu/@types/init.lua` + `contextmenu/init.lua` — es gab gar keine
    `Lib.ContextMenu`-Modul-Oberflächen-Klasse (nur `.Item`/`.BindOpts`), und
    `return M` trug keine `---@type`-Annotation — jedes Schwestermodul in
    diesem Scope hat beides. Fehlende Klasse ergänzt (deckt die vier echten
    Funktionen exakt ab) plus Return-Annotation.
  - `dotrepeat/init.lua` — aus demselben Konsistenzgrund die fehlende
    `---@type Lib.Dotrepeat`-Annotation auf `return M` ergänzt.
  - `image_preview/init.lua` — dieses Modul ist eine echte repo-übergreifende
    API (wird von markdown.nvim aufgerufen), trug aber noch Namensreste von
    vor der Extraktion: einen `Markdown.ImageProvider`-Type-Alias (falscher
    Namespace, sollte `Lib.*` sein) sowie einen Autocmd-Gruppennamen/-Desc,
    hartcodiert auf „MarkdownNvimImagePreview"/„[markdown.nvim]". Geprüft,
    dass markdown.nvim nur `.preview()`/`.available()` aufruft und weder den
    Alias noch den Gruppennamen direkt referenziert — beide gefahrlos
    umbenannt zu `Lib.ImagePreview.Provider` bzw.
    `lib_nvim_image_preview`/„lib.nvim.image_preview: …".
- **Keine echten Bugs gefunden.**
- **Kein toter Code gefunden** — keine verwaisten `@types`-Dateien, keine
  unreferenzierten Funktionen (der nächstliegende Kandidat, `require.lazy`,
  hat einen echten Aufrufer — siehe Tag unten).
- **`--- CDX:` gesetzt (Judgment Calls):**
  - `dev/duplicates.lua` (`M.lines`) — die gerenderte Ausgabe verwendet
    deutsche Labels („Zeilen", „Plugins", „identische Funktionskoerper…"),
    während jeder andere nutzer-sichtbare String in lib.nvim englisch ist —
    ein Rest aus dem im Modul-Header dokumentierten Python-Tool-Ursprung.
    Als Tag belassen statt direkt übersetzt, weil es angezeigten Ausgabetext
    ändert, nicht nur eine Annotation.
  - `require/init.lua` (`M.lazy`) — reimplementiert `lib.lua.lazy`s
    `LAZY.module(name).get` (Cache-on-first-access-Require) statt darauf zu
    delegieren — beide müssen jetzt von Hand im Verhalten synchron gehalten
    werden. Echter Aufrufer: `LIB.require_lazy` in
    `lib/strategies/{eager,lazy}.lua`.
- **Nichts für WKDBooks ausgelagert** — kein Header in diesem Scope trug
  generische Neovim/Lua-Mechanik oder Benchmark-Erzählung schwer genug, um
  die Auslagerungsschwelle zu reißen; die vorhandene Design-Rationale
  (frecencys Bucket-Recency-Begründung, asyncs await/run-Protokoll,
  selections gv-Vermeidungs-Begründung, treesitter/parser_policys
  Queueing-Begründung) hängt jeweils eng an ihrem eigenen Call-Site.

stylua ok, luacheck 0/0 (8 nicht-`@types`-Dateien betroffen), volle
`TESTS/run.lua`-Suite `LIB_TESTS_OK`. Ohne Co-Authored-By.

**Damit ist lib.nvims gesamter `lua/`-Quellbaum durchgesweept (Schritte 1–9,
Sub-Häppchen 1–9/9).** Nur noch `TESTS/` + `doc/` + `docs/` offen — andere
Art von Inhalt (Test-Code bzw. generierte/gepflegte Dokumentation statt
Source-Kommentare). Nachträglich in die Schritte 10–13 aufgeteilt (siehe
Plan oben und der Nachtrag dort) — die ursprüngliche Schätzung „ein Schritt"
war mit ~22.000 Z. über 118 Dateien selbst zu grob.

**Sub-Häppchen 8 — erledigt** (`lua/lib/nvim/{harvest,progress,markdown,
lastcmd,cache,net,neotree,notify}/`, Commit `6aede6d`, gepusht, Re-Fetch
bestätigt identisch). 32 Dateien gelesen (~4600 Zeilen), 5 geändert. Der
größte Teil (`harvest/`, `progress/`, `lastcmd/`, `cache/`, `neotree/`) war
bereits auf demselben hohen Niveau wie `deps/`/`logger/` in Sub 7: keine
Redundanz, keine Boilerplate-Header, jede Rationale genau an der Stelle
nützlich, an der sie steht — komplett unangetastet gelassen.

- **Direkte Fixes:**
  - `markdown/table/init.lua` — der Modul-Header trug eine vierzeilige
    „who was ahead"-Extraktionshistorie-Tabelle; zwei ihrer vier Zeilen
    (`parse_row`, `resolve_overrides`) waren wortgleich bereits von den
    Inline-Doc-Kommentaren an genau diesen Funktionen dupliziert → auf einen
    Absatz eingedampft, der auf die Funktions-Docs verweist.
  - `notify/safe/init.lua` — ein `-- FIX: Anschließenden text auf englisch
    übersetzen`-Marker gefolgt von einem ~35-zeiligen deutschen Blockkommentar
    entfernt, der nur die fünfzeilige englische Modul-Doku drei Zeilen darüber
    nochmal übersetzte und jede Funktion (schedule/defer/wrap/create_safe)
    erneut beschrieb, obwohl jede bereits vollständig eigene `@param`-Doku
    trägt. Zusätzlich das fehlende `require("lib.nvim.notify.@types")`
    ergänzt (jedes Schwestermodul in diesem Scope macht das, hier fehlte es).
- **`@types`-Fixes:**
  - `net/curl/@types/init.lua` — `Lib.Net.Curl` fehlten `config_quote` und
    `is_secret_header`, beides öffentliche Funktionen (`M.config_quote`,
    `M.is_secret_header`) mit eigener Doku in `curl/init.lua`, nie zur
    Aggregat-Klasse hinzugefügt. Ergänzt.
  - `notify/@types/init.lua` — `Lib.Notify` trug ein `resolve_log_level`-Feld,
    das es auf der echten `M`-Tabelle gar nicht gibt: jeder reale Aufrufer
    (`logger/init.lua`, `strategies/eager.lua`, `strategies/lazy.lua`)
    requiret `lib.nvim.notify.resolve_log_level` direkt über den eigenen
    Pfad, nie über das Notify-Aggregat — Phantom-Feld entfernt.
  - `notify/@types/safe.lua` — wurde von nichts im Repo requiret (ganzes Repo
    gegrept) und deklarierte, in deutlich AI-Boilerplate-lastigerer Prosa,
    exakt dieselbe `Lib.Notify.Safe`-Klasse, die `notify/@types/init.lua`
    bereits trug. Zwei Typen darin waren aber einzigartig und real referenziert
    (`Lib.Notify.Safe.Notifier`, `Lib.Notify.Safe.ScheduleMode`) → beide,
    von der Prosa befreit, nach `notify/@types/init.lua` migriert, die jetzt
    vollständig doppelte Waisen-Datei gelöscht (gleiches Muster wie die
    verwaiste `@types`-Datei in Sub 5).
- **Keine echten Bugs gefunden.** Kein toter Laufzeit-Code gefunden — die
  einzige Löschung war die oben genannte, bereits vollständig duplizierte
  `@types`-Datei.
- **Nichts für WKDBooks ausgelagert** — der einzige Kandidat
  (`markdown/table`s Extraktionshistorie-Tabelle) erwies sich beim genaueren
  Hinsehen als größtenteils bereits inline dupliziert statt genuin
  einzigartiger Design-Rationale, deshalb vor Ort eingedampft statt
  ausgelagert.

stylua ok, luacheck 0/0 (2 nicht-`@types`-Dateien betroffen: `markdown/
table/init.lua`, `notify/safe/init.lua`), volle `TESTS/run.lua`-Suite
`LIB_TESTS_OK`. Ohne Co-Authored-By.

**Sub-Häppchen 7 — erledigt** (`lua/lib/nvim/{deps,logger,system,health,
lua_ls,core}/`, Commit `21c871a`, gepusht, Re-Fetch bestätigt identisch).
34 Dateien gelesen (~4540 Zeilen), nur 4 geändert. Größtenteils
außergewöhnlich sauber — `deps/` (11 Dateien, größter Teilbaum hier),
`logger/` (8 Dateien) und der Großteil von `system/` (env/info/job/
proc_trace) waren bereits auf einem Doku-Niveau, das nichts zu tun übrig
ließ: keine Redundanz, keine Boilerplate-Header, jede Rationale genau an der
Stelle nützlich, an der sie steht.

- **Direkte Fixes:**
  - `core/simple_echo.lua` — ein zweivariantiges „USAGE:"-Beispielblock
    (`require(...)` einmal direkt aufgerufen, einmal in eine Variable
    gespeichert) wiederholte nur generische require-dann-call-Mechanik ohne
    modulspezifischen Mehrwert → gestrichen; ein Inline-Kommentar
    duplizierte zusätzlich wortgleich die „preallocates a single-element
    chunks array"-Zeile aus dem Header → gelöscht.
  - `system/rpc_pipe.lua` — ein Emoji-Kommentar (`-- ✅ Default: true`)
    entfernt (Wert bereits in der `@param`-Doku zwei Zeilen darüber
    dokumentiert); zwei Kommentare gelöscht, die nur die exakt folgende
    Bedingung nochmal in Prosa wiederholten; ein reißerischer
    „CRITICAL:"-Kommentar auf normalen Ton zurückgestuft.
- **`@types`-Fix:** `deps/status.lua` — `M.collect()`s Rückgabe-Annotation
  war eine anonyme Inline-Tabelle (`{ tools: ..., sources: ..., plugins:
  ..., failed: ... }`), obwohl `deps/@types/init.lua` bereits exakt diese
  Form als `Lib.Deps.Status.Collected`-Klasse deklariert — auf den
  benannten Typ umgestellt, damit beide Deklarationen nicht länger
  unabhängig synchron gehalten werden müssen.
- **`--- CDX:` gesetzt (Judgment Calls):**
  - `lua_ls/@types/init.lua` — `Lib.LuaLS` dokumentiert ein
    `require("lib.nvim.lua_ls")`-Aggregatmodul mit den Feldern
    `get_module_path`/`insert_module_annotation`, das es zur Laufzeit gar
    nicht gibt (kein `lua_ls/init.lua` — die echten Einstiegspunkte sind
    `lib.nvim.lua_ls.get_module_path` und
    `lib.nvim.lua_ls.insert.module_annnotation`, je über eigenen
    Require-Pfad). Gleiches wiederkehrende Muster wie in Sub 4/5/6 —
    belassen, nicht gelöscht.
  - `system/rpc_pipe.lua` — erkennt Windows über
    `package.config:sub(1, 1) == "\\"` statt wie das Schwestermodul
    `system/env.lua` `lib.nvim.cross.platform.is_windows` zu nutzen, obwohl
    `env.lua`s eigener Header genau das als Grund nennt ("so detection
    logic lives in exactly one place"). Kein Bug, aber eine Inkonsistenz,
    die es wert ist, dass jemand sie sich nochmal ansieht.
- **Zusätzlich gelöscht (kein separater `@types`-Bug, sondern verwaiste
  Typen ohne jeden Verweis):** `lua_ls/@types/init.lua` —
  `Lib.LuaLS.GetModulePath` und `Lib.LuaLS.InsertModuleAnnotation`, zwei
  `__call`-Wrapper-Klassen, die nirgendwo im Repo referenziert werden (auch
  nicht per `---@type` in den Modulen, die sie eigentlich beschreiben
  sollten) und 1:1 redundant zu den bereits inline auf `Lib.LuaLS`
  stehenden `fun(...)`-Signaturen waren.
- **Keine echten Bugs gefunden.** Kein toter Laufzeit-Code gefunden — `deps/`,
  `logger/`, `system/`, `health/` sind durchweg real referenzierte,
  aktive Aggregatmodule; das einzige Phantom-Muster in diesem Scope betrifft
  ausschließlich die oben getaggten `@types`-Klassen.
- **Nichts für WKDBooks ausgelagert** — kein Header in diesem Scope trug
  generische Neovim/Lua-Mechanik oder Benchmark-Zahlen schwer genug, um die
  Auslagerungsschwelle zu reißen.

stylua ok, luacheck 0/0 (3 nicht-`@types`-Dateien betroffen: `core/
simple_echo.lua`, `deps/status.lua`, `system/rpc_pipe.lua`), volle
`TESTS/run.lua`-Suite `LIB_TESTS_OK` (inkl. `deps_spec.lua`, `logger_spec.lua`,
`system_job_spec.lua`, die Module aus diesem Scope direkt testen). Ohne
Co-Authored-By.

**Sub-Häppchen 6 — erledigt** (`lua/lib/nvim/ui/`, Commit `01ba23a`, gepusht,
Re-Fetch bestätigt identisch). 29 Dateien gelesen (~4469 Zeilen), 2 geändert
(nur `@types`-Dateien). Ungewöhnlich sauberer Teilbaum — `ui/kit/` (das
Floating-Window/UI-Widget-Toolkit: Chooser, Prompts, Confirm, Compare,
Layout, Theme, …) war praktisch fehlerfrei, keine Boilerplate-Header, keine
alten Marker, keine falsche Sprache.

- **`@types`-Fix:** `ui/kit/@types/init.lua` — `Lib.UI.Kit.ThemeModule` fehlte
  das Feld `default` (theme.lua exportiert `M.default()`, den Namen des
  aktiven Presets); Klasse hatte nur resolve/apply/materialize/border_glyphs/
  setup/presets dokumentiert. Ergänzt.
- **`--- CDX:` gesetzt (Judgment Call):** `ui/@types/init.lua` — `Lib.UI`
  dokumentiert ein `require("lib.nvim.ui")`-Aggregatmodul, das es zur
  Laufzeit gar nicht gibt (kein `ui/init.lua`; `hl/`, `kit/`, `list/`,
  `nerd_font/`, `statusline/` sind eigenständige Leaf-Module über ihren
  eigenen Require-Pfad). Zusätzlich selbst als Phantom unvollständig — die
  Felder `statusline` und `nerd_font` fehlen ganz. Gleiches wiederkehrende
  Muster wie in Sub 4 (`lib/@types/init.lua`) und Sub 5
  (`buf_win_tab`/`buffer` `@types`) — belassen bis ein externer-Consumer-Check
  klärt, ob je implementiert.
- **Keine echten Bugs, kein toter Code.** `kit/@types/init.lua`s
  `Lib.UI.Kit`-Klasse passt sonst exakt zu `kit/init.lua`s echtem `M`-Table.
- **Nichts für WKDBooks:** Die Modul-Doku in diesem Scope (z. B. `list/init.lua`s
  Stack/Titel/Fokus/Leerfall-Rationale, `nerd_font/init.lua`s
  Font-Erkennungs-Begründung, `kit/compare.lua`s SEARCH/MARKED/COMPARE-
  Zustandsautomat-Doku) hängt jeweils eng am konkreten API-Vertrag, den sie
  beschreibt — kein generisches Tutorial, kein AI-Boilerplate-Block. Bleibt
  im Code.

stylua ok, luacheck 0/0 (24 nicht-`@types`-Dateien geprüft, sauber auch über
den gesamten `ui/`-Scope hinweg), volle `TESTS/run.lua`-Suite `LIB_TESTS_OK`
(inkl. `ui_kit_spec.lua`/`ui_list_spec.lua`/`statusline_spec.lua`, die Module
aus diesem Scope direkt testen). Ohne Co-Authored-By.

**Sub-Häppchen 5 — erledigt** (`lua/lib/nvim/buf_win_tab/` + `window/` +
`buffer/`, Commit `81a8f81`, gepusht, Re-Fetch bestätigt identisch). 46
Dateien gelesen (~3955 Zeilen), 9 geändert. `window/` und die
Leaf-Module unter `buf_win_tab/`/`buffer/` (get_option, move_buffer_to_tab,
normal_buffer, safe_adjacent_buffer, selection, word_under_cursor,
context-Module) waren bereits sauber — die Arbeit steckt wie in Sub 3/4 fast
nur in den alten AI-Boilerplate-`@types`-Headern von `buf_win_tab`.

- **Direkte Fixes:** `buf_win_tab/windows_utils.lua` — kontextloser
  „---FIX: LSP"-Marker → als `--- CDX:` markiert statt stillschweigend zu
  löschen (unklar, was er meinte). `buffer/get_alternate.lua` — veralteter
  deutscher Marker „AUDIT: Implementiere in lib" gelöscht (die Funktion liegt
  bereits in lib.nvim, der Audit-Auftrag ist erledigt). `buffer/@types/init.lua`
  — ein `return {}` stand mitten in der Datei (vor den
  `Lib.Buf.InsertLinesPos*`-Klassen) → ans Dateiende verschoben.
- **Boilerplate gekürzt:** `buf_win_tab/@types/{init,buffer_utils,tabs_utils,
  windows_utils}.lua` sowie `buf_win_tab/resize_guarded/@types/init.lua` —
  „Design principles"/„Performance notes"/„Technical Notes"-Blöcke, die nur
  die Feld-Docs direkt darüber wiederholten; bei `resize_guarded/@types` zudem
  ein komplettes „Usage Example", das 1:1 im echten `resize_guarded/init.lua`
  steht.
- **Toter Code gelöscht:** `buf_win_tab/@types/resize_guarded.lua` — verwaiste
  Dublette von `buf_win_tab/resize_guarded/@types/init.lua` aus der Zeit vor
  dem Umzug von `resize_guarded.lua` in ein eigenes Unterverzeichnis; beide
  definierten exakt dieselbe `Lib.BufWinTab.ResizeGuarded`-Klasse ohne
  Unterschied.
- **`--- CDX:` gesetzt (Judgment Calls):** `buf_win_tab/@types/init.lua`
  (`Lib.BufWinTab`/`Lib.BufWinTab.All`) und `buffer/@types/init.lua`
  (`Lib.Buffer`/`Lib.Buffer.ALL`) dokumentieren je ein
  `require("lib.nvim.buf_win_tab")`/`require("lib.nvim.buffer")`-Aggregat­modul,
  das es zur Laufzeit gar nicht gibt (kein `buf_win_tab/init.lua`, kein
  `buffer/init.lua` — beide Verzeichnisse bestehen nur aus Einzelmodulen, die
  über ihren eigenen Require-Pfad genutzt werden). Gleiches Muster wie der
  bereits in Sub 4 geflaggte `Lib.Modules`-Fund in `lib/@types/init.lua` —
  belassen bis ein externer-Consumer-Check klärt, ob das je implementiert war.
- **Keine echten Bugs, kein `@types`-Drift:** anders als in Sub 3/4 keine
  Signatur-Abweichung zwischen `@types` und echtem `M`-Table gefunden (u. a.
  `Lib.Window.Context.Stats`/`Lib.Buffer.Context.Stats` gegen ihre
  `get_stats()`-Implementierung geprüft — passt exakt).
- **Nichts für WKDBooks:** keine Design-Rationale oder Mechanik-Tutorials in
  diesem Batch, die die Auslagerungs-Schwelle gerissen hätten.

stylua ok, luacheck 0/0 (2 nicht-`@types`-Dateien betroffen), volle
`TESTS/run.lua`-Suite `LIB_TESTS_OK` (inkl. `window_spec.lua`/
`context_spec.lua`, die Module aus diesem Scope direkt testen). Ohne
Co-Authored-By.

**Sub-Häppchen 4 — erledigt** (`lua/lib/nvim/fs/`, Commit `95e9be5`,
gepusht, `pull --ff-only` sauber). Größter Teilbaum (52 Dateien gelesen, 13
geändert), wieder überdurchschnittlich sauber. Kein toter Code gelöscht.

- **`@types`-Fixes:** „sucess"/„in cade of"-Tippfehler; `write.lua` fehlte
  `---@meta` (alle Schwester-`@types` haben es); Klasse hieß `Lib.FS.Write`
  statt `Lib.Fs.Write` (Casing bricht Konvention) → umbenannt + Feldverweis
  mitgezogen.
- **Changelog-Narrative in Headern gekürzt** (das Muster hier): `is_subpath`
  („an earlier version used `package.config`… returned false for every
  subpath on Windows"), `is_valid_filename` („to close a gap in
  create_entry…"), `collect_recursive` (`====`-Banner mit
  „plenary/libuv research this was born from", „used to live here as a
  private copy"), `watch` (neo-tree-Archäologie). Jeweils die echte
  Invariante / der Async-Close-Grund behalten.
- `is_readable_file` — irreführendes `-- Ensure the path is valid` (prüft nur
  Lesbarkeit) → echter Doc + Hinweis „true auch für Verzeichnis".
- `path_shorten` — `strlen`-Doc behauptete utf8-Fallback, Rumpf ist `return #s`
  → auf Bytelänge korrigiert (Breiten-Budget ist byte-basiert).

**`--- CDX:` gesetzt:**
- **`fs/ignore/list/init.lua:62` — echter Logikbug:** Pattern
  `package%.lock.json` matcht „package.lock.json", npm's Lockfile heißt aber
  `package-lock.json` → Regel feuert nie. Gemeint war `package%-lock%.json`.
- **`fs/write/async/init.lua` — Verhaltens-Bug:** hängt kein abschließendes
  Newline an, obwohl das synchrone „counterpart" `to_file` (und `append`) es
  tun; `write/batch` erbt die Lücke. Angesichts der „counterpart"-Formulierung
  wohl unbeabsichtigt.
- `fs/@types/{init,query,transform}.lua` — veraltetes Scaffolding
  (`Lib.Fs`/`Lib.Fs.ALL`/`Lib.Fs.Query`/`Lib.Fs.Transform`): es gibt kein
  `lib.nvim.fs`-Aggregatmodul, die Gruppierung path/query/transform/write ist
  fiktiv; `Lib.Fs.ALL.dedup` benennt kein Modul. Echte flache Oberfläche:
  `all_functions.lua`. Analog `Lib.Cross.ALL` (Sub 3) getaggt statt gelöscht.
  Die real referenzierten `Lib.Fs.*Opts`/`Lib.Fs.Path`-Klassen bleiben.
- `fs/polymorphic_rootresolver/@types` — `RootResolverCfg` ohne `Lib.Fs.`-
  Präfix (bricht Konvention), aber public in `docs/API/filesystem.md` →
  Rename mit Rippeleffekt, nur markiert.

**Memory-Subtlety geprüft:** `polymorphic_rootresolver` löst Root **pro
Aufruf** aus `arg` auf, cwd nur als Fallback — kein Kommentar behauptet
Gegenteiliges, nichts zu flaggen.

**Für Sub-Häppchen 8:** `docs/API/filesystem.md` — `polymorphic_rootresolver`
erwähnt `cfg.markers` aber nicht `cfg.resolve`; „28 submodules"-Zahl in Z.1
verifizieren; falls `RootResolverCfg`-Rename je kommt, Z.88 mitziehen.

**Für einen späteren WKDBooks-Pass** (Agent hat nichts committet, nur notiert —
ortsunabhängige Mechanik, die in Headern anfällt): `vim.fn.*`→`E5560` in
Fast-Event-Kontexten; Windows-8.3-Kurznamen (`STEFAN~1`) brechen
`vim.fn.glob`; `io.open` „w"/„r" ist Text-Modus (CRLF-Wandlung) vs. libuv
`fs_write` byte-exakt; `fs_event` feuert mehrfach pro Save + Handle-Close ist
async.

stylua ok, luacheck 0/0 (31 Dateien), `LIB_TESTS_OK`. Ohne Co-Authored-By.

**Sub-Häppchen 3 — erledigt** (`lua/lib/nvim/cross/`, Commit `cc21351`,
gepusht, `pull --ff-only` sauber). 29 Dateien. Bestätigt das Muster: die
Arbeit steckt fast nur in `@types` + alten AI-Boilerplate-Headern; der
Ausführungscode ist praktisch kommentar-rein.

- **`@types/init.lua` — Signaturen wichen vom Code ab:** `Lib.Cross` fehlten
  `is_windows/is_wsl/is_macos/is_linux/is/executable` komplett, veraltetes
  `clipboard`-Feld drin (existiert nicht). `Lib.Cross.Uv`: `spawn_command`
  gibt `{ spawn_project_command = … }` zurück (nicht `fun(argv)`),
  `spawn_shell_command` nimmt `(cmd, args, opts)`, `wait_until` fehlte der
  `cb`-Param. Alle korrigiert.
- `spawn_capture/@types` — `stdin?`-Feld fehlte in der `@class` (war inline da).
- `uv/spawn_command.lua` — ~30-Zeilen-`Features:`/`Design decisions:`-
  Boilerplate-Header eingedampft, `SECURITY:`-Block erhalten. `spawn_shell_command`
  „Usage example" raus.
- `fs/separators/normalize/init.lua` — falscher Assert-Modul-Tag
  `[lib.nvim.normalize.os_sep]` → korrekter Pfad.
- `run/init.lua` — `-- FIX: Optimize, doc`-Marker raus (Modul ist dokumentiert),
  Header zu echter `---`-Doc.
- `fs/expand_path` — Header nannte nur `$VAR`, Code macht auch `${VAR}`.
- `fs/_cwd`, `uv/fs` — plain `--` → `---`; `uv/fs` dokumentiert jetzt, dass es
  `fs._cwd` bewusst dupliziert.

**`--- CDX:` gesetzt:**
- `@types/init.lua` `Lib.Cross.ALL` — unreferenziert, listet `run_blocking`
  **zweimal** (zweiter Eintrag ist eigentlich `run_argv.run_blocking`,
  Copy-Paste), abgelöst durch `Lib` in `all_functions.lua`.
- `@types/clipboard.lua` `Lib.Cross.Clipboard` — unreferenziert, es gibt keine
  `cross.clipboard`-Tabelle (Modul ist `cross.copy_to_clipboard`, nackte Fn).
- `fs/separators/normalize/init.lua:14` — eigene Windows-Erkennung statt
  `cross.platform.is_windows`, prüft `os_uname().version` statt `sysname` —
  inkonsistent mit dem Rest von `cross/`.

Keine echten Logik-Bugs (Spawn/Retry/Timeout-Pfade sind sorgfältig).

**Für Sub-Häppchen 8:**
- `run/init.lua` `run_detached`-Doc und `reveal_in_fm/init.lua`
  `spawn_helper`-Doc enthalten denselben ~10-Zeilen-Text zu libuv
  `DETACHED_PROCESS` / Konsole-vs-GUI (load-bearing Windows-Wissen, aber über
  2 Dateien dupliziert) → in ein Docs-File auslagern + Pointer.
- `docs/API/cross-platform.md` unvollständig: `fs.mutate` fehlen `symlink`/
  `hardlink`; `run.env` fehlt `M.array(vars?)`.

stylua ok, luacheck 0/0 (29 Dateien), `LIB_TESTS_OK`. Ohne Co-Authored-By.

**Sub-Häppchen 2 — erledigt** (`lua/lib/nvim/bindings/`, Commit `1dd5f36`,
gepusht, `pull --ff-only` sauber). 28 Dateien, überdurchschnittlich sauber.

- **`@types`-Enumerationen unvollständig** (das Kernmuster hier): `Lib.AutoCmd`
  fehlten `registered`/`by_event`/`docs`; `Lib.UserCmd.Composer.Handle` fehlten
  die Fluent-Builder-Methoden `:count`/`:buffer`; `DocsOpts`/argtype-Alias
  hatten doppelte Beschreibungszeilen. → alle gegen die reale `M`-Tabelle
  abgeglichen. **Für die restlichen lib.nvim-Sub-Häppchen: jede `Lib.*`-
  `@class` gegen das Modul-`M` prüfen.**
- **`====`-Banner-Header** in `autocmd/init.lua`, `keymap/set.lua` → `---@module`;
  `autocmd/augroup.lua` hat noch einen (trivial, fürs Aufräum-Häppchen).
- Fehlplatzierte Rationale-Blöcke in `autocmd/init.lua` an die richtige
  Funktion (`M.group`/`M.get_augroup`) verschoben; doppelter aus `augroup.lua`
  kopierter Block ersetzt.
- `autocmd/dispatcher/init.lua` — Inline-Mikrobenchmark-Zahlen (`~30us` etc. +
  Pfad zum Bench-Skript) → auf die Schlussfolgerung + README-Verweis eingedampft.
- Toter auskommentierter `---@param`-Block in `keymap/set.lua` gelöscht.
- Stale Changelog-Notizen in Kommentaren: „`WINDOW` … missing from this list"
  (steht drin), „pre-Phase-6 behavior" → entfernt.
- **Struktur:** Inline-`---@class Lib.UserCmd.Composer.Node` aus `tree.lua`
  nach `composer/@types/` verschoben (Konvention `conventions.md`).

**`--- CDX:` gesetzt:**
- `keymap/modifier/init.lua` `capture()` — konsultiert nur Tier-1-
  Deklarationen unter Modus `"n"`, obwohl `M.declare(mode, …)` beliebige Modi
  annimmt und speichert. Ganzes Feature ist normal-mode-only (`resolve_target`/
  `setup` hardcoden `"n"`), also matcht `declare("i"/"x", …)` still nie —
  latenter Bug / toter Parameter.

**Nicht angefasst:** `format.lua` `arg_token` (redundanter `if/else`-Zweig,
identisches Ergebnis — Code-Logik, kein Kommentar); `docgen.lua` `cell()`
dupliziert `docs_util.cell` (Konsolidierung = neue Cross-Modul-Abhängigkeit);
`dispatcher/init.lua` closure-lokale `Registration`-Klasse (Verschieben zu
riskant für Kommentar-Sweep).

**Für Sub-Häppchen 8:** `doc/lib.nvim-composer.txt` nutzt in USAGE
`require("replacer").prompt()`, `composer/init.lua`-Doc nutzt
`.replace_prompt()` — beide fiktiv, aber inkonsistent; angleichen.

Kein Deutsch, kein toter Code, keine Smart Quotes, keine `require`-Pfad-Bugs,
keine `X and CONST or CONST`-Ternaries in diesem Scope.

stylua ok, luacheck 0/0 (28 Dateien), `LIB_TESTS_OK`. Ohne Co-Authored-By.

**Sub-Häppchen 1 — erledigt** (Commit `524ec4d`, gepusht, `pull --ff-only`
sauber). Teilbaum war **überdurchschnittlich sauber** — kaum Deutsch, keine
Smart Quotes, konsistenter House-Style. Funde konzentriert auf:

**Direkte Fixes:**
- `lua/lib/lua/time/diff/init.lua` + `@types/init.lua` — **Doc widersprach
  Code:** Header/USAGE/@types behaupteten `require("lib.lua.time.diff")`
  liefere eine Instanz (`diff.start()`); das Modul ist eine **Factory**,
  korrekt ist `require(...)()`. An 4 Stellen gefixt. „Technical Notes"-Wall
  (Benchmark, Umrechnungstabelle, Limitations-Listen — alles im README
  dupliziert) getrimmt.
- `lua/lib/lua/memo/memo.lua` — toter auskommentierter `---@field memoize2`;
  copy-paste-falscher `memoize2`-Docstring korrigiert; `@types` fehlte das
  (dokumentierte) `memoize2`-Feld → ergänzt.
- `lua/lib/lua/lazy/init.lua` — Boilerplate-Header + „Design goals"-Wall auf
  Param-Liste; `LAZY.require`-USAGE zeigte ein nicht existierendes 2. Argument.
- `lua/lib/@types/all_functions.lua` — „corrent" → „current" (4×), verirrtes
  `-` in Feldsignatur, kaputter Satz neu formuliert.
- `lua/lib/health.lua` — doppelter `PROBE`-Eintrag `"lib.nvim.ui.kit"`; falscher
  Kommentar „one representative module per namespace" (Liste hat immer mehrere).
- `lua/lib/lua/json/decode/to_string_array.lua` — veralteter Header (Code
  existiert nicht) neu geschrieben.
- `lua/lib/lua/memo/lru.lua` — eine deutsche Zeile → Englisch.
- `lua/lib/nvim_usrcmds/{@types,actions}.lua` — stale `@see`-Referenz;
  `-- FIX:` → `--- CDX:`.

**`--- CDX:` gesetzt:**
- `lua/lib/lua/strings/init.lua` — **echter Logikbug:** `M.normalize_ws =
  require("lib.lua.strings.links").normalize_ws` → `links` hat keine solche
  Funktion, Ausdruck ist `nil` und überschreibt das direkt darüber korrekt
  zugewiesene `core.normalize_ws`. Typ ist deklariert, Laufzeit ≠ Typ.
- `lua/lib/lua/lazy/init.lua` — `LAZY.typed` byte-gleich zu `LAZY.require`,
  keine Caller, undokumentiert. Löschkandidat, aber geteilte Dependency → getaggt.
- `lua/lib/@types/init.lua:7` — `Lib.Modules` ohne `---@type`-Referent,
  abgedriftet, vermutlich durch `Lib` (in `all_functions.lua`) abgelöst.
- **3× `vim`-Leck in `lib.lua.*`** (`memo/memo.lua` `vim.inspect`,
  `json/decode/to_string_array.lua` `vim.split`, `time/diff/init.lua`
  `vim.uv.hrtime`) — `architecture.md` sagt `lib.lua.*` sei editor-unabhängig;
  Schwestermodule vermeiden es. Ein Ausgliedern in ein eigenes `lib.lua`-Repo
  (in `architecture.md` als Ziel) würde daran scheitern.

**Für das Docs-Sub-Häppchen (8) vorgemerkt — dieselben Fehler in READMEs:**
- `lua/lib/lua/time/diff/README.md` — `require("lib.lua.time.diff")` →
  `require("lib.lua.time.diff")()`.
- `lua/lib/lua/lazy/README.md` — „Every call to require(...) creates an
  independent timer instance" ist ein Textbaustein-Fehler (falsches Modul).

**Bewusst nicht angefasst:** `@types/luassert.lua` (langer, aber konkret-
technischer Essay), `strategies/{control,telemetry_wrap}.lua` (tragende
„why this exists"-Docs), `nvim_usrcmds/autocmds.lua` (Rationale eng am Code),
`lua/diff/myers.lua` (Modulname vs. DP-LCS-Inhalt — selbst dokumentiert).

stylua ok, luacheck 0/0 (349 Dateien), `LIB_TESTS_OK`. Ohne Co-Authored-By.

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
