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

### buffer-ctx.nvim — ERLEDIGT 2026-08-24

- [x] `[N]` `[F]` Count und Range sind **dieselbe Sache**, einmal gebaut:
      `3<S-m>` markiert drei Zeilen, `:'<,'>Mark toggle` eine Selektion.
      Bewusst **kein** Per-Zeilen-Toggle — bei teilweise markiertem Bereich
      ergaebe das ein Schachbrett. Regel: ist irgendeine Zeile unmarkiert,
      wird der ganze Bereich markiert; nur ein vollstaendig markierter
      Bereich wird abgeraeumt. Vertauschte Grenzen werden normalisiert.
- [x] `[F]` Mark-Kategorien: `mark.categories` gibt benannte Erscheinungen
      neben `default`. `:Mark toggle todo`, und `yank`/`clear` filtern
      danach. Neuer Argtyp `MARK_CATEGORY` mit Completion; unbekannter Name
      wird mit der konfigurierten Liste abgelehnt.
      Die Kategorie ist jetzt der **Wert** in der Mark-Tabelle (vorher
      `true`) — dadurch braucht das Filtern keine zweite Tabelle.
      Eine Zeile in anderer Kategorie neu zu markieren **ersetzt**, statt
      abzuwaehlen. `mark.sign` konfiguriert weiter `default`, alte Configs
      bleiben unberuehrt.
- [x] `[F]` `:Mark clear [category]`. Vorher hiess Abwaehlen: jede Zeile
      einzeln toggeln — also erst finden. `keymaps.clear` ist per Default
      **ungesetzt**, es kommt nichts Neues ungefragt dazu.
      Commit `a6e67c2`, Branch `feat/mark-ranges-categories-clear`.
      `mark_spec.lua` erweitert, Suite gruen.
      **Achtung:** der `toggle`-`desc` hat sich geaendert.

### cascade.nvim — ERLEDIGT 2026-08-24

- [x] `[N]` Count auf Cycle, Move und Quick-Toggle — je die Semantik, die
      passt:
      * **Cycle**: N *Schritte*, nicht N Plaetze. Eine Regel deckt alle
        Gruppentypen ab — 2-State nach Paritaet, 3-State mit Wrap, ISO-Datum
        mit Monatsuebertrag (`3<C-y>` auf `2026-08-30` → `2026-09-02`).
        Beide nativen Fallbacks **reichen den Count weiter**, statt ihn zu
        schlucken.
      * **Move**: N-mal je eine Zeile, damit Reindent und Renumber bei jedem
        Schritt stimmen; stoppt am Pufferrand.
      * **Quick-Toggle**: erweitert den *Scope* auf N Zeilen statt zu
        wiederholen — Wiederholen waere bei geradem Count ein No-Op.
      Cycle und Quick-Toggle stashen den Count vor dem Dot-Repeat-Trampolin,
      wie `swap_right`/`swap_left` es schon taten.
- [x] `[F]` `:Cascade cycle add|list|remove` — Gruppen zur Laufzeit.
      Nimmt den ganzen Tail (Werte duerfen Leerzeichen enthalten).
      Abgelehnt: weniger als zwei verschiedene Werte, und Duplikate — beides
      ergibt einen Zyklus, der nicht zyklen kann.
      **Bewusst nicht persistiert**: Session-only, die Config bleibt die
      Wahrheit fuer Gruppen, die man behalten will.
      Commit `3895d4a`, Branch `feat/count-and-runtime-cycle-groups`.
      `commands_spec.lua` prueft die exakte Subkommando-Liste und hat
      `cycle` sofort gemeldet — Erwartung nachgezogen, Suite gruen.
      Keine `desc`-Strings geaendert.

### emojis.nvim — ERLEDIGT 2026-08-24

- [x] `[N]` `[F]` `:Emojis next [count]` — Positional, kein Kommando-Count:
      `:3Emojis next` waere eine Adresse (Zeile 3). Schrittweise statt nach
      dem N-ten Treffer zu suchen, dadurch bleibt der Wrap bei jedem Schritt
      korrekt.
- [x] `[N]` `<leader>et`-Count: **reine Doku-Luecke**, wie im Ledger vermutet.
      Der zentrale Cheatsheet beschrieb ihn bereits vollstaendig — gefehlt
      hat er in der plugin-eigenen `docs/BINDINGS.md`.
- [x] `[F]` `/` filtert das Overlay-Grid. Prompt statt Live-Eingabezeile:
      das Grid ist eine Hotkey-Flaeche mit fester Anordnung (in `grid_keys`
      ist jede druckbare Taste bereits eine Einfuege-Aktion). Gefiltert wird
      durch Neu-Oeffnen, weil Zell-Byte-Spans und Hotkeys beide aus der
      Item-Liste abgeleitet sind. Der ungefilterte Satz bleibt im State, ein
      zweiter Filter weitet also wieder auf.
- [x] `[F]` `:Emojis! toggle` — Checkbox rueckwaerts. `checkbox.toggle` nahm
      immer schon ein `dir`, erreichbar war es nur ueber die Lua-API.
- [x] `[F]` `:Emojis! <action> cwd` — erzwingt `--no-ignore` fuer diesen
      Aufruf, auf einer Kopie der Config, damit ein Aufruf nicht still jede
      spaetere Suche der Session veraendert.
      **Ein Bang, zwei Aktionen, keine Mehrdeutigkeit** — die beiden sind
      disjunkt.
      Commit `a72453e`, Branch `feat/next-count-bang-and-grid-filter`.
      Nebenbei gefixt: `forward()` stringifiziert Positionals, weil `fargs`
      Nvims String-Konvention spiegelt und `execute` `fargs[2]` lowercased —
      das warf, sobald `next` einen INT-Positional hatte.
      `commands_spec.lua` erweitert, Suite gruen.

### fileops.nvim — ERLEDIGT 2026-08-24

- [x] `[F]` `path`, `cd`, `info`, `lockinfo`, `bulk_rename` als `lhs`-Optionen.
- [x] `[F]` `delete_force` — die `:File! delete`-Form. Der normale
      `delete`-Key verweigert bei modifiziertem Buffer und verweist aufs
      Kommando; richtig fuer einen Default-Key, liess die Force-Variante
      aber nur per Neutippen erreichbar.
- [x] `[F]` `next_filtered` / `prev_filtered` — fragen einmal nach dem Glob
      und zykeln dann darin. `cycle.navigate` nahm `opts.pattern` immer
      schon; es hat ihm nur nie jemand einen aus einem Keymap uebergeben.
      Der Glob bleibt fuer die Session gemerkt, Count wird respektiert.

**Alle acht sind per Default ungesetzt.** Einen Keymap *moeglich* zu machen
ist etwas anderes, als eine Taste zu belegen — ohne Konfiguration bindet
nichts Neues. `config_spec.lua` nagelt das fest, damit ein kuenftiger Default
eine Entscheidung ist und kein Versehen.

`ops.file` hatte alles Noetige bereits (`copy_path`, `cd_here`, `info`,
`diagnose_lock`, `delete_current({ force = true })`) — die Luecke war rein,
dass kein Keymap drankam.

Commit `28eeaa5`, Branch `feat/keymap-options-for-command-only-actions`.
Suite gruen.

### filetree.nvim — ERLEDIGT 2026-08-24

- [x] `[F]` Dry-Run-Toggle: `:Filetree copymove dry-run` und
      `:Filetree renamebatch dry-run`. `trash` und `safety` hatten laengst
      einen Runtime-Toggle; ausgerechnet die destruktiven **Bulk**-Operationen
      hatten `dry_run` nur als Config-Key.
      **`renamebatch`, nicht `rename`:** `rename` ist bereits ein
      Leaf-Kommando, eine Tabelle unter demselben Key wird still
      ueberschrieben — genau das ist im ersten Anlauf passiert.
- [x] `[F]` Sprung zu Marks: `Ngm`, `]M`, `[M`. Navigation folgt dem Baum
      **wie gerendert**, nicht der alphabetischen Reihenfolge von
      `get_marked()` — und eine Mark in einem eingeklappten Verzeichnis hat
      gar keine Zeile zum Anspringen. Count klemmt wie bei `G`.
      **Der Diff-Teil brauchte nichts:** `diff_marked()` diffed die zwei
      markierten Dateien seit jeher **gegeneinander**, nicht gegen den
      aktuellen Buffer. Audit-Aussage war falsch, vorher geprueft.
- [x] `[F]` Visual-Mode-Keymaps: `m` markiert die Selektion, `[m` hebt auf.
      Die einzigen Visual-Keymaps des Plugins. Ein Zeilenbereich ueber einem
      gerenderten Baum *ist* eine Knotenmenge.
- [x] `[N]` Bewusst kein Count auf Aktionen — unveraendert. `Ngm` ist ein
      Count auf *Navigation zwischen* Marks, nicht auf das Ziel einer Aktion.
      Im Cheatsheet so dokumentiert.
      Commit `7f5a045`, Branch `feat/mark-nav-visual-and-dry-run`.
      **Beobachtung:** ein Lauf der refs-Suite meldete 46/8 direkt nachdem
      stylua vier Dateien umgeschrieben hatte; in sieben Folgelaeufen nicht
      reproduzierbar, weder mit noch ohne meine Aenderungen. Festgehalten,
      nicht weggelassen.

### github_stats.nvim — ERLEDIGT 2026-08-24

- [x] `[N]` `[F]` `Ns` / `Nt` ruecken N Positionen vor. Count **modulo**
      Zykluslaenge: `5s` bei vier Eintraegen landet eins weiter statt vier
      Extrarunden zu drehen, `4s` ist bewusst ein No-Op. Ein Count groesser
      als der Zyklus ist ein Vertipper, keine Aufforderung zu kreisen.
      Jede andere Navigationstaste des Dashboards las laengst einen Count —
      genau deshalb fiel das Fehlen hier auf.
- [x] `[L]` Die letzten zwei Roh-API-Autocmds laufen jetzt ueber
      `lib.nvim.autocmd.create`. Ihr Kommentar sagte, der Wrapper reiche
      `buffer` nicht durch und wuerde sie zu globalen Listenern machen —
      stimmte damals, heute nicht. Zur Laufzeit geprueft: beide bleiben
      buffer-scoped, kein globaler Leak.
- [x] `[L]` `[?]` N-Fetch mit `chained_action`: **n/a**. Der Fetcher holt
      alle Repos *parallel* mit Completion-Zaehler; `chained_action`
      serialisiert. Verketten waere hier schlicht langsamer, ohne Gewinn.
      Commit `c6a0142`, Branch `feat/cycle-count-and-autocmd-rollback`.
      Keine `desc`-Strings geaendert.
      **Hinweis:** `PlenaryBustedDirectory` terminiert in dieser Umgebung
      nicht; einzelne Spec-Dateien laufen normal, so wurde geprueft.

### images.nvim — ERLEDIGT 2026-08-24

- [x] `[C]` `[?]` **Brauchte nichts.** `:Image pickers` und `:Image compare`
      completen ihre Festwerte (`cfile cwd path`), `:Image next` nimmt gar
      kein Argument. Vorher geprueft.
- [x] `[N]` `<leader>in` / `<leader>ip` mit Count. `step()` wrappt schon
      modulo Bildanzahl — den Delta zu multiplizieren war alles.
- [x] `[N]` Redact-`u` mit Count, geklemmt auf das tatsaechlich Vorhandene
      statt pro fehlender Box zu warnen.
- [x] `[F]` Count auf `paste`/`screenshot` **fragt nach dem Namen**. Der
      Audit nannte ein Namensargument "wuenschenswert, aber als bare-lhs
      unpraktikabel" — als *Argument* ja, als Prompt-Ausloeser nicht.
      Die Luecke war enger als sie aussah: `M.paste(name)` nahm immer einen
      Namen, und der Prompt kam bereits bei `paste.ask_filename = true`. Nur
      bei `false` hatte ein Keymap keinen Weg. Neues `force_ask` durchgereicht.
      Der **Wert** des Counts wird bewusst ignoriert — "3-mal einfuegen"
      ergibt keinen Sinn, er liest sich als Flag.
      Commit `393a847`, Branch `feat/counts-and-name-prompt`.
      Keine `desc`-Strings geaendert.
      **Vorbestehend:** `browse_spec`, `convert_spec`, `remote_spec` schlagen
      in dieser Umgebung fehl (8.3-Pfad, zwei fehlende externe Tools) — per
      Stash als unveraendert bestaetigt.

### language.nvim — ERLEDIGT 2026-08-24

- [x] `[N]` `3<thesaurus.keymap>` nimmt das dritte Synonym direkt, wie `3z=`.
      Die Liste existiert an der Stelle schon — das Menue war nur der Weg,
      daraus zu waehlen.
      `vim.v.count` **raw**: 0 muss von 1 unterscheidbar bleiben (kein Count
      oeffnet das Menue, `1` nimmt das erste Synonym direkt).
      Ausserhalb des Bereichs wird **gemeldet, nicht geklemmt** — ein anderes
      Wort einzusetzen als das gezaehlte waere eine ungefragte Aenderung.
- [x] `[F]` `translate.keymaps.to` — eine Taste pro Sprache, erzwingt das
      Ziel fuer **einen** Lauf (one-shot, laeuft nicht in den naechsten).
      Mit gesetztem `default_target` nahm der Operator immer dieses und
      fragte nie; ohne fragte er immer. Beides ist nicht "dieses Stueck
      jetzt auf Spanisch".
      **Ein Count ging hier nicht:** beim Operator gehoert der Count zur
      Motion (`3<lhs>w` = drei Woerter), das ist der Sinn eines Operators.
      Daher eine Taste pro Sprache — die zweite der beiden Optionen, die der
      Audit selbst vorschlug. Per Default ungesetzt.
      Commit `0b17b02`, Branch `feat/nth-synonym-and-target-keys`.
      Keine Testsuite — zur Laufzeit verifiziert.

### markdown.nvim — ERLEDIGT 2026-08-24

- [x] `[N]` **Alle fuenf Count-Eintraege sind veraltet** — das Plugin hat
      Count-Support nach dem Audit vom 2026-08-08 bekommen. Zur Laufzeit
      bestaetigt statt nur gelesen:
      * `]]` / `[[` und die Level-Varianten lesen `vim.v.count1`
        (`3]]` ab Zeile 1 landet auf der dritten Ueberschrift)
      * `<C-Right>` / `<C-Left>` verschieben um den Count
        (`2<C-Right>` macht aus `##` ein `####`)
      * `]|` / `[|` bewegen N Zellen (`repeat_cell_move`)
      * `:Markdown toc` liest den Count als `max_level`
      * `fold_h2_plus` ebenso als Faltungsebene
      Nichts zu tun.
- [x] `[L]` `refs.lua`s Live-Tracking-Autocmd laeuft jetzt ueber
      `lib.nvim.autocmd.create`. Der Kommentar nannte zwei Gruende — kein
      `buffer`-Durchreichen und die benoetigte Autocmd-Id — beide sind
      erledigt: der Wrapper reicht `buffer` durch **und** gibt die Id zurueck.
      Geprueft: buffer-scoped, kein globaler Leak, `live_off()` funktioniert.
      Die uebrigen Roh-Autocmds (table_mode, hover, tableview) tragen keine
      solche Behauptung und bleiben unangetastet.
- [ ] `[QF]` Link-Diagnosen als Quickfix-Export — **Phase 3**, nicht jetzt.
      Commit `c1efa82`, Branch `fix/refs-live-through-lib-autocmd`.
      Suite gruen.

### mdview.nvim — ERLEDIGT 2026-08-24

- [x] `[C]` `[F]` Zoom-Clamping: **war da**, nur nicht auf Route-Ebene — der
      Audit beschrieb den Ort, nicht das Fehlen. Das echte Problem war
      leiser: `zoom 500` wandte still 300% an. Jetzt wird gemeldet, was
      gewuenscht war, welcher Bereich gilt und was verwendet wurde.
- [x] `[F]` `:MDView start port=N` — Port fuer genau diesen Spawn.
      `port=` statt `--port`, weil `cwd=` bereits die Konvention dieses
      Kommandos ist. Auf die Live-Config gesetzt und **nach dem Spawn wieder
      zurueckgesetzt**, sonst erbt das naechste `:MDView start` ihn still.
      Ausserhalb 1-65535 abgelehnt; bei laufendem Server ignoriert mit
      Warnung, genau wie `cwd=`.
      Commit `a6ad438`, Branch `feat/port-override-and-zoom-report`.
      Zur Laufzeit verifiziert.

### pickers.nvim — ERLEDIGT 2026-08-24

- [x] `[N]` `<leader>dp` liest einen Count als Tiefe: `2<leader>dp` ist
      `:Pickers dir 2`. Das Konzept gab es am Kommando, es hat ihm nur nie
      jemand einen aus dem Keymap uebergeben.
      `vim.v.count` **raw**: 0 muss unterscheidbar bleiben, denn ohne Count
      oeffnet der interaktive Picker, waehrend `:Pickers dir 0` eine echte
      Tiefe ist (das cwd selbst).
- [x] `[F]` **Brauchte nichts:** `keymaps.explorer` ist als eigenes Feld in
      `CONFIGURATION.md`, `KEYMAPS.md` und `BINDINGS.md` dokumentiert — nicht
      nur in einem Code-Kommentar.
- [x] `[F]` Selektive Eskalation: `hidden`, `no_ignore`, `follow` einzeln und
      per `+` kombinierbar; `all` bleibt die Kurzform. Die drei tun
      Verschiedenes — Dotfiles, ignorierte Dateien, Symlinks — also hiess
      all-or-nothing, `node_modules` zu durchlaufen, nur um eine `.env` zu
      sehen. Unbekanntes Flag wird gemeldet und die Eskalation verworfen,
      statt sie teilweise anzuwenden.
- [x] `[L]` **Nichts zurueckzubauen:** das `selected_index`-Modul wurde zu
      `result_count` umgeschrieben und pollt, statt einen buffer-lokalen
      Autocmd zu registrieren.
- [ ] `[QF]` Quickfix-Export inkl. Marks — **Phase 3**, nicht jetzt.
      Commit `fb90198`, auf `main` gemerged und gepusht.
      `pickers_spec.lua` erweitert, gruen.

### sandbox.nvim — ERLEDIGT 2026-08-24

- [x] `[F]` `E` in jeder List-View cycled docker → podman → nerdctl und
      rendert neu. `:Sandbox engine set podman` hiess vorher: Buffer
      verlassen, Kommando tippen, Liste neu oeffnen — drei Schritte fuer
      etwas, das man beim Blick auf genau diese Liste entscheidet.
      Die Zyklusreihenfolge ist eine deklarierte Liste, nicht `pairs`.
- [x] `[F]` `workdir=` auf `exec` / `exec-once` → `-w` der Engine.
      **kv statt Positional:** jeder Token nach der Id gehoert zum Kommando
      *im* Container, ein Positional waere davon nicht unterscheidbar.
      Das Flag steht **vor** der Container-Id — danach reicht die Engine es
      an das innere Kommando durch, was wie dessen eigener Fehler aussieht.
- [x] `[F]` Bulk-Bestaetigung nennt die Items (max. zehn, dann "… and N
      more"). "Remove 5 containers?" liess genau die Frage offen, die eine
      Bulk-Rueckfrage beantworten muss.
- [x] `[F]` `f` filtert strukturiert. `/` findet eine Zeile und laesst die
      anderen stehen; `f` engt ein und matcht ueber **alle Felder** —
      `f redis` findet den Container mit diesem Image, obwohl das Image gar
      nicht in der Zeile steht. Leere Eingabe stellt alles wieder her,
      gefiltert wird immer vom ungefilterten Satz aus.
      Vorerst nur die Container-Liste liefert den Callback; die anderen vier
      binden die Taste schlicht nicht.
- [x] `[N]` Bewusst kein Count — unveraendert. Keine der neuen Tasten nimmt
      einen; Visual-Multiselect bleibt die Antwort auf "N Items".
      Commit `56fa7bc`, auf `main` gemerged und gepusht.
      Neuer `exec_workdir_spec.lua` (12 Checks, drei Engines), gruen.
      **Hinweis:** `:Sandbox` registriert headless nicht (keine Engine-Binary
      vorhanden); die Kommandoschicht wurde direkt aufgerufen geprueft.

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
