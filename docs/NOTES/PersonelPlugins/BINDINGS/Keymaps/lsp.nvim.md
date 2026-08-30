# lsp.nvim — Keymaps Cheatsheet

Source: `C:\repos\lsp.nvim\lua\lsp\config\KEYMAPS.lua` (Katalog),
`C:\repos\lsp.nvim\lua\lsp\bindings\keymaps.lua` (Registrierung)
Docs: `C:\repos\lsp.nvim\docs\BINDINGS.md` (generiert), `doc/lsp.nvim.txt`

Keymaps sind Daten: ein Eintrag pro Aktion im Katalog (`lhs`, `mode`, `rhs`,
`desc`, optional `requires`), `bindings/keymaps.lua` bindet, was nach den
User-Overrides uebrig bleibt. Eine neue Map heisst: ein Katalogeintrag — nichts
ist an der Bindungsstelle fest verdrahtet.

Diese Tasten kamen aus fuenf Dateien der Config (`bindings/mappings/lsp.lua`,
`bindings/mappings/trouble.lua`, die LSP-Zeilen aus `bindings/mappings/fzf.lua`,
`config/inc_rename/`, und dem damaligen `lsp/diagnostics/keymaps.lua`), zwei
Paare davon doppelt besessen. Ein Katalog, ein Besitzer.

**Die Tabelle unten ist eine Zweitschrift.** Massgeblich ist
`C:\repos\lsp.nvim\docs\BINDINGS.md` — die wird von `scripts/gen_bindings.lua`
aus dem Katalog erzeugt und in CI mit `--check` geprueft, kann also nicht
driften. Diese Datei kann es, und hat es: sie stand von 2026-08-23 bis
2026-08-29 auf "Stand: keine Keymaps, der Katalog ist leer", waehrend
`default` laengst 44 Eintraege band.

## Steuerung

| Config | Wirkung |
| --- | --- |
| `keymaps.enable = false` | Gar nichts binden |
| `keymaps.preset` | `"default"` (alle 47) / `"minimal"` (31) / `"none"` (keine) |
| `keymaps.map.<action> = "<lhs>"` | Aktion auf eine andere Taste legen |
| `keymaps.map.<action> = false` | Diese Map weglassen |

`minimal` laesst weg, was Neovim 0.11 selbst mitbringt (`grn`, `grt`, `gO`,
`grr`, `gri`, `]d`/`[d`) plus die praefixlose `ls*`-Familie.

## Navigation

| Key | Mode | Effect | Option/Source |
| --- | --- | --- | --- |
| `lsd` | n | Go to definition | `goto_definition` |
| `lsD` | n | Go to declaration | `goto_declaration` |
| `lst` | n | Go to type definition | `goto_type_definition` |
| `grt` | n | Go to type definition (g-Variante) | `goto_type_definition_gr` |
| `lsr` | n | List references | `goto_references` |
| `lsi` | n | List implementations | `goto_implementations` |
| `lss` | n | Document symbols | `document_symbols` |
| `lsa` | n | Code action | `code_action` |
| `<M-s>` | i | Signature help | `signature_help` |

## Rename

| Key | Mode | Effect | Option/Source |
| --- | --- | --- | --- |
| `grn` | n | Rename symbol | `rename` |
| `<leader>rn` | n | Rename symbol (Leader-Variante) | `rename_leader` |

Beide gehen durch **dieselbe** Aktion, die den Backend aus `rename.provider`
waehlt (`"auto"` / `"inc_rename"` / `"native"`). Frueher lief `grn` das native
Rename und `<leader>rn` `:IncRename` — zwei Tasten, dieselbe Operation,
verschiedenes Verhalten. Das war Roadmap-Befund B9.

## Formatter

| Key | Mode | Effect | Option/Source |
| --- | --- | --- | --- |
| `<leader>tft` | n | Format-on-save umschalten | `format_toggle` |
| `<leader>ft` | n | Buffer einmal formatieren | `format_buffer` |
| `<leader>fl` | n | Direkt ueber den Language Server formatieren | `format_lsp` |

## Inlay Hints

| Key | Mode | Effect | Option/Source |
| --- | --- | --- | --- |
| `<leader>th` | n | Inlay Hints global umschalten | `hints_toggle` |
| `<leader>tH` | n | Inlay Hints fuer dieses Filetype umschalten | `hints_toggle_filetype` |

Die geshiftete Taste ist die engere Reichweite derselben Aktion. `<leader>tH`
schreibt einen expliziten Override, auch wenn das Ergebnis dem globalen Default
entspricht — sonst wuerde eine spaetere globale Aenderung den gerade gemachten
Toggle still zurueckdrehen. `:Lsp hints clear <ft>` nimmt den Override zurueck.

## Code-Action-Indikator

| Key | Mode | Effect | Option/Source |
| --- | --- | --- | --- |
| `<leader>tl` | n | Code-Action-Indikator global umschalten | `lightbulb_toggle` |
| `<leader>tL` | n | Code-Action-Indikator fuer dieses Filetype umschalten | `lightbulb_toggle_filetype` |

Dieselbe Global/Shift-Paarung wie bei den Inlay Hints, und aus demselben Grund:
es ist derselbe Schaltertyp. Der Indikator markiert die Zeile, sobald
`textDocument/codeAction` an der Cursorposition etwas zurueckgibt — `lsa` ist
damit kein Blindgriff mehr.

Entscheidend ist `lightbulb.kinds` (Default `quickfix`, `source`): ungefiltert
leuchtet die Lampe unter `ts_ls` und `gopls` permanent, weil beide fast ueberall
Refactorings anbieten, und eine Lampe, die immer leuchtet, sagt nichts. Mit dem
Default heisst sie „hier ist etwas kaputt und behebbar". `:Lsp lightbulb status`
sagt, welche Clients im Buffer `codeActionProvider` melden.

## Diagnostics — Listen und Navigation

| Key | Mode | Effect | Option/Source |
| --- | --- | --- | --- |
| `<leader>wq` | n | Diagnostics → Quickfix (Workspace) | `diag_to_qflist` |
| `<leader>lq` | n | Diagnostics → Loclist (Buffer) | `diag_to_loclist` |
| `<leader>tq` | n | Diagnostics → Quickfix (schlicht, `vim.diagnostic.setqflist`) | `diag_setqflist` |
| `]d` / `[d` | n, x, o | Naechste/vorige Diagnostic im Buffer | `diag_next` / `diag_prev` |
| `]q` / `[q` | n | Naechster/voriger Quickfix-Eintrag | `qf_next` / `qf_prev` |
| `]l` / `[l` | n | Naechster/voriger Loclist-Eintrag | `loc_next` / `loc_prev` |

Die acht Bewegungstasten respektieren einen Count: `3]q` springt drei
Quickfix-Eintraege weiter. Die Leader-Aktionen fuellen eine Liste oder schalten
etwas um und haben kein geordnetes Ziel, in das ein Count indizieren koennte
(NEW-25).

Wohin `]d`/`[d` fuehren, entscheidet `diagnostics.ui`: `"native"` immer
`vim.diagnostic.jump`, `"trouble"` oeffnet und fokussiert Troubles Liste,
`"auto"` (Default) ist `"trouble"` wenn Trouble installiert ist, sonst
`"native"`.

## Trouble

Alle mit `requires = "trouble"`.

| Key | Mode | Effect | Option/Source |
| --- | --- | --- | --- |
| `<leader>xt` | n | Diagnostics-Liste umschalten | `trouble_toggle` |
| `<leader>xx` | n | Alle Diagnostics | `trouble_all` |
| `<leader>xw` | n | Workspace-Diagnostics | `trouble_workspace` |
| `<leader>xd` | n | Buffer-Diagnostics | `trouble_buffer` |
| `<leader>xl` | n | Location-Liste | `trouble_loclist` |
| `<leader>xq` | n | Quickfix-Liste | `trouble_qflist` |
| `<leader>xld` | n | Definitions | `trouble_definitions` |
| `<leader>xlr` | n | References | `trouble_references` |
| `<leader>xli` | n | Implementations | `trouble_implementations` |
| `<leader>xlt` | n | Type definitions | `trouble_type_definitions` |
| `<leader>xls` | n | Document symbols | `trouble_symbols` |
| `]w` / `[w` | n | Naechster/voriger Eintrag in der **offenen** Trouble-Liste | `trouble_diag_next` / `trouble_diag_prev` |

`]w`/`[w` bewegen sich nur innerhalb einer bereits offenen Trouble-Liste und
tun nichts, wenn keine offen ist. Das ist bewusst eine andere Frage als "wohin
schickt mich `]d`" — deshalb sind es zwei Tastenpaare und nicht eins.

## Picker (fzf-lua)

Alle mit `requires = "fzf-lua"`.

| Key | Mode | Effect | Option/Source |
| --- | --- | --- | --- |
| `<leader>dos` | n | Document symbols | `picker_document_symbols` |
| `<leader>wos` | n | Workspace symbols (live) | `picker_workspace_symbols` |
| `<leader>do` | n | Document diagnostics | `picker_document_diagnostics` |
| `<leader>wo` | n | Workspace diagnostics | `picker_workspace_diagnostics` |

## Sonstiges

| Key | Mode | Effect | Option/Source |
| --- | --- | --- | --- |
| `<leader>lsp` | n | Root-Scope waehlen (cwd / Git-Root / Dateipfad) | `root_scope_pick` |
| `<leader>lsw` | n | Workspace-Folder hinzufuegen (Multi-Root / Monorepo) | `workspace_folder_add` |
| `<leader>lb` | n | Marksman-Markdown-Hints umschalten | `marksman_hints` |

`<leader>lsp` und `<leader>lsw` sehen benachbart aus, bewegen aber zwei
verschiedene Dinge. `lsp` schaltet die *Strategie*, mit der ein Root gesucht
wird, und erreicht nur die Server, deren `root_dir` eine Funktion ist
(`lua_ls`, `marksman`) — `gopls`, `ts_ls`, `clangd`, `csharp` deklarieren
`root_markers`, die Neovim selbst aufloest, ohne Haken. `lsw` fuegt einen
*Workspace-Folder* ueber `workspace/didChangeWorkspaceFolders` hinzu und
erreicht damit jeden Server, der `changeNotifications` ankuendigt, ohne
Neustart. Nur `add` hat eine Taste; `remove` und `list` laufen ueber
`:Lsp root remove` / `:Lsp root list` — eine zweite Taste daneben waere einen
Anschlag davon entfernt, den Ordner zu entfernen, den man hinzufuegen wollte.

## which-key

`<leader>x` — "Trouble / LSP lists"-Gruppe, `<leader>xl` — "Trouble LSP
views"-Gruppe, nur wenn which-key installiert ist und `which_key.enable`
(Default an) gilt.

Die Labels sind **kuratiert, nicht hergeleitet**, und das ist eine bewusste
Ausnahme vom Anti-Drift-Prinzip des restlichen Katalogs. Wuerden sie aus den
gebundenen lhs abgeleitet, bekaeme jeder `<leader>`-Praefix, den das Plugin
beruehrt, ein LSP-Label — `<leader>f` ist aber das Find/File-Praefix der
Config, `<leader>d`, `<leader>w`, `<leader>l` und `<leader>t` ebenso. Die "LSP"
zu nennen waere schlicht falsch. `<leader>x` ist das einzige Praefix, das
ganz diesem Plugin gehoert.

## Notes

- **`requires` wird aufgezeichnet, nicht erzwungen.** Ein Katalogeintrag mit
  `requires = "trouble"` wird gebunden, auch wenn Trouble fehlt — Probing zur
  Bindungszeit wuerde ein Plugin laden, das der User bewusst auf Demand gesetzt
  hat. Die betroffenen `rhs` sind Command-Strings, die bis zum Druck inert
  bleiben. `:checkhealth lsp` meldet jede gebundene Taste, deren Plugin fehlt —
  das ist die Stelle, an der es auffaellt, statt beim Druecken.
- **Die praefixlose `ls*`-Familie kostet jedes Normal-Mode-`l` ein
  `timeoutlen`**, weil Neovim abwarten muss, ob ein `s` folgt. Preis einer
  praefixlosen Drei-Zeichen-Map, bewusst bezahlt.
- **`grn` und `grt` kollidieren mit Neovims eigenen `gr*`-Maps**, die auf
  `LspAttach` **buffer-lokal** gesetzt werden und damit globale schlagen. Ein
  Katalogeintrag auf so einem lhs waere genau in den Buffern verschattet, fuer
  die er gedacht ist. `bindings/autocmds.lua` bindet die zwei auf `LspAttach`
  nach — relevant, sobald `rename.provider` inc-rename waehlt.
- **Kontextmenue:** `lsp.integrations.menu` baut seine Eintraege aus
  `require("lsp").status().keymaps`, also aus dem aufgeloesten Katalog mit
  bereits angewandtem Preset und Overrides. `rename_leader` und
  `goto_type_definition_gr` werden als reine Zweittasten uebersprungen,
  ebenso alles, dessen `requires`-Plugin fehlt.

## Changelog

- 2026-08-23: Repo-Geruest nach `gates/NEW_PROJECT.md` angelegt. Keymap-
  Mechanismus vorhanden, Katalog leer.
- 2026-08-29: **Vollstaendig neu geschrieben.** Die Datei stand noch auf dem
  Geruest-Stand von 2026-08-23 ("keine Keymaps, der Katalog ist leer"),
  waehrend `default` 44 und `minimal` 28 Eintraege band — fuenf Monate Drift
  in dem Baum, aus dem `:Bindings check` seine Vergleichsbasis zieht. Inhalt
  aus dem generierten `lsp.nvim/docs/BINDINGS.md` uebernommen, das aus dem
  Katalog erzeugt und in CI geprueft wird.
- 2026-08-29 (2): `hints_toggle` / `hints_toggle_filetype` (`<leader>th`,
  `<leader>tH`) aus Roadmap-QW3 aufgenommen.
- 2026-08-30: `lightbulb_toggle` / `lightbulb_toggle_filetype` (`<leader>tl`,
  `<leader>tL`) aus Roadmap-M2 aufgenommen. Bei der Gelegenheit die
  Preset-Zeile korrigiert: sie stand noch auf 44/28 und war seit QW3 (45/29)
  falsch; jetzt 47/31.
