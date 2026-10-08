# Handover — Usrcmd-Hilfe-Float (Cheatsheet fuer Composer-Verben)

Lebendes Dokument: nach **jedem** erledigten Schritt aktualisieren.
Plan + Tasks: tasks.nvim, Plan `lib.nvim/usrcmd-help-float-cheatsheet`
(Vault `$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins`, Area `lib.nvim`;
`:Tasks plan lib.nvim --plan=lib.nvim/usrcmd-help-float-cheatsheet`).

**Arbeitsweise (global):** Antworten deutsch, Code/Kommentare englisch; max. Agent-Anzahl laut
Nutzerregel; nach jedem Schritt auf `main` pushen (kein PR); keine Co-Author-Zeile; Edit-Tool statt
Shell-Heredocs bei Backslashes (`HEREDOC.md`).

## Wunsch

1. Nur den Root-Usrcmd eingeben (`:Clipboard`, `:Ui`, ...) zeigt heute eine Notify-Textausgabe; stattdessen
   ein **UI-Float** mit allen Optionen, je `option - kurze Beschreibung`; `<CR>` fuegt die Option in die
   Cmdline ein.
2. Auf **jeder Ebene** (`:Cdx prompt` unvollstaendig -> Float statt Fehler).
3. **Cheatsheet-Taste:** in der Cmdline (`:Clipboard ` getippt) per Taste das Float oeffnen, *ohne* dass
   etwas falsch eingegeben ist. Beschreibungen knapp, kein Doku-Aufsatz.
4. **Opt-in**, bis der Nutzer zufrieden ist; erst **ein** Verb als Pilot.

## Stand (2026-10-07): Kern fertig, Pilot aktiv

| Was | Wo | Commit |
|---|---|---|
| Option-Float, Opt-in, Cheatsheet-Taste, `desc`/`enum_desc`, Spec, README | lib.nvim | `237825d` |
| lange Beschreibungen auf Bildschirmbreite kuerzen | lib.nvim | `ec469be` |
| Pilot: `:Clipboard` mit `help = true`, Taste `<C-\>h`, kuerzere Route-Descs | nvim-config | `73fcb2e1` |
| Plan + Tasks | WKDBooks | `d5e633e2` |

### Aufbau (lib.nvim `lua/lib/nvim/bindings/usercmd/composer/`)
- `help/entries.lua` — **rein**: `compute(root, committed_tokens, lead)` -> Zeilen (Subcommands, Gruppen mit
  Zusammenfassung ihrer Kinder, Enum-Werte mit `enum_desc`, `--flags`, `key=`-Paare, Werte von `--flag=` /
  `key=`, Hint-Zeile fuer freie Argumente). Filter wie `<Tab>` (`available`/`check`), bereits gegebene Flags
  fallen weg, Lead filtert per Praefix (kein Treffer -> volle Liste).
- `help/ui.lua` — Zeilen -> `kit.select` Rich-Items (Label gedimmt-aktiv, Beschreibung `KitMuted`, Gruppen
  mit `›`, Ueberschriften nur bei >1 Abschnitt, Beschreibung auf 80 % Bildschirmbreite gekuerzt).
- `help/init.lua` — `parse_line` (Range/Bang/Lead), `insertion`, `open`, `from_cmdline`, `on_dispatch`,
  `set_keymap` (Cmdline-Expr-Mapping: verlaesst die Cmdline per `<C-c>`, oeffnet das Float, **Esc stellt die
  Zeile wieder her**), `setup`, `enabled`.
- `parse.lua` — `M.show_usage(notify, level, text, tokens, reason)`: nutzt `notify.help(...)`, sonst Notify
  wie bisher. Greift bei bare `:Verb`, unvollstaendiger Gruppe, unbekanntem Subcommand. `spec.default` gewinnt.
- `init.lua` — Notifier bekommt `help`; `composer.setup({ help = { enable, keymap } })`; `composer.help` lazy.

### Opt-in (Default: aus)
Verb ist "an", wenn `spec.help == true`, oder `help.enable` gesetzt und `spec.help ~= false`. Die Taste wirkt
nur bei angeschalteten Composer-Verben (sonst nichts). Taste: `composer.setup({ help = { keymap = "<C-\\>h" } })`
(in `lua/bindings/usrcmds/init.lua`).

### Entscheidungen / Abweichungen vom ersten Konzept
- `kit.select` statt `kit.menu` (kein Spiegel-Drift mit ui.nvim, keine Aenderung an `menu.lua`).
- Kein Drill-down im Float: jede Wahl wird eingefuegt, die Taste oeffnet die naechste Ebene.
- Default-Taste `<C-\>h` (nicht `<C-\>` allein: kollidiert mit `c_CTRL-\_e`); frei konfigurierbar.
- Fehlerpfad `missing required argument` oeffnet das Float noch nicht (Task `help-float-missing-argument-float-stage-2`);
  die Cheatsheet-Taste deckt die Ebene aber ab.

### Tests
`TESTS/composer_help_spec.lua` (in `TESTS/run.lua` und `TESTS/README.md` eingetragen): Engine, Parsing,
Insertion, UI-Items, Opt-in, Dispatch-Hook, Taste. Integrationslaeufe (Float, `j<CR>` -> `:Demo open `,
Taste -> Float, Esc -> Zeile zurueck) wurden headless mit gestubbtem `nvim_list_uis` gefahren.
Bekannte, nicht zu verantwortende Ausfaelle der Gesamt-Suite: `telemetry_wrap_spec` (runtime-analysis fehlt),
`git_spec` (Worktree-Branchname).

## Nachtrag 2026-10-07 (spaeter)

- Taste ist `<M-h>` (`<C-\>` braucht AltGr und kam im Terminal nicht an); Nutzer hat den Pilot probiert: **funktioniert**.
- lib.nvim `70e41e2` (Review-Funde: Range/Bang, Restore, Taste durchreichen, `--flag <wert>`, `--`, Steuerzeichen) und
  `86f6f18` (**fehlendes Pflichtargument oeffnet das Float** auf der Ebene der Route; falscher Wert behaelt die Meldung).
- Tasks: Pilot und Stufe 2 erledigt. Offen im Plan: Entscheidung `:UI`, Beschreibungen fuer fileops/debugging.

## Offen

1. **Entscheidung Rollout** (Task `help-float-ui-usercmd-decision-migrate-or-attach`, Nutzer): `:UI`/`:Theme`
   (ui.nvim, handgebaut mit eigenem Dispatcher/`complete()`) auf den Composer migrieren (~1 Tag) oder nur anbinden
   (~2 h); weitere Verben mit `spec.help = true` oder global `help.enable = true`.
2. Beschreibungen (Task `help-float-descriptions-for-fileops-and-debugging-routes`): fileops `route()` und
   debugging-Routen haben keine `desc` (die Floats zeigen dort nur den Namen). Alle anderen Repos sind ausreichend
   beschrieben (die frueher vermuteten Luecken in replacer/recommender waren `path = {}`-Wurzelrouten mit Verb-`desc`).
3. Optional: `desc`/`enum_desc` an Argumenten, wo Werte nicht selbsterklaerend sind.

## Stolperfallen (aus den Reviews)

- Ein Lua-`expr`-Mapping hat `replace_keycodes = true`: den Rueckgabewert **roh** liefern (`"<M-h>"`, `"<C-c>"`),
  nicht vorher durch `nvim_replace_termcodes` jagen (sonst Muell wie `<80>ü`; in der echten Config lief das in einen Haenger).
- `nvim_feedkeys(..., escape_ks = true)` fuer Text aus der Cmdline (ein Byte 0x80, z. B. im Gedankenstrich, ist sonst K_SPECIAL).
- `fargs` sind schon entmaskiert (`my\ key` -> `my key`): beim Wiederaufbauen der Zeile Leerzeichen und `\` wieder maskieren;
  Zeile aus der Cmdline mit maskierten Leerzeichen tokenisieren (`help/init.lua: split_tokens`).
- Bei `-count`-Verben liefert nvim fuer `:Verb 3 sub` `range = 1`, `line1 = Cursorzeile`, `line2 = 3`: die Zahl steckt in `line2`.
- Hinter einem nackten `--` hoeren nur die Flags auf (`flags.split`); `key=value` wird weiter geparst (`kv.split`).
- Die echte Config laedt lib.nvim vom `main`-Checkout: Fixes erst nach Push+Pull dort testbar.

## Stand nach Review-Runde 3 (2026-10-07)

- Stufe 0 (global `help.enable = true`, Taste `<M-h>`) und Stufe 1 (alle Routen von `Filetree`/`Ft`, `Debug`, `File` beschrieben) sind drin.
- Runde 3 (lib.nvim `686f03b`, filetree `6ab56ba`, debugging `c684af4`): offenes Token nach `\ `, Kurz-Flags (`-m <wert>`),
  `optional_value`-Flags bare einfuegbar, **UTF-8-Sanitizer** fuer jede ueber das Typeahead wiedergegebene Zeile (ein einzelnes
  Byte 0x80 + `KA` ist `<kEnter>`), **Lazy-Stubs** (Verb eines noch nicht geladenen Plugins: lazy laedt es, dann das Float),
  Meta-Taste ausserhalb von Help-Zeilen wird geschluckt (Alt-h wuerde sonst die Zeile abbrechen), `stopinsert` vor dem Float,
  Kuerzen nach Zellen statt Zeichen, billigere Gruppen-Zusammenfassung.
- Beschreibungstexte aus Doku-Tabellen sind **nicht** blind uebernehmbar: Reviewer fanden falsche/abgeschnittene/kontextgebundene Texte
  (`messages show`, `noice *`, `neotest framework`, `backup-clean`, `filter`, `move`, ...). Neue Tests pruefen beidseitig:
  jede Route hat einen Text, jeder Text gehoert zu einer Route.
- Offen: Stufe 2/3 (Flag-/kv-Vokabular), Enums, `:UI`-Entscheidung; Platzhalter-Texte der Form `annotation -> :Insert` (buffer-ctx `:Insert`)
  und aehnliche in anderen Plugins sind fachlich leer und sollten ersetzt werden.

## Stufe 2 und 3 (2026-10-08): Flag- und kv-Texte

- Mechanismus (lib.nvim `327131c`, `93745f9`): `--no-x` ohne eigenen Text zeigt `Off: <Text von --x>`;
  `composer.help.undocumented(verb?)` listet Flags/kv ohne Text; Flags mit `values` zeigen ihre Werte wie ein Enum.
- Ergebnis in einer echten Sitzung: `undocumented()` ueber alle 69 Verben = **0**. Jedes Repo hat einen Spec, der das erzwingt
  (er ueberspringt sich, wenn lib.nvim aelter ist als `help.undocumented`).
- Texte stehen an den Spec-Definitionen der Plugins: replacer `1af89ed`, insights `04efcb8`, terminal `83b10a3`, data `5e25c60`,
  rules `39c779a`, casedesk `17ff0d2`, tasks `880938b`, testing `5a11d84`, media `e61ee80`, diff `dd302e9`, open `51372b8`,
  sessions `94e09a7`, gitsuite `834ab0e`, images `fffc82e`, language `193d639`, recommender `0e97e91`, sandbox `c32743f`,
  mdview `61c5fb7`, pdfport `c782e3e`, buffer-ctx `7d45c84`, nvim-config `afef77e7` (:Bindings), `988ddf08` (:MyPlugins).
- Noch ohne Text: **Positionsargumente** (z. B. `old`/`new`/`scope` bei :Replace, `path:MEDIA_PATH` zeigt nur den Typnamen),
  `mode`-Werte bei `:Image paste`; die `:UI`-Entscheidung; Vorbehalte der Agenten (alle Zweifelsfaelle stehen in ihren Commits/Specs).
- Hinweise: casedesk-Docs nennen `:Cases find ... year=`, das es nicht gibt; replacer-Docs sagen "jedes Flag hat ein --no-"
  (stimmt nicht fuer alle 41).

## Positionsargumente (2026-10-08)

- Mechanismus (lib.nvim `d1a8874`): `desc` am ArgSpec, **Typ-Text** (`register_type(name, { desc = ... })`, einmal pro geteiltem Typ),
  Enum mit `desc` zeigt eine inerte Zeile ueber den Werten (+ `enum_desc` je Wert), eingebaute Typen zeigen ihren Namen;
  `help.undocumented(verb?, { args = true })` listet, was noch nichts sagt.
- Ergebnis in einer echten Sitzung (alle Plugins geladen): `undocumented(nil, { args = true })` ueber alle **69 Verben = 0**.
  Jedes Repo hat einen Spec, der Flags, kv **und** Argumente erzwingt (ueberspringt sich bei aelterem lib.nvim).
- Texte: casedesk `971af62`, sandbox `1d9ab9c`, pdfport `06751fe`, media `c0c7824`, images `68b010f`, terminal `2c891ce`/`9b1775d`,
  pickers `fc780b1`, lsp `516466d`, hover `d27de3e`, spotlight `4f7bb1f`, reposcope `8a148f8`, emojis `ee8764b`, insights `f329e76`,
  github_stats `bf5827f`/`f3b47fe`, buffer-ctx `44713a7`, sessions `a551393`, mdview `b4941e6`, my `a75f525`/`6a2bc33`,
  runtime-analysis `789285a`, tasks `773a23b`, debugging `e267ce7`, fileops `509e27c`, nvim-config `6a7bf62a`,
  replacer `5180871`, open `b4de920`, gitsuite `921571b`/`bfb8e38`, ai `bff2ebb`, cascade `f3b15c5`, lib `55b01d0`, rules `51f377c`,
  gopath `c184732`/`08e8939`, language `bc67f28`, recommender `9e39ae1`, color_my_ascii `ef44fb9`, filetree `965788a`,
  testing `6c44baf`, data `8d69f08`, diff `32eecc7`, markdown `e304f36`.
- **Verhalten geaendert:** debugging.nvim (29 Platzhalter-Slots `arg` entfernt, Slots heissen jetzt wie in der Doku), buffer-ctx
  (`linecount`/`bufnr`/`:Format clear|trim|cite|squeeze` ohne Argument-Slot). Ein zusaetzlich getipptes Token landet weiter in `ctx.rest`.
- Gefundene Fehler (als Tasks angelegt): `:Case clean path=` unerreichbar, `:My set` 1/0 als Boolean, `:Insights imports unused` /
  `compress outdir`, `:GithubStats diff` Presets, `:Debug inspect buffer` Namen vs. Zahl, `:Markdown format` fehlt in
  SUBCOMMAND_NAMES, haengende Config-Tests (`sync_*`).
- Offen: emojis `insert`/`first` bieten ein ignoriertes Scope-Argument an; reposcope-Slot heisst `a1`; gitsuite `bfb8e38` ist redundant
  (`git revert` moeglich); die `:UI`-Entscheidung.

## Review-Runde 4 (2026-10-09): alle uebrigen Code-Commits

117 Agenten (max. 5 gleichzeitig): 13 Repo-Gruppen x (Text-Genauigkeit, Code/Tests) + lib-Security/Perf, jeder Fund mit Skeptiker;
47 bestaetigt (22 falsche/irrefuehrende Texte, 9 Bugs, 15 Risiken, 1 Security), 23 widerlegt. Alle bestaetigten Funde sind behoben:

- **lib.nvim:** `e9076d3` (eine Ebene nur mit freiem Argument oeffnet das Float statt die Zeile still zurueckzugeben; `entries.compute` im pcall;
  Tokens wie fargs), `863952e` (Float-Titel mit Steuerzeichen werden ausgeschrieben, nicht roh gezeichnet), `ca0df56` (**`spec.quotes`**:
  Tab und Float zaehlen einen gequoteten Lauf als ein Token; neues Modul `composer.tokens`), `f013cce`/`28b0d6f` (git_sync-Specs).
- **replacer** `32d5851` (E1513 im argtypes-Spec), `400048a` (abstuerzende Suites lassen CI jetzt scheitern: `TESTS/ci_guard.lua`),
  `af9dfc3` (`quotes = true` an Replace/Replacer/Surround/Wrap).
- **markdown** `b9a0c4c`/`d29b2ab` (Disk-Pfad von `:Markdown format` und link_sanitize behalten BOM/CRLF/Schluss-Newline: `util/disk_lines.lua`),
  `354d592`, `20ed40f` (`:Markdown export pdf <datei>` exportierte bei modifiziertem Buffer den falschen Inhalt).
- **debugging** `321c72e` (Typ `DBG_BUFNR`: Tab bietet Nummern, `inspect buffer` akzeptiert nur Zahlen), `6084759`; **filetree** `593f6e8`;
  **fileops** `54b2c4a`, `f390c00`; **casedesk** `6f7adc5`; **media** `1965f81` (`:Media window screen=` wurde nie weitergereicht);
  **pdfport** `2fd5444` (`pages=` bei pdftotext liefert exakt die gelisteten Seiten), `1d8995f`; **tasks** `1267b95`; **testing** `5976ecb`
  (`:Testing list` bietet `--cached`/`--reporter` nicht mehr an); **sandbox** `5623a06`; **recommender** `8648a78`; **language** `c659fe7`;
  **terminal** `2651d3d`; **reposcope** `e2fca0c`; **lsp** `0fb3a23`; **nvim-config** `bc0b554b` (lokal) = `b7d18bab` (origin).
- **Neue Tasks (Entscheidungen, die die Agenten nicht trafen):** pdfport `pages=` bei claude/gemini ignoriert; casedesk `:Case clean path=`;
  lib: weitere Verben mit `spec.quotes`.
- Hinweis: lokales nvim-config-`main` hat `bc0b554b` noch als Duplikat von `b7d18bab`; `git pull --rebase` verwirft es von selbst,
  sobald die fremde Arbeit (`docs/ROADMAP/new.md`, github-stats-Daten) committed ist.
