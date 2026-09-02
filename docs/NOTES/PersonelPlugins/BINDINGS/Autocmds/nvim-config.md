# nvim-config — Autocmds Cheatsheet

Sources: `lua/autocmds/**`, `lua/bindings/**`, `lua/config/harpoon/**`,
`lua/options.lua`, `lua/plugins/**`, `lua/startup/init.lua`,
`lua/wkdnvchad/ui/**`, `lua/wkdoptions/**`

**Not a plugin.** The autocmds this configuration registers in its own Lua,
which belong to no plugin. The keymaps half lives in
[`Keymaps/nvim-config.md`](../Keymaps/nvim-config.md), the commands half in
[`Usercmds/nvim-config.md`](../Usercmds/nvim-config.md).

Erstellt 2026-09-02. Der Korpus ist nach Plugins geschnitten und hatte fuer
die Autocmds der Config nie einen Ort — bis `:Bindings check` eine
Autocmds-Achse bekam und **35 von 47 undokumentierten Registrierungen** dieser
Config zuschrieb. Dieselbe Luecke, die die Usercmd-Seite mit `:MyOpt*` hatte,
eine Stufe tiefer: dort existierte das Blatt und es fehlten Zeilen, hier
fehlte das Blatt.

**Gezaehlt werden Aufrufstellen, nicht Event-Registrierungen** — dieselbe
Regel wie in `lsp.nvim.md`. Ein Handler auf drei Events ist eine Zeile;
`nvim_get_autocmds` zaehlt ihn dreifach. Stand dieses Blattes: **58
Aufrufstellen**, davon **43 in 28 Augroups** und **15 ohne jede Augroup**
(siehe "Ohne Augroup" unten).

**Nachtrag 2026-09-02, abends: drei Registrierungen mehr.** `NeotestCore`
(zwei) und `NvChadLspSignature` (eine) fehlten, und sie fehlten aus einem
Grund, der das Blatt selbst nicht betrifft: sie werden erst registriert, wenn
neotest bzw. ein LSP-Client geladen ist. Ein `:Bindings check` in einer
frisch gestarteten Session sieht sie nie. Gefunden hat sie ein Lauf, der die
lazy Plugins vorher absichtlich geladen hat — siehe
`bindings_explorer/docs/MEASURING.md`, Falle 5.

Genau deshalb melden sie sich in einem normalen `:Bindings check` als
`autocmd-not-live` — dieselbe Klasse wie `LspNvimSagaWinbarDepth`, das
ebenfalls an `LspAttach` hängt, und `LspFormatOnSave`, das an einem
Feature-Schalter hängt. Als Prosa statt als Tabellenzeile wären sie still,
aber auch unprüfbar: eine umbenannte Augroup fiele dann nie auf. Drei
bekannte Nicht-Befunde sind der Preis dafür, dass die Zeilen geprüft werden.

Alle 55 laufen ueber `lib.nvim.bindings.autocmd.create` — kein einziger auf
der Roh-API. Die *Augroups* dagegen sind gemischt, wie in lsp.nvim auch.

## Dateisystem-Explorer — `lua/autocmds/`

| Augroup | Event(s) | Pattern | Action |
| --- | --- | --- | --- |
| `AutoCenterExplorerSetup` | `FileType` | — | Auto-Zentrierung fuer Explorer-Buffer einrichten |
| `WkdExplorerSingleton` | `WinEnter` | — | Die jeweils andere Explorer-UI schliessen, wenn eine aufgeht |
| `WkdExplorerSingleton` | `WinClosed` | — | Die verdraengte Explorer-UI **einmal** wieder oeffnen, dann vergessen |

Das Paar in `WkdExplorerSingleton` ist als Paar zu lesen: `WinEnter`
verdraengt, `WinClosed` stellt wieder her. Das "einmal, dann vergessen" ist
der Grund, warum es zwei Aufrufstellen sind und nicht ein Handler auf beiden
Events — der zweite haelt Zustand, den der erste setzt.

## Terminal, Git, Text — `lua/autocmds/`

| Augroup | Event(s) | Pattern | Action |
| --- | --- | --- | --- |
| `general_autocmds_autocmds_general_kitty_spacing` | `VimEnter` | — | Kitty: Fensterabstand fuer das aktuelle Fenster reduzieren |
| `general_autocmds_autocmds_general_kitty_spacing` | `VimLeavePre` | — | Kitty: Abstand beim Verlassen wiederherstellen |
| `git_autocmds_commit_ft` | `FileType` | `gitcommit` | Buffer-Einstellungen fuer die Commit-Message |
| `gitsigns_refresh` | `BufEnter`, `FocusGained` | — | gitsigns bei Fokus/Eintritt neu einlesen |
| `numbers` | `TermOpen` | — | Terminal: absolute und relative Zeilennummern lokal abschalten |
| `trim_trailing` | `BufWritePre` | `*` | Nachlaufende Leerzeichen beim Speichern entfernen |
| `trim_blank` | `BufWritePre` | `*` | Vollstaendig leere Zeilen saeubern, Cursorposition erhalten |
| `last_loc` | `BufReadPost` | `*` | Letzte Cursorposition nach dem Lesen wiederherstellen |

Der Kitty-Name ist doppelt praefixiert
(`general_autocmds_autocmds_general_…`) — ein Artefakt der Namensbildung in
`lua/autocmds/general/init.lua`, kein zweiter Mechanismus. Notiert, weil ein
Grep nach `general_kitty_spacing` ihn sonst nicht findet.

## Keymaps und Commands — `lua/bindings/`

| Augroup | Event(s) | Pattern | Action |
| --- | --- | --- | --- |
| `NoiceBufferMaps` | `FileType` | `noice*` | Buffer-lokale Noice-Keymaps setzen |
| `CasedeskSlaNotify` | `FocusGained` | — | casedesk: SLA-Uhren erneut pruefen (SLA.md §6C) |

## Neotest — `lua/config/neotest/core/`

| Augroup | Event(s) | Pattern | Action |
| --- | --- | --- | --- |
| `NeotestCore` | `BufEnter`, `BufNewFile` | — | An eine Testdatei automatisch anhaengen (`neotest.run.attach`), wenn der Buffername einem der Testdatei-Muster entspricht |
| `NeotestCore` | `User` | `NeotestRunComplete` | Das Output-Fenster oeffnen, sobald mindestens ein Test fehlgeschlagen ist (`enter = false`) |

Beide haengen an einem Schalter: `auto_attach_on_test_file` bzw.
`show_output_on_fail` in `config.neotest.core`. Steht einer auf `false`, wird
der zugehoerige Autocmd gar nicht erst angelegt — die Augroup existiert
trotzdem (`Autocmd.group("NeotestCore", true)`).

## LSP-Signaturhilfe — `lua/nvchad/au.lua`

| Augroup | Event(s) | Pattern | Action |
| --- | --- | --- | --- |
| `NvChadLspSignature` | `LspAttach` | — | Fuer einen neu angehaengten Client `nvchad.lsp.signature` einrichten, aber nur wenn dessen `signatureHelpProvider` Trigger-Zeichen meldet |

Aus derselben lokalen Override-Kopie von `nvchad/au.lua` wie `ReloadNvChad`
und `:MasonInstallAll` (siehe
[`ExternPlugins/Bindings/Autocmds/NvChadUI.md`](../../../ExternPlugins/Bindings/Autocmds/NvChadUI.md)).
Registriert wird nur, wenn `config.lsp.signature` wahr ist.

## Harpoon — `lua/config/harpoon/`

| Augroup | Event(s) | Pattern | Action |
| --- | --- | --- | --- |
| `HarpoonHardening` | `BufLeave`, `FocusLost` | — | Debounced speichern |
| `HarpoonHardening` | `VimLeavePre` | — | Ausstehenden Speichervorgang rausschreiben |
| `HarpoonPinMarks` | `FileType` | `harpoon` | Pin-Marken im Harpoon-Buffer |

`HarpoonPinMarks` steht auch in
[`ExternPlugins/Bindings/Autocmds/Harpoon.md`](../../../ExternPlugins/Bindings/Autocmds/Harpoon.md) —
dort als Verhalten der Harpoon-UI beschrieben, hier als Registrierung dieser
Config. Beide Seiten sind richtig; die Registrierung liegt hier.

## Optionen und Plugin-Specs — `lua/options.lua`, `lua/plugins/`

| Augroup | Event(s) | Pattern | Action |
| --- | --- | --- | --- |
| `MarkdownLocalFolds` | `FileType` | `markdown` | Leichtgewichtiges Markdown-Folding, nur fuer Markdown-Buffer |
| `WebdevRestyLoader` | `FileType` | `http`, `resty` | `resty.nvim` bei seinen eigenen Filetypes nachladen (`once`) |

## Statuszeile — `lua/wkdnvchad/`

| Augroup | Event(s) | Pattern | Action |
| --- | --- | --- | --- |
| `WkdNvChadCwdModeBadgeHl` | `ColorScheme` | — | Die Highlights des cwd-Mode-Badges fuer die neue Palette neu bauen |

## Hervorhebungen — `lua/wkdoptions/hl_config/`

Der groesste Block dieses Blattes: das Highlight-Subsystem der Config, elf
Augroups. Die Namen sind zweigeteilt (`myopt.X` mit Punkt, `myopt_X` mit
Unterstrich) — historisch, kein Unterschied in der Bedeutung.

| Augroup | Event(s) | Pattern | Action |
| --- | --- | --- | --- |
| `myopt.CWord` | `CursorMoved` | — | Wort unter dem Cursor unterstreichen (fensterlokal) |
| `myopt.CWord` | `InsertEnter`, `BufLeave`, `WinLeave` | — | Unterstreichung wieder loeschen |
| `myopt_CwordOccur` | `CursorMoved` | — | Vorkommen des Cursorworts: bei Bewegung aktualisieren |
| `myopt_CwordOccur` | `CursorMovedI` | — | Dasselbe im Insert-Modus |
| `myopt_CwordOccur` | `BufEnter`, `BufWinEnter`, `WinScrolled` | — | Bei Sicht- und Fensterwechseln aktualisieren |
| `myopt_CwordOccur` | `TextChanged`, `TextChangedI` | — | Bei Aenderungen aktualisieren |
| `myopt_CwordOccur` | `BufLeave`, `WinLeave` | — | Beim Verlassen loeschen |
| `myopt_CwordOccur` | `InsertEnter` | — | Beim Insert loeschen, falls so konfiguriert |
| `myopt.Flash` | `TextYankPost` | — | Gejankten Bereich kurz aufblitzen lassen |
| `myopt.ModeTint` | `ModeChanged` | — | `CursorLine` je nach Modus einfaerben |
| `myopt.ModeTint` | `BufWinEnter` | — | Faerbung beim Fenstereintritt erneut anwenden |
| `myopt.ModeTint` | `WinClosed` | — | Cache der Modusfarben aufraeumen |
| `myopt.SigncolTint` | `DiagnosticChanged`, `BufEnter` | — | `SignColumn` nach der schwersten Diagnostic einfaerben |
| `myopt.TermPalette` | `TermOpen` | — | Terminal-spezifische Palette anwenden |
| `myopt.ColorPersist` | `ColorScheme` | — | Highlights nach einem Themenwechsel erneut setzen |
| `myopt.PerWindow` | `WinEnter`, `BufWinEnter` | — | Highlights im aktiven Fenster aktivieren |
| `myopt.PerWindow` | `WinLeave` | — | Im inaktiven Fenster daempfen |
| `myopt.PerWindow` | `BufReadPost`, `TextChanged`, `TextChangedI` | — | Spalten-Highlight bei Groessenaenderung neu pruefen |
| `myopt_PathCache` | `BufEnter`, `BufFilePost` | — | Repo-Pfad-Cache pro Buffer vorwaermen |
| `myopt_PathCache` | `DirChanged` | — | Cache bei `:cd`/`:tcd` auffrischen |

**Sechs Aufrufstellen fuer `myopt_CwordOccur`** sind kein Versehen: jede
schaltet einen anderen Ausloeser, und drei davon *loeschen* statt zu setzen.
In einen Handler zusammengelegt waere die Unterscheidung "aktualisieren" vs.
"loeschen" nur noch im Rumpf sichtbar.

## Optionen — `lua/wkdoptions/options_config/`

| Augroup | Event(s) | Pattern | Action |
| --- | --- | --- | --- |
| `myopt_Options` | `ColorScheme` | — | Basisoptionen und `guicursor` ueber Themenwechsel stabil halten |

## Ohne Augroup

Fuenfzehn Aufrufstellen registrieren **ohne** Gruppe. Sie stehen hier
vollstaendig, weil `:Bindings check` sie strukturell nicht sehen kann: die
Achse braucht eine Augroup, um eine Zeile mit einer Registrierung zu
verbinden, und zaehlt sie deshalb nur als "nicht pruefbar".

| Augroup | Event(s) | Pattern | Quelle | Action |
| --- | --- | --- | --- | --- |
| **none** | `OptionSet` | `diff` | `lua/options.lua:180` | `wrap`/`cursorbind` beim Betreten des Diff-Modus zuruecksetzen |
| **none** | `FileType` | — | `lua/plugins/treesitter.lua:121` | Treesitter-Highlighting aktivieren, Parser-Policy beachten |
| **none** | `FileType` | — | `lua/plugins/treesitter.lua:144` | Treesitter-Folding setzen |
| **none** | `FileType` | — | `lua/plugins/treesitter.lua:154` | Treesitter-`indentexpr` setzen (experimentell) |
| **none** | `VimEnter` | — | `lua/startup/init.lua:105` | Eine ausstehende `UIReady`-Phase nachholen (`once`), **eine pro Phase** |
| **none** | `FileType` | `*` | `lua/wkdoptions/indent_per_ft/init.lua:23` | Einrueckung je Filetype |
| **none** | `ColorScheme` | `*` | `lua/wkdoptions/init.lua:39` | Highlight-Konfiguration nach Themenwechsel neu anwenden |
| **none** | `FileType` | je Sprache | `lua/wkdoptions/italic_keywords/init.lua:21` | Schluesselwoerter kursiv setzen, **eine Aufrufstelle pro Sprache** |
| **none** | `BufEnter`, `BufWinEnter`, `FileType` | — | `lua/wkdoptions/ui/line_numbers/init.lua:62` | Zeilennummern-Modus je Buffer |

**Zwei Zeilen sind Generatoren, keine Einzelfaelle.**
`italic_keywords` laeuft ueber `M.languages` und registriert eine
Aufrufstelle je aktivierter Sprache — derzeit sechs (`typescript`, `go`,
`rust`, `cpp`, `asm`, `lua`). `startup/init.lua:105` registriert eine je
ausstehender `UIReady`-Phase — derzeit zwei (`usrcmds`, `mappings`). Beide
Zahlen wachsen mit der Konfiguration, nicht mit dem Code; deshalb steht hier
der Generator und nicht die Liste.

**Warum das nicht nur Kosmetik ist.** `Autocmds/lsp.nvim.md` hat 2026-08-25
zwei gruppenlose Autocmds als Fehler protokolliert, mit gemessener Folge: ihre
`setup()` hatte keinen Idempotenz-Guard und lief bei jedem Config-Reload
erneut, und ein gruppenloser Autocmd **stapelt** dabei (1 → 2 → 3), waehrend
`usercmd.create` mit `force = true` sich selbst ueberschreibt. Ob eine der
fuenfzehn oben denselben Weg nimmt, ist **nicht gemessen** — es haengt daran,
ob ihr Registrar ein zweites Mal laufen kann.

## Offene Punkte

- **Die fuenfzehn ohne Augroup** auf Stapelverhalten pruefen. Das Rezept steht
  in `lsp.nvim.md`: vor und nach einem Reload `nvim_get_autocmds` zaehlen,
  nicht den Quelltext lesen.
- **Zwei Namensschemata im selben Subsystem** (`myopt.X` / `myopt_X`). Rein
  kosmetisch, aber es macht jeden Grep zweigeteilt.
- **Der doppelt praefixierte Kitty-Name** (siehe oben).

## Changelog

- 2026-09-02: Blatt angelegt. Anlass war die neue Autocmds-Achse von
  `:Bindings check`, die 35 Registrierungen dieser Config als undokumentiert
  meldete — die erste Zahl, die es fuer diese Luecke je gab.
