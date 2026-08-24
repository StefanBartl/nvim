# Sweep-Ledger

Arbeitsliste fuer den Plugin-Sweep. Erzeugt 2026-08-24 aus
`RULES-audit-completion.md` `[C]`, `RULES-audit-count.md` `[N]`,
`RULES-flags-options.md` `[F]`. Quelle des Audits: 2026-08-08.

`RULES-plugin-ideas.md` ist **nicht** eingeflossen und bleibt liegen.
`learn-cli.nvim` ist per Entscheidung ausgelassen.

**Benutzung:** eine Session pro Plugin. Nur den eigenen Block lesen, nicht die
`RULES-*.md`. Vorgehen, Doku-Pflichten und Definition of Done stehen in
[SWEEP-PLAN.md](SWEEP-PLAN.md).

Marker: `[C]` Completion — `[N]` Count — `[F]` Flags/Optionen
— `[?]` unverifiziert, zuerst pruefen — `[L]` lib.nvim betroffen
— `[QF]` Kandidat fuer den Quickfix-Audit (Phase 3, nicht jetzt)

---

## Phase 1 — lib.nvim-Blocker (vor dem Sweep) — ERLEDIGT 2026-08-24

Commit `eb99db1` auf Branch `feat/count-helpers` in `C:/repos/lib.nvim`.

- [x] `[L]` `lib.nvim.autocmd.create` reicht `buffer` durch — **war schon
      gefixt** (Commit `53050ff`, 2026-07-26). Der Audit vom 2026-08-08 ist an
      dieser Stelle veraltet. pickers.nvim' Workaround ist beim Umbau auf
      `result_count` (Polling statt Autocmd) ebenfalls verschwunden. Offen
      bleiben drei Rueckbauten: github_stats.nvim, color_my_ascii.nvim,
      markdown.nvim — stehen in deren Bloecken.
- [x] `[L]` `PATH`/`DIR`/`FILE`/`BUFFER`-Completion-Typen — **existierten
      bereits** in `composer/argtypes.lua`. Neu ergaenzt: `WINDOW` (spiegelt
      `BUFFER`, ohne Namens-Fallback) fuer debugging.nvims
      `:Debug report win <id>`. Die uebrigen Abnehmer benutzen die
      vorhandenen Typen einfach.
- [x] `[L]` `lib.nvim.count.chain` — aus dap.nvims `counted_step()`
      generalisiert.
- [x] `[L]` Count-Konvention — als `lib.nvim.count` (`get`/`raw`/`given`/
      `clamp`/`times`) umgesetzt statt als blosse Textregel, gemeinsam mit
      `chain` in einem Modul.

**Fuer den Sweep heisst das:** Count-Nachruestungen gehen ueber
`require("lib.nvim.count")`, nicht ueber handgeschriebenes `vim.v.count1`.
Details in `C:/repos/lib.nvim/lua/lib/nvim/count/README.md`.

## lib.nvim-Zuwachs (laufend fuehren)

Was der Sweep neu in die Lib gehoben hat, damit spaetere Plugins es
wiederverwenden statt neu zu bauen.

| Modul / Funktion | Aus welchem Plugin | Datum |
| ---------------- | ------------------ | ----- |
| `lib.nvim.count` (`get`/`raw`/`given`/`clamp`/`times`/`chain`) | `chain` aus dap.nvim `counted_step()`, Rest neu | 2026-08-24 |
| composer-Argtyp `WINDOW` | fuer debugging.nvim | 2026-08-24 |

---

## Welle A — Einzelposten

### gopath.nvim (Pilot) — ERLEDIGT 2026-08-24

- [x] `[C]` `[?]` `:Gopath cache add-root <dir>` — **kein Gap.** Die
      composer-Route deklariert bereits `type = "DIR"`
      (`bindings/usrcmds.lua:167-174`), der Alias `:GopathCacheAddRoot` setzt
      `complete = "dir"`. Zur Laufzeit gegengeprueft: beide completen
      Verzeichnisse. Keine Codeaenderung; die Luecke war rein dokumentarisch
      und ist in `docs/BINDINGS.md`, `docs/FEATURES/CACHE.md` und im zentralen
      Usercmds-Cheatsheet nachgetragen.

**Rezept-Erkenntnis fuer die naechsten Plugins:** `[?]`-Punkte zuerst und mit
einem echten `getcompletion()`-Lauf pruefen, nicht nur per Codelesen. Loest
sich der Punkt auf, bleibt trotzdem Doku-Arbeit uebrig — "unverifiziert" im
Audit heisst meistens "nirgends aufgeschrieben".

### runtime-analysis.nvim — ERLEDIGT 2026-08-24

- [x] `[C]` `:RA provenance <path>` — neuer composer-Argtyp
      `RA_PROVENANCE_PATH`, spiegelt `provenance.resolve_container`s
      Container/Field-Split. Bietet Funktions- **und** Tabellenfelder an, weil
      eine Tabelle der Weg zu einer Funktion ist.
      **Entscheidende Einschraenkung:** die Completion ruft nie `require` auf.
      Sonst wuerde ein Tab-Druck Module laden (Top-Level-Code, Autocmds) als
      Nebenwirkung. Gelesen wird nur der `_G`-Walk und `package.loaded`.
      Im Test abgesichert: `package.loaded` bleibt ueber einen
      Completion-Durchlauf unveraendert.
      Validierung bleibt bewusst weich — `inspect` liefert vier praezise
      Fehlermeldungen, die eine composer-Validierung ersetzen wuerde.
      Commit `2adf867`, Branch `feat/provenance-completion`.

### insights.nvim — ERLEDIGT 2026-08-24

- [x] `[F]` `symbols_telescope` / `symbols_fzf` nehmen jetzt entweder einen
      lhs-String (wie bisher) oder `{ lhs, scope?, type?, rebuild? }`.
      Bewusst **kein** `ui`-Feld — die UI ist, welcher der beiden Keys es ist.
      Unbekannter scope/type wird gemeldet und der Default genommen.
      **Der Befund war groesser als der Audit-Eintrag:** die Keymaps haben gar
      nicht ueber `handle_symbols` dispatcht, sondern selbst gescannt und den
      Picker geoeffnet — und dabei die Leer-Pruefung und `rebuild` verloren.
      Dispatch liegt jetzt in `symbols/open.lua`, beide Pfade gehen dort
      durch. Die Token-Listen (scope/type/ui) sind mit umgezogen, weil sie
      Completion **und** Keymap-Validierung speisen. `open_symbol_picker` und
      `default_ui` in `usrcmds.lua` waren danach tot und sind entfernt.
      Sichtbare Aenderungen: Picker-Titel aus einem Keymap nennt jetzt auch
      den Typ; `desc` spiegelt die aufgeloeste Wahl — relevant fuer
      `:Bindings check`, das seit `12611cf6` auf desc matcht.
      Commit `b352939`, Branch `feat/symbols-keymap-options`.
      Hinweis: insights.nvim hat keine Testsuite — verifiziert wurde zur
      Laufzeit (alle normalize_keymap-Formen, beide Mappings, Completion).

### open.nvim

- [ ] `[F]` Kurz-Keymaps fuer `:Open split` und `:Open terminal`, analog zu den
      bestehenden `browser`/`filemanager`-Shortcuts.

### dap.nvim

- [ ] `[F]` Breakpoint-Condition / Logpoint-Message lassen sich nicht
      wiederverwenden oder editieren — der Prompt startet immer leer.
- [ ] `[L]` `counted_step()` nach lib.nvim heben (siehe Phase 1), danach hier
      auf die Lib-Variante umstellen.

### diff.nvim

- [ ] `[F]` Kein Default-Keymap fuer "diff gegen letzten Commit"
      (`:Diff target=git:HEAD`) und den Merge-Conflict-Fall
      (`base=git:HEAD target=git:MERGE_HEAD`). Nur als **opt-in** anbieten —
      das Plugin verzichtet bewusst auf aufgezwungene Leader-Mappings.
- [ ] `[F]` Kein Keymap-Aequivalent fuer `:DiffBuffers` / `:DiffOrig` /
      `:DiffClear`. Mindestens `:DiffOrig` ist haeufig genug fuer ein
      optionales Mapping.
- [ ] `[F]` Keine `<C-c>`-Alternative zu `<Esc><Esc>` bei `scope="global"`,
      fuer Kollisionsfaelle.

### cmdlog.nvim

- [ ] `[F]` Kein Multi-Select / Batch-Delete fuer History-Eintraege — nur
      Einzelloeschung via `<C-x>`.
- [ ] `[F]` `risky_patterns` zeigt nicht, welches Pattern gematcht hat.
      `:Cmdlog risky test <cmd>` wuerde das Tunen ermoeglichen.
- [ ] `[F]` Shell-History-Parser (zsh/fish/bash) sind hardcoded — kein
      Escape-Hatch fuer exotische Formate (z. B. eigenes `HISTTIMEFORMAT`).

### sessions.nvim

- [ ] `[F]` Kein Keymap fuer `:Session current` und fuer den Picker
      (`:SessionLoad`).
- [ ] `[F]` `:Session delete` / `rename` ohne Keymap-Option. Vermutlich
      Absicht (destruktiv, selten) — pruefen und ggf. als "n/a" abhaken.

### pdfport.nvim

- [ ] `[F]` `:PdfPort float` / `terminal` fragen die Page-Range interaktiv ab;
      ein `pages=`-kv-Flag wuerde Scripting ermoeglichen.
- [ ] `[F]` `[?]` Batch-Open (`<leader>pb`): Fortschritt/Summary (X von Y
      geoeffnet, Z Fehler) — unverifiziert, ob `batch.lua` das schon liefert.

### recommender.nvim

- [ ] `[N]` Kein Keymap liest count. Vorschlag: `N<leader>lr` setzt den
      Threshold auf N, statt des hardcodierten `<leader>lrh` (Threshold 5).
- [ ] `[F]` Kein `--threshold=N`-Flag. Aktuell eine mehrdeutige Fallback-Kette
      (`tonumber(pos_args[2]) or tonumber(pos_args[1])`).

### migrate.nvim

- [ ] `[C]` `[?]` `[%|cwd]`-Literale ohne `complete`. Moeglicherweise liefert
      `lib.nvim.usercmd.composer` das schon — zuerst dort nachsehen.
- [ ] `[F]` Kein Dry-Run / "nur Preview" fuer den Single-Line-Fall.
- [ ] `[N]` `[F]` Kein count "die naechsten N Zeilen migrieren", obwohl die
      zugrundeliegenden Kommandos range-faehig sind.

### color_my_ascii.nvim

- [ ] `[C]` `[?]` `Fence lang <language>` / `Fence import <file>` — haben die
      Wert-/Datei-Completion? Registrierung liegt in einer beim Audit nicht
      gelesenen Datei.
- [ ] `[F]` `:ColorMyAscii toggle` koennte `!`-Bang oder Range akzeptieren, um
      mehrere Buffer zu togglen — derzeit nur der aktuelle.
- [ ] `[F]` `fence_export` (`:Fence export [path] [--open] [--replace]`) hat
      als einziges `Fence`-Subkommando kein Gegenstueck in der ACTIONS-Tabelle.
- [ ] `[L]` Buffer-lokaler-Autocmd-Workaround zurueckbauen (nach Phase 1).

### debugging.nvim

- [ ] `[C]` `:Debug report win <id>` und `:Debug inspect buffer|window <id>`
      completen die ID nicht (`bindings/usercmds.lua:78-84`) — Liste offener
      Window-/Buffer-IDs anbieten.
- [ ] `[C]` `:Debug keylogger start [path]` ohne Pfad-Completion — `PATH`-Typ
      aus Phase 1.
- [ ] `[F]` `<lt>c` (Messages capturen) kann file-only / clipboard-only nicht
      aus dem Keymap heraus waehlen — nur via `:Debug messages capture` mit
      Lua-API-Aufruf.

---

## Welle B — Mittlere Plugins

### buffer-ctx.nvim

- [ ] `[N]` `<S-m>` (Mark togglen) ignoriert count — "N Zeilen ab Cursor
      markieren".
- [ ] `[F]` `:Mark toggle` ohne Range-Modus (visuelle Selektion → alle
      abgedeckten Zeilen markieren). Ueberschneidet sich mit dem Count-Punkt —
      gemeinsam entwerfen.
- [ ] `[F]` `mark.sign` erlaubt nur ein globales Sign/Highlight;
      Mark-Kategorien (rot/gruen/gelb) fehlen vollstaendig.
- [ ] `[F]` Kein `:Mark clear`, um alle Marks eines Buffers zu leeren.

### cascade.nvim

- [ ] `[N]` Cycle (`<C-y>`/`<C-x>`), Line-Move (`<A-Up>`/`<A-Down>`) und
      Quick-Toggle (`<A-->` etc.) im Normal-Mode ohne count — inkonsistent zum
      sehr bewussten Count-Design bei Indent/Dedent. Besonders lohnend:
      Date-Cycling (`3<C-y>` = "+3 Tage").
- [ ] `[F]` `cycle.groups` / `per_filetype` sind rein statisch aus der Config;
      kein Live-Kommando (z. B. `:Cascade cycle add {a},{b}`), obwohl das
      Plugin sonst viel ueber `:Cascade` exponiert.

### emojis.nvim

- [ ] `[N]` `[F]` `:Emojis next` ohne count (`nav.lua:72-79` springt immer 1).
- [ ] `[N]` `<leader>et`-Count-Semantik (count > 1 erweitert den Scope auf die
      naechsten N Zeilen) steht nur im Code-Kommentar, nicht in `BINDINGS.md`.
      Reine Doku-Luecke.
- [ ] `[F]` Overlay-Grid ohne type-to-filter (nur der `list`-Modus hat das via
      Kit-Chooser).
- [ ] `[F]` `checkbox.toggle` mit `dir = -1` existiert in `core/checkbox.lua`
      und `actions.checkbox`, ist aber nur ueber die Lua-API erreichbar — kein
      `:Emojis toggle`-Argument, kein Preset-Keymap.
- [ ] `[F]` `search.no_ignore` / Extra-Globs nur via
      `:Emojis <action> cwd <glob>...`; ein `!`-Bang (`:Emojis! clear cwd`)
      waere idiomatischer.

### fileops.nvim

- [ ] `[F]` Keine Keymaps fuer `bulk rename`, `lockinfo`, `info`, `path`, `cd`
      — nur `:File …`. Vorschlag: optionales `lhs`-Config-Feld fuer die
      haeufigen (`path`, `cd`).
- [ ] `[F]` `attach_delete` ohne "force delete"-Keymap-Variante fuer
      modifizierte Buffer — nur der Ex-Command mit `!` deckt das ab.
- [ ] `[F]` Cycle-Keymaps ohne Pattern-Filter-Aequivalent (`next *.lua`
      existiert nur als Ex-Command, nicht als Keymap mit Prompt).

### filetree.nvim

- [ ] `[F]` Kein Dry-Run-Keymap/-Toggle fuer `copy_move` / `rename_batch` —
      nur `trash` hat `:Filetree trash dry-run`, und nur als Ex-Command.
- [ ] `[F]` Kein Keymap, um direkt zu einer bestimmten Mark zu springen; kein
      Diff zweier markierter Dateien gegeneinander (nur `diff marked` gegen den
      aktuellen Buffer).
- [ ] `[F]` Gar keine Visual-Mode-Keymaps — alles ist Single-Node-Normal-Mode
      oder marks-basiert.
- [ ] `[N]` Bewusst **kein** count: "N Items" laeuft hier ueber Marks
      (mark-then-act). Beim Sweep nicht nachruesten, nur in `BINDINGS.md`
      als bewusste Entscheidung dokumentieren.

### github_stats.nvim

- [ ] `[N]` `[F]` `cycle_sort` / `cycle_time_range` (`s`/`t`) koennten count
      als "N Schritte weiter" nutzen (`3s`).
- [ ] `[L]` Buffer-lokaler-Autocmd-Workaround zurueckbauen (nach Phase 1).
- [ ] `[L]` `[?]` N-Fetch-Hintergrundabruf koennte `chained_action` aus
      Phase 1 nutzen — pruefen.

### images.nvim

- [ ] `[C]` `[?]` Completen `:Image next`, `:Image pickers [cfile|cwd|path]
      [dir]`, `:Image compare [...]` ihre Festwert-Argumente? Unverifiziert.
- [ ] `[N]` `<leader>in` / `<leader>ip` (next/prev) lesen kein `vim.v.count1` —
      `3<leader>in` = 3 Bilder weiter.
- [ ] `[N]` Redact-Window `u` (letzte Box zuruecknehmen) ohne count — `3u`.
- [ ] `[F]` `paste` / `screenshot` als Keymap ohne Namensargument (nur
      `:Image paste {name}` kann das). Als bare-lhs-Keymap unpraktisch, da kein
      Texteingabepfad — ggf. mit Prompt loesen oder als "n/a" abhaken.

### language.nvim

- [ ] `[N]` Thesaurus-Replace ohne count fuer die direkte Auswahl des N-ten
      Synonyms (`3<leader>th`, analog zu `z=`) — die Auswahlliste existiert
      intern bereits.
- [ ] `[F]` Translate-Operator-Mapping kann die Zielsprache nicht waehlen
      (immer die Default-Sprache) — pro-Sprache-Mapping oder Prompt.
- [ ] `[N]` Der Operator-Pending-Mapping erbt den count der Motion bereits
      nativ (`3<leader>tww`). Nicht anfassen, nur dokumentieren.

### markdown.nvim

- [ ] `[N]` Heading-Navigation (`<C-p>`/`[[`, `<C-f>`/`]]` plus die
      Level-Varianten) liest keinen count.
- [ ] `[N]` Fold-Kommandos ohne count.
- [ ] `[N]` Table-Cell-Navigation (`]|` / `[|`) ohne count.
- [ ] `[F]` `:Markdown toc [level]` ohne count-Aequivalent (`3<leader>toc`
      → `max_level=3`).
- [ ] `[F]` `[?]` `<C-Right>` / `<C-Left>` (Heading-Level inc/dec) vermutlich
      ohne count (`3<C-Right>` = 3 Level hoch).
- [ ] `[L]` Buffer-lokaler-Autocmd-Workaround zurueckbauen (nach Phase 1).
- [ ] `[QF]` Link-Diagnosen als Quickfix-Export — **nicht jetzt**, Phase 3.

### mdview.nvim

- [ ] `[C]` `[F]` `:MDView zoom <factor>` ohne sichtbares Clamping/Validierung
      des numerischen Werts auf Route-Ebene.
- [ ] `[F]` Kein `:MDView start --port <n>` fuer einen festen Port (z. B. fuer
      Firewall-Regeln) — derzeit nur implizit ueber `config.browser` /
      `server_args`.

### pickers.nvim

- [ ] `[N]` `<leader>dp` (Dir-Navigation) ohne `vim.v.count1`, obwohl "N Ebenen
      hoch" via `:Pickers dir <number>` schon existiert. `2<leader>dp` waere
      eine kleine, natuerliche Ergaenzung.
- [ ] `[F]` `keymaps.explorer` (`<leader>.`) ist nur in einem Code-Kommentar
      dokumentiert, nicht als eigenes Feld in der Config-Referenz. Doku-Luecke.
- [ ] `[F]` Die "find all"-Eskalationsflags (`hidden` + `no_ignore` + `follow`)
      lassen sich nicht selektiv kombinieren — all-or-nothing.
- [ ] `[L]` Buffer-lokaler-Autocmd-Workaround zurueckbauen
      (`selected_index/init.lua:184-193`, nach Phase 1).
- [ ] `[QF]` Quickfix-Export inkl. Marks-Feature — **nicht jetzt**, Phase 3.

### sandbox.nvim

- [ ] `[F]` Kein Keymap/Kommando, um direkt aus der List-View zwischen den drei
      Engines zu wechseln (nur `:Sandbox engine set`).
- [ ] `[F]` `container exec` / `exec-once` ohne Flag fuer das Arbeitsverzeichnis
      im Container (`docker exec -w`).
- [ ] `[F]` Kein `--dry-run` / Preview vor destruktiven Bulk-Aktionen — die
      Rueckfrage nennt nur "Remove 5 containers?", nicht welche.
- [ ] `[F]` List-Views ohne Such-/Filter-Keymap — `/` sucht nur im Buffer, kein
      strukturierter Filter nach Status/Name.
- [ ] `[N]` List-View-Aktionen bewusst ohne count (je genau ein Item unter dem
      Cursor); "N Items" gehoert hier in Visual-Mode-Multiselect. Nur
      dokumentieren.

### spotlight.nvim

- [ ] `[N]` Keines der 7 Mappings liest `v:count`. `N]k` / `N[k` ("N Treffer
      ueberspringen") ist naheliegend, da `nav.lua` die Navigation bereits
      kapselt.
- [ ] `[F]` `:Spotlight list` hat `jump`/`remove`-Mode-Args, aber kein
      Filter-Arg (Farbe, Origin) — nuetzlich sobald viele Spotlights aktiv sind.
- [ ] `[F]` `next`/`prev` ohne `!`-Bang/Flag, um eine session-weite Suche
      unabhaengig vom konfigurierten `nav.scope` zu erzwingen.

### reposcope.nvim

- [ ] `[C]` `filter [text]` und `prompt [field ...]` sind Freitext ohne
      erkennbare Completion.
- [ ] `[C]` `[?]` Clone-Zielverzeichnis-Prompt: Pfad-Completion unverifiziert —
      `PATH`-Typ aus Phase 1.
- [ ] `[N]` `nav_up` / `nav_down` bewegen exakt einen Listeneintrag pro
      Tastendruck; `3<Down>` fehlt.

---

## Welle C — Schwer / unscharf

### replacer.nvim

- [ ] `[C]` Volle Flag-/kv-Completion fuer das sehr flag-reiche `:Replace`:
      `--regex`, `--type=`, `--glob=`, `--exclude=`, `--changed=`, `--engine=`,
      `--context=`. Im Audit als "praktisch unverzichtbar" markiert, aber aus
      dem gelesenen Code nicht verifiziert — **zuerst pruefen, was schon da
      ist**. `:ReplacePreset` hat bereits explizite Namens-Completion.
      Groesster Einzelbrocken des Sweeps; ggf. neuer composer-Mechanismus, dann
      `[L]`.
- [ ] `[QF]` Hat als einziges Plugin bereits Quickfix-Export (`export.lua`) —
      dient in Phase 3 als Referenz. Nichts zu tun.

### documentation.nvim

- [ ] `[F]` `:DocMap churn [range]` / `:DocMap diff [ref]` ohne Completion fuer
      Git-Refs/Ranges (im Gegensatz zu den Modulnamen) — `git branch` /
      `git tag` waeren moeglich.
- [ ] `[F]` Keine `<Plug>`-Mappings fuer einzelne `DocBrowse`-Actions (z. B.
      `goto_source`), nutzbar ausserhalb einer offenen Browser-Instanz —
      derzeit nur ueber `opts.keys` erreichbar.
- [ ] `[QF]` Quickfix-Export-Kandidat — **nicht jetzt**, Phase 3.
- [ ] `[N]` Referenzimplementierung fuer count (`browse/init.lua:1018-1176`,
      geclamptes `v:count1`; `j`/`k` bewusst nicht reimplementiert). Nichts zu
      tun — beim Nachruesten anderswo als Vorlage nehmen.

### nvim-config (dieses Repo)

- [ ] `[C]` `:MyReposUpdate [path]` ist mit `nargs = "?"` registriert, aber
      **ohne** `complete` — im Gegensatz zum Geschwister
      `:MyPlugins clone/remove/… [dir]`, das den `MYPLUGINS_DIR`-Typ nutzt.
      Einzeiler: denselben Typ wiederverwenden
      (`bindings/usrcmds/update_repos/init.lua:156-164`).
- [ ] `[N]` `<leader>tn` / `<leader>tp` (Tab next/prev) ignorieren `v:count`,
      obwohl `:tabnext` / `:tabprevious` nativ einen count-Praefix akzeptieren.
- [ ] `[N]` Window-Resize (`<S-h/l/j/k>`) nutzt fixen Schritt 5 statt
      `v:count1 * 5`.
- [ ] `[N]` `[q` / `]q` / `[l` / `]l` (Quickfix/Loclist) und `]w` / `[w`
      (Trouble Workspace-Diagnostics) ignorieren count, obwohl die
      zugrundeliegenden Ex-Kommandos ihn unterstuetzen.
- [ ] `[N]` `view_scroll.lua` liest `v:count` sauber (`0` → halbe Fensterhoehe)
      — bestes Count-Modell der Config, aber aktuell inaktiv/auskommentiert.
      Entscheiden: reaktivieren oder entfernen.
- [ ] `[F]` `:MyPlugins clone/reclone --dry-run` — Vorschau, was geklont/
      entfernt wuerde. Grundlage existiert in `finish_check`/`finish_reclone`,
      nur nicht als eigener Dry-Run-Pfad exponiert.
- [ ] `[F]` `:MyReposUpdate --only=<name>`, analog zu
      `:MyPlugins fetch/pull/update --only=<name>` — derzeit immer alle Repos.
- [ ] `[F]` `:WhoLocks --json` fuer eine kuenftige pickers.nvim-Integration
      (aktuell nur Plaintext-Notify + `print`).
- [ ] `[F]` `[?]` `:Trouble`-Mappings (`[w`/`]w`): `<leader>x`-Variante mit
      explizitem count-Argument — blockiert, bis Troubles API das unterstuetzt.
      Zuerst pruefen, sonst zurueckstellen.

---

## Zuletzt — lsp.nvim (neu, noch nicht auditiert)

Erstellt am 2026-08-23, war im Audit vom 2026-08-08 nicht enthalten. Bewusst
als **letztes** Plugin, weil hier erst die Scans laufen muessen, die fuer alle
anderen schon vorliegen — und weil das Rezept bis dahin eingespielt ist.

- [ ] Scan: Keymaps, Usercmds und Autocmds erfassen. Registrierungen liegen
      unter `lua/lsp/bindings/`, `lua/lsp/usercmds/`, plus die Integrationen
      (`integrations/{mason,trouble,inc_rename}`) und `lua/lsp/lspdoctor/`.
- [ ] `[C]` Completion aller `:Lsp…`-Routen pruefen — nutzt es
      `lib.nvim.usercmd.composer`? Falls ja, faellt Completion aus dem
      Route-Tree; falls nein, ist die Umstellung der eigentliche Task.
- [ ] `[N]` Count-Kandidaten pruefen: Diagnostics-Navigation ist der
      naheliegendste Fall (`3]d`). Ueber `lib.nvim.count`.
- [ ] `[F]` Flag-/Options-Luecken sammeln — das Aequivalent zu dem, was der
      Audit fuer die anderen 30 Plugins geliefert hat.
- [ ] Doku anlegen: `docs/FEATURES` fehlt komplett (vorhanden ist nur
      `docs/features.md` in Kleinschreibung — klaeren, ob umbenennen oder
      Verzeichnis anlegen). `docs/BINDINGS.md` existiert bereits.
- [ ] Zentralen Bindings-Baum anlegen — fuer lsp.nvim fehlen alle drei
      Dateien unter `docs/NOTES/PersonelPlugins/BINDINGS/{Keymaps,Usercmds,
      Autocmds}/`, plus Eintraege in den `All.md`- und
      `autocmds-by-*.md`-Indizes.
- [ ] Ergebnis als eigenen Block hier im Ledger festhalten, damit der Umfang
      dokumentiert ist statt nur abgearbeitet.

## Anhang: Wo liegt die FEATURES-Doku?

Verzeichnis (`docs/FEATURES/`): buffer-ctx, cascade, cmdlog, dap, debugging,
documentation, filetree, gopath, images, insights, language, markdown, mdview,
open, pdfport, replacer, reposcope, runtime-analysis, sandbox.

Einzeldatei (`docs/FEATURES.md`): color_my_ascii, diff, emojis, fileops,
github_stats, pickers, recommender, sessions, spotlight.
Kleinschreibung: migrate (`docs/features.md`).

Beides vorhanden (zuerst klaeren, welche fuehrt): debugging, replacer,
reposcope, color_my_ascii.

`lsp.nvim` hat nur `docs/features.md` (Kleinschreibung) und kein
FEATURES-Verzeichnis — siehe seinen Block oben.
