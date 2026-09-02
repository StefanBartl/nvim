# nvim-dap-view — User-Commands

**Repo:** `igorlfs/nvim-dap-view` — der Stamm `DapView` löst normalisiert auf
`nvim-dap-view` auf; die Zeile steht hier, weil das Blatt neu ist und die
Zuordnung damit ohne Nachrechnen lesbar ist.

Alle elf Commands sind **[default]**, registriert in `plugin/dap-view.lua`
des Plugins. Diese Config registriert keinen eigenen — sie erreicht dieselben
Funktionen über den Wrapper `StefanBartl/dap.nvim`, siehe
[Usercmds/Dap.md](./Dap.md) und [Keymaps/Dap.md](../Keymaps/Dap.md).

nvim-dap-view ist der **UI-Provider** dieser Config für Debugging: das
Fenster mit Scopes, Watches, Breakpoints, Threads und der REPL. Der Wrapper
kann zwischen ihm und `rcarriga/nvim-dap-ui` umschalten; die Commands hier
gehören nur zum ersteren.

## [default] Fenster und Sichten

| Command | Wirkung |
|---|---|
| `:DapViewOpen` | Das dap-view-Fenster öffnen. |
| `:DapViewClose[!]` | Schließen. Mit `!` auch das Terminal-Fenster. |
| `:DapViewToggle[!]` | Umschalten; `!` wie oben. |
| `:DapViewShow {sicht}` | Direkt zu einer Sicht springen (`watches`, `scopes`, `exceptions`, `breakpoints`, `threads`, `repl`, `console`). |
| `:DapViewNavigate {richtung}` | Zwischen den Sichten blättern, statt eine zu benennen. |

## [default] Werte ansehen und beobachten

| Command | Wirkung |
|---|---|
| `:DapViewHover [ausdruck]` | Wert unter dem Cursor (oder des Ausdrucks) in einem Float. |
| `:DapViewWatch [ausdruck]` | Ausdruck in die Watch-Liste aufnehmen. Ohne Argument das Wort unter dem Cursor. |
| `:DapViewJump [sicht]` | In die Sicht springen **und** den Fokus dorthin setzen — der Unterschied zu `:DapViewShow`, das die Sicht nur wechselt. |

## [default] Virtual Text

Nicht zu verwechseln mit den gleichnamigen Commands von
`nvim-dap-virtual-text` — das ist ein anderes Plugin mit eigenen Commands,
siehe [DapVirtualText.md](./DapVirtualText.md). Diese drei steuern die
**eingebaute** Inline-Anzeige von dap-view.

| Command | Wirkung |
|---|---|
| `:DapViewVirtualTextEnable` | Inline-Werte im Quelltext einblenden. |
| `:DapViewVirtualTextDisable` | Ausblenden. |
| `:DapViewVirtualTextToggle` | Umschalten. |

## Warum dieses Blatt jetzt entstanden ist

Es gehört zu dem Block, den die Stamm-Auflösung sichtbar gemacht hat: im
Standardlauf sind diese elf Commands unsichtbar, weil dap-view lazy ist und
`:Bindings check` das Blatt dann überspringt. Lädt man das Plugin, stehen sie
als undokumentiert im Bericht. Die Regel dafür steht in
[Overview.md](./Overview.md) — Debugging ist ein Arbeitsablauf, also ein
Blatt.
