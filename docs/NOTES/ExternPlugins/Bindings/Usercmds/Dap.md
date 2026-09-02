# nvim-dap (via StefanBartl/dap.nvim) — User-Commands

**Repo:** `StefanBartl/dap.nvim` — gelesen von `:Bindings check`, weil `Dap` sonst mehrdeutig zwischen `dap.nvim` und `nvim-dap` wäre.

Zwei Sätze: die **[custom]** `:Dap`-Routen des Wrappers
`StefanBartl/dap.nvim` (eigenes Repo, `E:/repos/dap.nvim` — kein relativer
Link möglich, anderes Laufwerk), das über `mfussenegger/nvim-dap` und die
UI-Provider (`nvim-dap-view`/`rcarriga/nvim-dap-ui`) sitzt, und die
**[default]** Commands von `nvim-dap` selbst.

> **Korrektur, 2026-09-02.** Hier stand: „`nvim-dap` selbst bringt keine
> Usercmds mit (reine API-Lib)". Das ist falsch — nvim-dap registriert
> **fünfzehn** Commands in seiner eigenen `plugin/dap.lua`. Gefunden hat es
> `:Bindings check`, nachdem die Stamm-Auflösung das Blatt überhaupt erst mit
> einem geladenen Plugin verglich. Es ist dieselbe falsche Behauptung, die
> auch `Usercmds/Conform.md`, `Usercmds/Treesitter.md` und
> `Usercmds/Neotest.md` trugen: „reine API-Lib" stimmte für die Bibliothek
> und nicht für ihr `plugin/`-Verzeichnis.

Die beiden Sätze überschneiden sich inhaltlich fast vollständig — jede
`:Dap`-Route hat ihr `:Dap…`-Gegenstück. Sie unterscheiden sich darin, wer
sie anlegt und wann: die `[default]`-Commands existieren, sobald nvim-dap
geladen ist, die `[custom]`-Routen erst nach `require("wkddap").setup()`.

Die Commands der beiden Nachbarplugins stehen in eigenen Blättern:
[DapView.md](./DapView.md) (11) und [DapVirtualText.md](./DapVirtualText.md)
(4).

## [default] nvim-daps eigene Commands

Registriert in `plugin/dap.lua` des Plugins, also sobald lazy.nvim nvim-dap
lädt — nicht erst durch ein `setup()`.

| Command | Wirkung |
|---|---|
| `:DapContinue` | Session starten bzw. fortsetzen (`dap.continue()`). Ohne laufende Session öffnet es die Konfigurationsauswahl. |
| `:DapNew [config]` | Eine **weitere** Session starten, statt die laufende fortzusetzen. Mit Completion über die Konfigurationsnamen. |
| `:DapToggleBreakpoint` | Breakpoint in der aktuellen Zeile setzen/entfernen. |
| `:DapClearBreakpoints` | Alle Breakpoints entfernen. |
| `:DapStepOver` | Über den Aufruf hinweg. |
| `:DapStepInto` | In den Aufruf hinein. |
| `:DapStepOut` | Aus der Funktion heraus. |
| `:DapPause` | Laufenden Thread anhalten. |
| `:DapTerminate` | Session beenden **und** den Debuggee mit. |
| `:DapDisconnect` | Session beenden, den Debuggee **weiterlaufen lassen** (`terminateDebuggee = false`). Der Unterschied zu `:DapTerminate`, und er ist bei angehängten Prozessen der wichtigere. |
| `:DapRestartFrame` | Den aktuellen Stack-Frame neu starten — wenn der Adapter es unterstützt. |
| `:DapToggleRepl` | Die REPL öffnen/schließen (`dap.repl.toggle()`). |
| `:DapEval [ausdruck]` | Ausdruck im aktuellen Frame auswerten, in einem eigenen Buffer. |
| `:DapSetLogLevel {level}` | Log-Ebene setzen (`TRACE`…`ERROR`). |
| `:DapShowLog` | Die Logdatei öffnen. Der erste Blick, wenn ein Adapter gar nicht erst startet. |

## Die [custom]-Schicht

Wie bei den Keymaps (siehe [Keymaps/Dap.md](../Keymaps/Dap.md)) stammt alles
Folgende von `StefanBartl/dap.nvim`.

Quelle im Wrapper: `lua/wkddap/bindings/usercmds/init.lua` (Registrierung)
und `lua/wkddap/bindings/init.lua` (Orchestrierung), beide in
`E:/repos/dap.nvim`. Aufgerufen aus `wkddap.bindings.setup(cfg)`, das wiederum
aus `require("wkddap").setup(opts)` läuft — demselben Setup-Aufruf, der auch
die Keymaps bindet (siehe
[lua/plugins/personal/init.lua](../../../../../lua/plugins/personal/init.lua),
`"StefanBartl/dap.nvim"`-Block).

Alle Einträge dieses Abschnitts sind **[custom]** — die `[default]`-Commands
stehen oben.

## Unabhängig von `keymaps.enable`

Wichtiger Unterschied zu den Keymaps: `wkddap.bindings.usercmds.setup()` wird
in `bindings/init.lua` **unbedingt** aufgerufen, noch bevor die
`cfg.keymaps.enable`-Prüfung greift. Die `:Dap`-Commands existieren also auch
dann, wenn `opts.keymaps.enable = false` gesetzt würde (in dieser Config nicht
der Fall — siehe [Keymaps/Dap.md](../Keymaps/Dap.md), Default `true` aktiv) —
Commands und Keymaps können in diesem einen Punkt auseinanderlaufen.

## `:Dap <subcommand>`

Gebaut mit `lib.nvim.bindings.usercmd.composer` (`composer.verb`) — dieselbe Composer-
Basis wie `:Harpoon` (`<Tab>`-Completion pro Subcommand, Usage-Ausgabe statt
rohem Vim-Fehler). Jede Route spiegelt exakt eine Keymap aus
`bindings/keymaps/init.lua` (Kommentar im Quellcode: "Every action mirrors a
default keymap 1:1 … but is an independent entry point — the keymaps call
dap()/ui() Lua functions directly, not these commands"). Keymap und Command
rufen also **nicht** dieselbe Funktion auf, sondern beide unabhängig
`require("dap")`/`require("wkddap.ui.provider")` — funktional identisch, aber
zwei getrennte Code-Pfade statt einem gemeinsamen.

| Aufruf | Wirkung | Entspricht Keymap |
|---|---|---|
| `:Dap continue` | `dap.continue()` | `<leader>dac` |
| `:Dap step-over` | `dap.step_over()` | `<leader>das` |
| `:Dap step-into` | `dap.step_into()` | `<leader>dai` |
| `:Dap step-out` | `dap.step_out()` | `<leader>dao` |
| `:Dap terminate` | `dap.terminate()` | `<leader>dat` |
| `:Dap restart` | `dap.restart()` | `<leader>dar` |
| `:Dap toggle-breakpoint` | `dap.toggle_breakpoint()` | `<leader>dab` |
| `:Dap conditional-breakpoint [condition...]` | `dap.set_breakpoint(condition)` — ohne Argument `vim.fn.input()`-Prompt, mit Argument wird der Rest der Zeile als Bedingung übernommen | `<leader>daB` (dort immer Prompt via `lib.nvim.ui.kit`) |
| `:Dap log-point [message...]` | `dap.set_breakpoint(nil, nil, message)` — ohne Argument Prompt, sonst Rest der Zeile als Message | `<leader>daL` (dort immer Prompt) |
| `:Dap list-breakpoints` | `dap.list_breakpoints()` | `<leader>dal` |
| `:Dap toggle-ui` | `ui().toggle()` (aktiver Provider, Default `dap-view`) | `<leader>dau` |
| `:Dap eval` | `ui().eval()` | `<leader>dae` (n und v) |
| `:Dap repl` | `dap.repl.open()` | `<leader>daR` |

## Unterschied zu den Keymaps bei Breakpoint-Argumenten

Die Commands (`conditional-breakpoint`, `log-point`) können ihr Argument
direkt in der Kommandozeile mitgeben (`ctx.rest` aus dem Composer) und fragen
nur bei fehlendem Argument interaktiv nach. Die Keymaps `<leader>daB`/`<leader>daL`
fragen dagegen **immer** interaktiv (`lib.nvim.ui.kit.input`), unabhängig von
irgendwelchen Argumenten — ein direkter, nicht-interaktiver Aufruf ist über
die Keymaps gar nicht möglich, nur über die Commands.
