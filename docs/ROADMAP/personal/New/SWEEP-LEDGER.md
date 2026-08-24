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

### open.nvim — ERLEDIGT 2026-08-24

- [x] `[F]` Keymap-Optionen kommen jetzt aus der **Handler-Registry** statt
      aus einer handgepflegten Dreierliste. `open_<handler key>` funktioniert
      fuer jeden registrierten Handler, auch fuer einen aus
      `custom_handlers`.
      **Der Audit nannte zwei, es waren mehr:** `split`, `vsplit`, `tab`,
      `terminal`, `image`, `notepad` und die benannten Browser hatten alle
      keine Option — die Liste war schlicht nicht mit den Handlern
      mitgewachsen. Zwei Eintraege haetten dieselbe Falle stehen lassen.
      Ein per `cfg.handlers` abgeschalteter Handler wird jetzt korrekt
      abgelehnt statt auf ein fehlschlagendes Kommando gemappt.
      Sonderfaelle: `open_manager` bleibt Alias auf `open_filemanager`;
      `open_default` bleibt das nackte `:Open` trotz gleichnamigem Handler.
      Registrierung laeuft jetzt ueber `lib.nvim.map`.
      **Achtung `desc`:** jetzt `"open.nvim: :Open split"` statt
      `"open.nvim: open_browser"` — Cheatsheet entsprechend angepasst
      (exakter Stringvergleich in `drift.lua`).
      Commit `cadad40`, Branch `feat/registry-driven-keymaps`.
      Hinweis: open.nvim hat keine Testsuite — zur Laufzeit verifiziert.

### dap.nvim — ERLEDIGT 2026-08-24

- [x] `[F]` Breakpoint-Condition / Logpoint-Message: der Prompt oeffnet jetzt
      vorbefuellt — erst mit dem Wert, der auf dieser Zeile schon liegt
      (`dap.breakpoints.get`), sonst mit dem zuletzt eingegebenen dieser
      Session, sonst leer. Condition und Log-Message werden getrennt
      gemerkt. Leere Eingabe **loescht** den Wert (nvim-dap liest leer als
      "keine Condition"), `<Esc>` bricht ab.
      Drei Call-Sites hatten je eine eigene Kopie des leeren Prompts —
      Keymaps, `:Dap conditional-breakpoint`/`log-point` und die
      nvzone/menu-Eintraege. Jetzt gemeinsam in `core/breakpoints.lua`.
- [x] `[L]` `counted_step()` laeuft jetzt auf `lib.nvim.count.chain`.
      Cap, Teardown, No-Count-Fastpath und die Abort-Sperre sind
      Lib-Verhalten; im Plugin bleibt nur der DAP-Teil (welche Events
      "fertig" und "weg" bedeuten).
      Nebenbei: der veraltete `pcall(require, "lib.nvim.map")`-Fallback samt
      "ships not yet"-Kommentar ist raus.
      Commit `0403309`, Branch `feat/breakpoint-prompts-and-lib-count`.
      Hinweis: dap.nvim hat keine Testsuite — gegen einen gestubbten Adapter
      zur Laufzeit verifiziert. Die `desc`-Strings sind unveraendert, also
      kein Drift-Risiko.

### diff.nvim — ERLEDIGT 2026-08-24

- [x] `[F]` Opt-in-Shortcuts `cfg.keymaps` fuer `:Diff target=git:HEAD` und
      den Merge-Conflict-Fall. **Nichts** wird per Default gebunden — die
      "keine aufgezwungenen Leader-Mappings"-Haltung bleibt, sie war ja der
      Grund, warum der Audit das als *optionale* Ergaenzung markiert hat.
- [x] `[F]` Ebenso Shortcuts fuer `:DiffBuffers` / `:DiffOrig` /
      `:DiffClear`. Die rhs wird aus `cfg.commands.*` gebaut, und jeder
      Shortcut nennt sein `cfg.features.*`-Gate — ein Shortcut auf ein
      abgeschaltetes Kommando wird abgelehnt statt gebunden.
- [x] `[F]` `exit.key` nimmt jetzt eine **Liste**, also `<C-c>` zusaetzlich
      statt als Ersatz. Dabei ein latenter Bug gefunden und behoben:
      `native_diffthis` loeschte `cfg.key` direkt und haette mit einer Liste
      still nichts mehr entfernt — laeuft jetzt ueber `detach_buffer`.
      Commit `945a9a9`, Branch `feat/optional-shortcuts`.
      Neuer Spec `keymaps_spec.lua`, gruen.
      **Vorbestehender Fehlschlag im Repo:** `git_spec.lua` ruft
      `git.resolve` synchron auf, obwohl die Funktion callback-basiert ist
      (`core/git.lua:47`). Der Spec ist veraltet, nicht die Implementierung;
      `:Diff target=git:HEAD` funktioniert. Separat als Task angelegt.

### cmdlog.nvim — ERLEDIGT 2026-08-24

- [x] `[F]` Batch-Delete: `mappings.toggle_selection` (default `<C-Space>`)
      markiert Eintraege, `<C-x>` loescht dann alle markierten. Telescopes
      eigener Multi-Select-Key `<Tab>` ist hier `toggle_favorite`, daher ein
      eigener Key. Ein Batch fragt **einmal** und unterdrueckt danach die
      Pro-Kommando-Rueckfrage der Shell-Loeschung.
- [x] `[F]` `:Cmdlog risky test <command>` meldet, welche Patterns greifen.
      Neues `risky.matching()`; `is_risky` ist jetzt darueber definiert.
      Ignoriert `highlight_risky` (das steuert Anzeige, nicht Auswertung)
      und sagt es, wenn der Schalter aus ist. Ein kaputtes Pattern schliesst
      sich selbst aus, statt zu werfen.
- [x] `[F]` `shell_history = { parse, matches }` als Escape-Hatch. Beide
      Haelften gehoeren zusammen: `matches` braucht das Loeschen, um die
      **Rohzeile** zu finden. `parse` allein laesst das Loeschen verweigern,
      statt den eingebauten Matcher auf ein unbekanntes Format raten und die
      falschen Zeilen entfernen zu lassen.

**Zwei echte Bugs dabei gefunden und behoben.** Die Mappings rufen
`delete_fn(cmd, on_done)`, aber keine der beiden History-Quellen hat diese
Form: `history.delete_entry` ist `(cmd)` mit Boolean-Rueckgabe — der Callback
kam nie, der Picker blieb auf einer veralteten Liste offen. Und
`shell.delete_entry` ist `(cmd, opts, on_done)` — der Callback landete im
`opts`-Slot, `<C-x>` warf `attempt to call local 'on_done' (a nil value)`.
Beides zur Laufzeit bestaetigt. Jede Picker-Quelle geht jetzt durch einen
Adapter, Vertrag ist `(cmd, on_done, opts)`.

Commit `afaba76`, Branch `feat/batch-delete-risky-test-parser`.
`smoke_spec.lua` um 14 Checks erweitert: 66 passed, 0 failed.

### sessions.nvim — ERLEDIGT 2026-08-24

- [x] `[F]` Keymaps fuer `:Session current` und den Picker (`:SessionLoad`).
      **Es waren mehr als die zwei:** die Keymap-Tabelle war eine
      hardcodierte Vierer-Liste, waehrend `:Session` auf zwoelf
      Subkommandos gewachsen war — `toggle-track`, `save-tab`, `load-tab`,
      `save-layout`, `load-layout` hatten ebenfalls keine Option. Jetzt alle
      elf mappbaren plus Picker.
- [x] `[F]` `delete` / `rename`: **kein** Keymap, aber der Grund ist ein
      anderer als der Audit vermutete. Nicht "destruktiv/selten" — sondern
      beide haben **Pflichtargumente**, und ein Keymap ist ein nackter
      Tastendruck ohne etwas zu uebergeben. `:Session save` ueberschreibt
      genauso bereitwillig und ist mappbar. Wer `keymaps.delete` setzt,
      bekommt jetzt genau diese Begruendung statt "Unknown key".
      Als bewusstes n/a dokumentiert, nicht offen gelassen.
      Nebenbei: der veraltete `pcall(require, "lib.nvim.map")`-Fallback ist
      raus.
      Commit `1830a49`, Branch `feat/keymaps-for-every-mappable-subcommand`.
      Hinweis: sessions.nvim hat keine Testsuite — zur Laufzeit verifiziert,
      inklusive der Gegenprobe, dass jedes gemappte Kommando existiert.

### pdfport.nvim — ERLEDIGT 2026-08-24

- [x] `[F]` `pages=` als kv auf `:PdfPort float` / `terminal`. Der Prompt
      machte beide Subkommandos aus Skripten, Mappings oder anderen Plugins
      unbenutzbar — ein Prompt laesst sich nicht nicht-interaktiv
      beantworten. `pages=abc` wird gemeldet und oeffnet nichts, statt zum
      Prompt oder zum ganzen Dokument durchzufallen.
      Hinweis: Completion bietet `pages=` erst ab einem Teilprefix an
      (`:PdfPort float p<Tab>`); bei leerem Lead belegt der Pfad-Completer
      den Slot. Composer-Verhalten, kein Defekt.
- [x] `[F]` `[?]` Batch-Summary: **war da, aber falsch.** Sie zaehlte die
      *versuchten* Dateien — bei drei von fuenf Fehlschlaegen meldete sie
      trotzdem "opened 5 PDF(s)". Jetzt `opened N of M PDF(s), K failed`.
      Dafuer brauchte es ein Abschluss-Signal, das es nicht gab: der
      Dispatch ist durchgehend asynchron und Erfolg ist still. `pdfport.open`
      hat jetzt ein optionales drittes Argument `on_done(ok, err)`, das auf
      **jedem** Pfad genau einmal feuert — inkl. eines Renderers, der wirft
      (jetzt pcall-umschlossen, vorher nicht). Zwei-Argument-Aufrufer
      unveraendert.
      Commit `6194046`, Branch `feat/pages-kv-and-batch-summary`.
      Neuer `TESTS/open_done_spec.lua`, Suite gruen. Er laeuft **zuletzt**:
      er laedt Producer-/Backend-Module, und `registry_spec`/`producer_spec`
      pruefen, dass die noch *nicht* geladen sind — weiter vorne platziert
      bricht er `producer_spec`. So ist die Abhaengigkeit aufgefallen.

### recommender.nvim — ERLEDIGT 2026-08-24

- [x] `[N]` `[F]` Beide Punkte sind dieselbe Sache von zwei Seiten:
      `-t` / `--threshold=N` als Flag, und ein Count auf den Keymaps setzt
      den Threshold (`3<leader>lrr`).
      **Die Audit-Beschreibung war veraltet:** `classify_pos_args` ist keine
      Fallback-Kette, sondern klassifiziert inhaltsbasiert und
      reihenfolgeunabhaengig. Das echte Problem ist enger — der positionale
      Threshold wird *erschlossen* (weder Scope noch Analyzer und
      `tonumber`bar). Beim Tippen in Ordnung, beim Generieren des Kommandos
      falsch. Das Flag sagt es aus und schlaegt den Positional.
      `<leader>lrh` (Threshold 5) bleibt fuer die Muskelerinnerung, ist aber
      jetzt nur noch Kurzform fuer `5<leader>lrr`.
      Keymaps sind deshalb Lua-Funktionen statt `<cmd>…<cr>`: `<cmd>`
      verschluckt den Count. `desc`-Strings unveraendert.
      `v:count` wird **raw** gelesen — 0 muss von einem getippten Count
      unterscheidbar bleiben ("kein Count" = konfigurierter Threshold, nicht
      1).
      Commit `1881616`, Branch `feat/threshold-flag-and-count`.
      Keine Testsuite — zur Laufzeit verifiziert, inkl. Praezedenz
      (`regex 3 --threshold=7` meldet 7).

### migrate.nvim — ERLEDIGT 2026-08-24

- [x] `[C]` `[?]` `[%|cwd]`-Completion: **war schon da.** `MIGRATE_SCOPE`
      ist in `common/command.lua` registriert und bietet beide Literale.
      Genau wie der Ledger-Hinweis vermutet hat — zuerst im Composer
      nachsehen. Zur Laufzeit bestaetigt, nichts zu tun.
- [x] `[F]` `-n` / `--dry-run`: meldet jede Migration mit echtem
      Vorher/Nachher, wendet nichts an. Nur Line und Range brauchten es —
      `%`/`cwd` haben mit dem Picker schon eine Vorschau mit Apply-Schritt.
      In allen vier Modi akzeptiert statt in zweien abgelehnt, damit ein
      Mapping es bedingungslos mitgeben kann.
      **Dabei einen latenten Bug gefunden:** `dispatch` parste den Scope aus
      `ctx.raw.args`, wo die Flags noch drinstehen — `--dry-run` kam als
      "Invalid argument" zurueck. Nimmt jetzt `ctx.args.mode`.
- [x] `[N]` `[F]` Count migriert N Zeilen: `3<leader>mo` deckt Cursorzeile
      plus zwei ab, auf Pufferende geklemmt, als expliziter
      `:{line1},{line2}`-Range. Die Kommandos waren die ganze Zeit
      range-faehig; es hat ihnen nur nie jemand einen Range aus einem
      Keymap uebergeben. Als Range statt via Vims Count-zu-Adresse, weil
      `:3MigrateOpt` "Zeile 3" hiesse, nicht "drei Zeilen ab hier".
      **Achtung:** die Keymap-`desc`-Strings haben sich geaendert.
      Commit `e2bca87`, Branch `feat/dry-run-and-count`.
      Suite gruen; sie deckt bewusst nur die reinen Migratoren ab
      (`migrate.common.*` hardrequired telescope), Rest zur Laufzeit.

### color_my_ascii.nvim — ERLEDIGT 2026-08-24

- [x] `[C]` `[?]` `Fence lang` / `Fence import`: **Completion war schon da**
      (`lang_tags()` bzw. Datei-Completion in `commands/fence/init.lua`).
      Zur Laufzeit bestaetigt.
- [x] `[F]` Toggle-Scope — **die Audit-Praemisse war verkehrt herum.**
      `:ColorMyAscii toggle` ist und war immer **global** (ein
      `state.enabled` ueber alle verwalteten Buffer), nicht
      current-buffer-only. Was gefehlt hat, ist das Gegenteil: Highlighting
      in *einem* Buffer abschalten. Jetzt
      `:ColorMyAscii toggle [global|buffer]`, Default `global`, also
      unveraendertes Verhalten fuer das nackte Kommando.
      Zwei bewusste Kanten: einen Buffer einschalten, waehrend das Plugin
      global aus ist, wird **abgelehnt** (sonst waere er verwaltet und
      wuerde nichts highlighten — liest sich wie ein Bug). Und der
      Buffer-Zustand ueberlebt kein Re-Attach; dafuer ist die
      `filetypes`/`disable`-Config da.
- [x] `[F]` `fence_export` in die ACTIONS-Tabelle aufgenommen — es war das
      einzige `Fence`-Subkommando ohne Eintrag.
- [x] `[L]` Buffer-lokaler-Autocmd-Workaround zurueckgebaut: die zwei
      Autocmds in `setup_buffer` liefen auf der Roh-API unter einem
      Kommentar, `lib.nvim.autocmd.create` unterstuetze `opts.buffer` nicht.
      Tut es. Laufen jetzt ueber den Wrapper.
      Commit `6c19242`, Branch `feat/toggle-scope-and-fence-export`.
      Neuer `TESTS/toggle_buffer_spec.lua`, Suite gruen.

### debugging.nvim — ERLEDIGT 2026-08-24

- [x] `[C]` `report win` / `inspect buffer|window` completen ihre Handles
      jetzt ueber die composer-Argtypen `WINDOW`/`BUFFER`.
      **Der WINDOW-Typ existierte in lib.nvim bereits** (`eb99db1`) — ich
      hatte ihn versehentlich ein zweites Mal registriert und wieder
      zurueckgenommen. Vor lib-Aenderungen kuenftig erst HEAD pruefen.
- [x] `[C]` `keylogger start [path]` bekommt `PATH`-Completion. Die Datei
      existiert noch nicht — completet wird der Verzeichnisteil auf dem Weg
      dorthin.
      `proc`-Ids und `performance startup` behalten bewusst den generischen
      Slot: das Plugin zaehlt diese Werte nicht auf, ein Completer haette
      nichts Wahres anzubieten. Im Spec festgenagelt.
- [x] `[F]` Capture-Sinks: `<lt>f` nur Datei, `<lt>y` nur Clipboard.
      `capture_messages` konnte `save_file`/`clipboard` immer schon — nur
      war ausschliesslich der Default gebunden. Drei getrennte Tasten statt
      Praefixbaum: `<lt>c` und dann auf ein moegliches `f` warten wuerde den
      haeufigen Fall zugunsten der zwei seltenen verzoegern. `<lt>c` bleibt
      unveraendert, Verhalten wie `desc`.
      Commit `dc879ae`, Branch `feat/handle-completion-and-capture-sinks`.
      Neuer `docs/TESTS/handle_args_spec.lua`, Suite gruen.

---

**Welle A abgeschlossen** (13/13) — 2026-08-24.

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
