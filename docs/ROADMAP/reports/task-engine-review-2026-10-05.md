# Review des Task-Features: Bugs, Security, Performance (2026-10-05)

Geprüft wurden alle Nicht-Doku-Commits, die das Task-Feature umsetzen: die Engine
(`lua/tasks/`), die `:MyPlugins`-Routen und das Dashboard
(`lua/bindings/usrcmds/plugin_repos/tasks_*`), die Specs (`TESTS/tasks/`), dazu die
Gegenstellen in `lib.nvim` (`markdown.frontmatter`), `ui.nvim` (`tasks_counter`) und
`mdview.nvim` (Frontmatter-Tabelle, Rust). Gefixt wurde jeweils sofort, mit Regression-Spec.

Vorgehen: Runde 1 mit drei Review-Agenten (A Lese-/Parse-Seite, B Schreibpfade/CLI/CI,
C Editor-Seite; gestartet vor der Umstellung auf höchstens einen Agenten gleichzeitig), Runde 2 (lib.nvim, ui.nvim, mdview, Statusline)
direkt. Alle Fixes wurden vor dem Merge noch einmal im Diff gelesen. **Kein Commit ist
von einem `ultracode`-Agenten reviewt**; die Prüfung war manuell (Diff gelesen,
Specs/Lint/Tests gelaufen).

## Befunde und Fixes

| Bereich | Befund | Art | Commit |
|---|---|---|---|
| model/fsio/lib | Whitespace-Läufe: `%s+$`, `^%s*(.-)%s*$` laufen quadratisch, eine Zeile mit 40 000 Leerzeichen blockierte den Editor sekundenlang bei jedem Scan | SEC-32 | nvim `ec922b8e`, lib.nvim `034bed4`, `f2043e7` |
| mutate | `done` überschrieb eine Task-Datei, die sich währenddessen geändert hatte (Datenverlust); Rollback ließ Halbzustände zurück und verschwieg, was nicht zurückgerollt werden konnte | BUG | `8290fe0f`, `20e2bb82` |
| mutate | `attach` ließ nach einem fehlgeschlagenen Kopieren einen halb gebauten Folder-Task zurück | BUG | `20e2bb82` |
| vault/scan | Area in anderer Schreibweise (`LIB.NVIM`) erreichte auf Windows/macOS denselben Ordner unter zweiter ID, Index las sich als `index-stale`; dazu Trailing-Dot und Windows-Gerätenamen (`nul`, `con`) | BUG | `4324c229`, `20e2bb82` |
| fsio | Terminal-Steuerzeichen (ESC, OSC, C1) aus Titeln/Refs/Dateinamen erreichten Terminal und generierten Index | SEC | `cc596d04` |
| index | Backslashes in Titeln und ungewöhnliche Dateinamen brachen die generierten Markdown-Links | BUG | `f8bece1b` |
| fsio | `write_atomic` flusht jetzt vor dem Rename und übernimmt den Modus der ersetzten Datei (ein privates `0600` wurde `0644`) | BUG/SEC | `b8ffdf56` |
| frecency | Eine ausgeuferte Frecency-Datei wurde bei jedem Dashboard-Refresh komplett gelesen und dekodiert | PERF | `c5aff412` |
| staleness | `--stale=refs`: ein fehlerhafter Pfad ließ den ganzen `git log`-Aufruf scheitern, kein Zeitbudget, unnötige Git-Aufrufe; `..` in Refs verließ das Repo | BUG/PERF | `f8942853` |
| check | Prozent-kodierte Asset-Links (`two%20words.png`) galten als `asset-dangling` | BUG | `ca1e6f0c` |
| cli | Leeres `--vault=` (nicht gesetzte Shell-Variable) schrieb in den echten Vault; ein per Timeout/Signal beendeter md_lint-Kindprozess zählte als bestanden; fehlender Exit-Code las sich als Erfolg | BUG/SEC | `997672c9` |
| Editor | `task attach` expandierte den Dateipfad ein zweites Mal: `shot[1].png` wurde als Wildcard gelesen (falsche Datei), ein Backtick im Namen lief durch die Shell | BUG/SEC | `ede1300f` (A+B+C fanden es getrennt; zusammengeführt) |
| Editor | Export-Pfad per `vim.fn.expand` (Backtick → Shell, `<cfile>` wirft, Wildcard) | SEC | `15e1cd53` |
| Editor | CSV-Export: Titel mit `=`, `+`, `-`, `@` wurden in Tabellenkalkulationen als Formel ausgeführt (CSV-Injection) | SEC | `4207f991` |
| Editor | Dashboard: Live-Refresh/Picker-Lifecycle, Watcher bei Burst-Events, Preview-Pfad als ein Argument, Temp-Datei-Aufräumen, Streuworte hinter Kommandos, Formular-Cursor | BUG | `15e1cd53`, `ad3aee93` |
| ui.nvim | `tasks_counter`: eine Frontmatter-Zeile mit 60 000 Leerzeichen kostete **16,7 s** auf dem Hauptthread bei jedem Refresh (`(.-)%s*$`, `([^|]-)%s*|`) | SEC-32 | ui.nvim `58a1757` |
| ui.nvim | `tasks_dir`-Quelle übersah Folder-Tasks, kannte weder Quotes, Kommentare noch BOM; ein nicht startbarer Read ließ den Refresh dauerhaft „scheduled" | BUG | ui.nvim `58a1757` |
| mdview | Frontmatter-Tabelle: Escaping und Sanitizer geprüft, **kein Bug**; zwei Regressionstests (Key/Value-Payload, langer ungeschlossener Block) | geprüft | mdview `d4591dd` |

Die Statusline-Verdrahtung (`lua/config/ui_statusline/init.lua`, `variant.lua`) war
korrekt und blieb unverändert.

## Beim Zusammenführen

- A und B fixten den Case-Insensitive-Area-Bug unabhängig; behalten: `vault.dir_listed`
  (öffentlich) plus das strengere `vault.has_area` in `scan.find`.
- B und C fixten das doppelte `expand` beim Attach. Behalten wurde die einfachere
  Variante (der Composer-Typ `FILE` löst `~`/`$VAR`/`%VAR%` schon auf). B's Hilfsfunktion
  `attach_source` fiel weg, weil ihr Fallback noch `vim.fn.expand` (Backtick → Shell)
  aufrief; die Routen-Spec deckt `shot[1].png` über den echten Composer-Weg ab.

## Offene Punkte (bewusst nicht Teil dieses Reviews)

- lib.nvim: `lib/lua/strings/location.lua:17` und `lib/nvim/deps/spec/init.lua:46`
  benutzen noch `^%s*(.-)%s*$` (quadratisch bei langem inneren Whitespace-Lauf), nicht im
  Task-Pfad; durch `lib.lua.strings.core.trim` ersetzbar.
- ui.nvim: `TESTS/context_languages_spec.lua` (Kotlin) schlägt auf diesem Rechner fehl
  (Tree-sitter-Grammatik-Version), unabhängig vom Task-Feature.
- mdview.nvim: `native/wasm-render/src/lib.rs` ist nicht rustfmt-sauber (Altlast, die CI
  prüft es nicht).
- `staleness` blockiert den Editor weiter bis zu 30 s (`TOTAL_BUDGET_MS`), jetzt aber
  gedeckelt statt unbegrenzt; ein asynchroner Pfad wäre die eigentliche Lösung.

## Verifikation

nvim-Config 21 Specs (`nvim -n -i NONE --headless -u NONE -l TESTS/run.lua`), stylua und
luacheck wie in der CI; lib.nvim `LIB_TESTS_OK` (neuer `strings_trim_spec.lua`); ui.nvim
`tasks_counter_spec` 26 Specs; mdview `cargo test` 31 Tests, clippy sauber.
