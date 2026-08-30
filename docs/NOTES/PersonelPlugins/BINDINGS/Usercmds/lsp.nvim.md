# lsp.nvim — `:Lsp <subcommand>` Cheatsheet

Ein Command, gebaut ueber `lib.nvim.bindings.usercmd.composer`
(`<Tab>`-Completion ueber Subcommands **und** jede geschlossene Argumentmenge).

Source: `C:\repos\lsp.nvim\lua\lsp\bindings\usrcmds.lua` (Routen),
`C:\repos\lsp.nvim\lua\lsp\usercmds\` (Legacy-Aliase + `:LspMdHints`)
Docs: `C:\repos\lsp.nvim\docs\BINDINGS.md`, `README.md`, `doc/lsp.nvim.txt`

Registriert von `setup()`, ausser `usrcmds.enable = false`. **Keine** Route ist
range-aware: sie wirken auf den aktuellen Buffer oder auf globalen Zustand, und
weder das eine noch das andere wird von einer Zeilen-Range eingegrenzt.

Ausgabe mehrzeiliger Reports geht in einen Scratch-Split, nicht in eine
Notification — sie ist zum Lesen und Kopieren gedacht, eine Notification wuerde
sie abschneiden.

## Inspizieren

| Command | Range | Effect |
| --- | --- | --- |
| `:Lsp status` | — | Was das Plugin aufgesetzt hat: aufgeloeste Config, gebundene Keymaps, Server, Warnungen aus der Normalisierung |
| `:Lsp servers` | — | Eingerichtete Server, plus die aktuell attachten Clients mit Root und Buffer-Anzahl |
| `:Lsp info` | — | Detaillierte LSP-Information zum aktuellen Buffer |
| `:Lsp health` | — | `:checkhealth lsp` |
| `:Lsp doctor [report]` | — | Per-Buffer-Diagnose; siehe die Report-Tabelle unter „Zwei Ausnahmen" |

## Lebenszyklus

| Command | Range | Effect |
| --- | --- | --- |
| `:Lsp start [server]` | — | Server fuer diesen Buffer starten (auto-detect, oder einen benannten) |
| `:Lsp stop [server]` | — | Clients auf diesem Buffer stoppen (alle, oder einen benannten) |
| `:Lsp restart [server]` | — | Clients auf diesem Buffer neu starten |
| `:Lsp force-restart {server}` | — | Einen Server mit vollstaendigem Cleanup davor neu starten |
| `:Lsp recover` | — | Server nachstarten, die hier laufen sollten und nicht laufen |

`force-restart` ist ein eigener Subcommand und keine Flag auf `restart`: ein
literales Wort nach `restart` waere mehrdeutig mit einem Server namens "force",
und die zwei Operationen sind wirklich verschieden — diese reisst den Client
erst ab.

`[server]` completet aus der **lebenden** Menge (attachte Clients zuerst, dann
alles aus `servers`), ueber einen eigenen Argumenttyp `LSP_SERVER`. Eine bei
der Registrierung eingefrorene Enum waere in dem Moment veraltet, in dem ein
Server dazukommt (NEW-26).

## Formatter, Diagnostics, Workspace, Root

| Command | Range | Effect |
| --- | --- | --- |
| `:Lsp format [action]` | — | `once` (Default), `on`, `off`, `toggle`, `status`, `which` |
| `:Lsp diag {action} [list]` | — | `action` ∈ `qf`, `loc`, `next`, `prev`; `list` ∈ `qf`, `loc` (Default `loc`) |
| `:Lsp workspace [action]` | — | Workspace-weite Diagnostics beim Attach: `on`, `off`, `toggle`, `status` (Default), `now` |
| `:Lsp root [action]` | — | Roots und Workspace-Folders: `show` (Default), `pick`, `add`, `remove`, `list` |

`:Lsp root` traegt zwei verschiedene Mechanismen unter einem Wort. `pick`
schaltet die Aufloesungs-*Strategie* (cwd / Git-Root / Dateipfad) und erreicht
nur die Server, deren `root_dir` eine Funktion ist — `lua_ls` und `marksman`.
`gopls`, `ts_ls`, `clangd` und `csharp` deklarieren `root_markers`, die Neovim
selbst aufloest; dort gibt es keinen Haken, an dem die Strategie greifen
koennte. `add`/`remove` bewegen dagegen LSPs eigene Workspace-Folders ueber
`workspace/didChangeWorkspaceFolders` — das erreicht jeden Server, der
`changeNotifications` ankuendigt, `root_markers`-Server eingeschlossen, und
wirkt ohne Neustart. Ein Server, der das nie angekuendigt hat, wird
uebersprungen statt benachrichtigt; `:Lsp root show` nennt ihn samt Grund.

Der Default wechselte von `pick` auf `show`: ein blankes `:Lsp root` oeffnete
bisher einen modalen Picker, jetzt meldet es Scope, aufgeloesten Root pro
Client und dessen Workspace-Folders in einen Scratch-Split.

`:Lsp diag next`/`prev` benutzt bewusst `1` und nicht `v:count1` als Default:
`v:count` haelt, was der letzte Tastendruck hinterlassen hat, nicht was jemand
in diesen Command getippt hat. Fuer eine Taste ist `v:count1` richtig, fuer
einen Command falsch.

## Inlay Hints

| Command | Range | Effect |
| --- | --- | --- |
| `:Lsp hints [action] [filetype]` | — | `action` ∈ `toggle` (Default), `on`, `off`, `status`, `clear` |

Ohne `filetype` bewegt sich der globale Default; mit einem wird ein Override
nur fuer dieses Filetype geschrieben. `clear` ist die einzige Aktion ohne
globale Bedeutung — "den globalen Override loeschen" waere die Einstellung
selbst loeschen — und verlangt deshalb ein Argument.

`status` berichtet beide Ebenen plus, welche geladenen Buffer ueberhaupt einen
Client mit `inlayHintProvider` haben. "Eingeschaltet" und "zeigt etwas" sind
zwei Fragen.

`[filetype]` completet ueber den Argumenttyp `LSP_FILETYPE` aus den offenen
Buffern plus allem, was bereits einen Override traegt. Neovims eigenes
`getcompletion(_, "filetype")` waere mehrere hundert Eintraege, von denen fast
keiner zu einem gerade offenen Buffer gehoert.

## Log

| Command | Range | Effect |
| --- | --- | --- |
| `:Lsp log open` | — | Neovims LSP-Logdatei in einem Split oeffnen |
| `:Lsp log level {level}` | — | Log-Level setzen; `level` ∈ `trace`, `debug`, `info`, `warn`, `error`, `off` |

## Legacy-Aliase

Die flachen Commands aus der Migration sind weiter registriert und erreichen
dieselben Funktionen wie die Routen. `usrcmds.legacy_aliases = false` laesst sie
weg. Sie sind Aliase, keine Zweitimplementierung — die zwei koennen also nicht
auseinanderlaufen.

| Alias | Route |
| --- | --- |
| `:LspStatus` | `:Lsp servers` (er berichtet die Clients des Buffers) |
| `:LspInfo` | `:Lsp info` |
| `:LspLog` | `:Lsp log open` |
| `:LspRecover` | `:Lsp recover` |
| `:LspForceRestart {server}` | `:Lsp force-restart {server}` |
| `:LspStartHere` / `:LspStopHere` / `:LspRestartHere` | `:Lsp start` / `stop` / `restart` |
| `:LspFormat` | `:Lsp format once` |
| `:LspFormatOn` / `:LspFormatOff` / `:LspFormatToggle` | `:Lsp format on` / `off` / `toggle` |
| `:LspFormatStatus` / `:LspFormatWhich` | `:Lsp format status` / `which` |
| `:LspWorkspaceDiagnosticsOn` / `...Off` / `...Toggle` | `:Lsp workspace on` / `off` / `toggle` |
| `:LspWorkspaceDiagnosticsStatus` / `...Now` | `:Lsp workspace status` / `now` |
| `:DiagQF` / `:DiagLoc` | `:Lsp diag qf` / `:Lsp diag loc` |
| `:DiagNextQF` / `:DiagPrevQF` | `:Lsp diag next qf` / `:Lsp diag prev qf` |
| `:DiagNextLoc` / `:DiagPrevLoc` | `:Lsp diag next loc` / `:Lsp diag prev loc` |

## Zwei Ausnahmen, die keine Aliase sind

Beide bleiben registriert, auch mit `legacy_aliases = false`.

| Command | Warum eigenstaendig |
| --- | --- |
| `:LspDoctor [report]` | Ein Diagnosewerkzeug mit eigenem Renderer und fuenf Reports, kein LSP-Steuerbefehl — dieselbe Ausnahme, die `replacer.nvim` fuer `:Surround` macht. Als `:Lsp doctor` trotzdem erreichbar. `!` oeffnet einen Scratch-Buffer und waehlt **keinen** Report. |
| `:LspMdHints [mode]` | Marksman-spezifisch. Server-Commands gehoeren nicht in ein globales Verb. `mode` ∈ `on`, `off`, `toggle` (Default), `status`. |

Aus demselben Grund sind `:TypeDef*`, `:EslintFix`, `:AstroDevStart`,
`:MdFormat` und `:LuaLsReloadLibrary` unangetastet: filetype-gebunden, und sie
gehoeren dem Modul, das sie besitzt.

### Die fuenf Reports

Der Name nennt die Frage, nicht die Ausgabemenge.

| Report | Beantwortet |
| --- | --- |
| `startup` | Laeuft der Server, und wenn nein, warum? Executable gefunden, Startversuche, letzter Fehler, was als naechstes zu tun waere |
| `resolve` | Wo bricht die Kette Filetype → Server? Fuenf Stufen, von „welche Server sollte dieses Filetype bekommen" bis zu dem, was `:Lsp start` anboete |
| `buffer` | Was ist gerade in diesem Buffer los? Clients, Diagnostics-Zaehlung, Provider-Konflikte, Offset-Encodings, Formatter. Listen bei `list_limit` gekappt |
| `capabilities` | Was koennen die Server hier genau? `buffer` ungekappt, plus `root_dir`/Workspace-Folders und die vollen Capabilities pro Client |
| `all` | Alle vier. Default von `:LspDoctor` ohne Argument |

Default von `:Lsp doctor` ohne Argument ist `startup`, nicht `all`: die Route
oeffnet einen Scratch-Split, und die Frage, mit der man ankommt, ist fast immer
„warum laeuft mein Server nicht".

Bis 2026-08-29 hiessen sie `health`, `debug`, `quick`, `deep`. **Die alten
Namen funktionieren weiter**, als Command-Argument und als Funktion; sie werden
nur nicht mehr in der Completion angeboten. Realisiert ueber den Argumenttyp
`LSP_DOCTOR_MODE` statt einer `enum` — der Composer weist einen Wert ausserhalb
der enum ab, *bevor* `run` laeuft, „akzeptiert aber nicht angeboten" laesst sich
mit einer enum also gar nicht ausdruecken.

## Notes

- **Doku-Datei heisst `doc/lsp.nvim.txt`**, nicht `doc/lsp.txt`: Neovims
  Runtime liefert selbst ein `doc/lsp.txt` (`:h lsp`), zwei Dateien gleichen
  Namens machen `:help lsp.txt` mehrdeutig. Alle Tags sind `lsp.nvim-…`
  praefixiert.
- **Modulwurzel-Kollision:** traegt die Config ihr eigenes `lua/lsp/**`,
  gewinnt sie auf der `runtimepath` und ueberschattet das Plugin komplett.
  Config-Ordner loeschen und Plugin installieren muessen derselbe Schritt sein.
  (Erledigt — das Plugin ist installiert.)
- `vim.g._formatter_api` wird von `setup()` veroeffentlicht, damit die
  Formatter-Aktionen die Instanz finden, die der Bootstrap gebaut hat.

## Changelog

- 2026-08-23: Repo-Geruest. Fuenf Routen, die nichts aus der Migration
  brauchten; das Plugin war in der Config nicht installiert.
- 2026-08-29: **Vollstaendig neu geschrieben.** Die Datei stand noch auf dem
  Geruest-Stand: fuenf Routen dokumentiert, `start`/`stop`/`format`/`diag`/
  `workspace`/`root`/`doctor` unter "Geplant", und der Hinweis, das Plugin sei
  nicht installiert. Tatsaechlich sind alle fuenf Migrationsphasen durch, es
  gibt 17 Routen plus rund 25 Legacy-Aliase. Fuenf Monate Drift in dem Baum,
  aus dem `:Bindings check` seine Vergleichsbasis zieht.
- 2026-08-29 (2): `:Lsp hints` aus Roadmap-QW3 aufgenommen.
- 2026-08-29 (5): `:Bindings check` hat beim Nachziehen von (4) einen
  Verweis auf `:LspStart` gemeldet — den Command gibt es nicht, er heisst
  `:LspStartHere` bzw. `:Lsp start`. Der Text stammte aus dem Plugin selbst,
  das ihn an fuenf Stellen fuehrte, davon eine als Handlungsanweisung im
  `startup`-Report ("Action: Not started - use `:LspStart lua_ls`"). Wer dem
  folgte, bekam E492. Im Plugin und hier korrigiert.
- 2026-08-29 (4): `:LspDoctor`/`:Lsp doctor`-Modi umbenannt:
  `health`->`startup`, `debug`->`resolve`, `quick`->`buffer`,
  `deep`->`capabilities`. Alte Namen bleiben gueltig, werden aber nicht mehr
  angeboten.
- 2026-08-29 (3): Klammer-Kurzschreibweise (`:LspFormat{,On,Off,…}`) durch
  ausgeschriebene Namen ersetzt. `:Bindings check lsp.nvim` hatte
  `:LspWorkspaceDiagnostics` als "dokumentiert, nicht registriert" gemeldet —
  zu Recht: der Parser nimmt den Stamm vor der Klammer als Commandnamen, und
  ein bares `:LspWorkspaceDiagnostics` gibt es nicht, nur die fuenf mit Suffix.
  Bei `:LspFormat` fiel es nicht auf, weil der Stamm dort zufaellig existiert.
  Die Kurzschreibweise ist in einem geparsten Baum also eine Falle, unabhaengig
  davon, ob sie im Einzelfall aufgeht.
