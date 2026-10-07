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
