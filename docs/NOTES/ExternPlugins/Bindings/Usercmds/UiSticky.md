# ui.nvim Sticky-Context — User-Commands

**Repo:** `StefanBartl/ui.nvim` (`ui.context`) — der Stamm `UiSticky` steht für
den Sticky-Teil des `:UI`-Dispatchers; die Theme-/Transparenz-Subcommands von
`:UI` stehen in [NvChadUI.md](./NvChadUI.md).

Source: `ui.nvim/lua/ui/bindings/usrcmds/init.lua` (`ui_sticky`),
`ui.nvim/lua/ui/context/init.lua`, `ui.nvim/lua/ui/context/state.lua`
Docs: `ui.nvim/docs/configuration.md` (Abschnitt Context), `ui.nvim/docs/BINDINGS.md`

`:UI sticky` (`:UI context` bleibt als älterer Name) steuert das Overlay, das die
umschließenden `function`/`class`/Schleifen-Zeilen — in Markdown die
Heading-Kette, in YAML die Eltern-Schlüssel — über den ersten Zeilen des
Fensters fixiert. Eingeschaltet wird es in
[lua/config/ui_statusline/init.lua](../../../../../lua/config/ui_statusline/init.lua)
über `require("ui").setup({ sticky = { ... } })`; das Feature ist dort
explizit (`all = true` schaltet es nicht ein), `sticky = false` lässt es aus.
Keine Keymaps.

## `:UI sticky`

| Command | Effect |
|---|---|
| `:UI sticky [toggle]` | Overlay für die Session umschalten |
| `:UI sticky on` / `:UI sticky off` | expliziten Zustand setzen |
| `:UI sticky status` | Zustand, Heading-Tiefe, Zeilenlimit; dazu, was per Befehl gesetzt wurde und ob es gespeichert ist |
| `:UI sticky depth [1-6\|all]` | tiefste Markdown-Heading-Ebene, die gepinnt wird (ohne Argument: Anzeige) |
| `:UI sticky lines [ft] [n]` | Zeilenlimit für einen Filetype oder für alle anderen; `0` = unbegrenzt (ohne Argument: Anzeige) |
| `:UI sticky reset` | verwirft, was `depth`/`lines` geändert haben, zurück zu den Werten aus `ui_statusline/init.lua`; löscht die State-Datei |
| `:UI sticky up [n]` | springt zum n-ten umschließenden Scope über dem Fensteranfang (1 = innerster; geht auch bei ausgeschaltetem Overlay) |

`:UI context …` ist derselbe Befehl unter dem älteren Namen. Vervollständigung:
das erste Argument über die Aktionen, danach `1`–`6`/`all` nach `depth` und
Filetypes nach `lines`.

## Was gespeichert wird

In dieser Config steht `persist = true` im `sticky`-Block. Damit schreibt jedes
`depth`/`lines` seinen Wert nach
`stdpath("state")/ui.nvim/sticky.json`
(`C:\Users\bartl\AppData\Local\nvim-data\ui.nvim\sticky.json`) und liest ihn beim
nächsten Start zurück, **über** den Werten aus `ui_statusline/init.lua`.
Gespeichert wird nur, was ein Befehl geändert hat — der Rest bleibt in der
Config.

## Notes

- **Ein gespeicherter Wert schlägt die Config, bis `reset`.** Wer in
  `ui_statusline/init.lua` `max_lines` ändert und keinen Effekt sieht, findet in
  `:UI sticky status` den Override, der es verdeckt.
- Eine fehlende, kaputte oder unsinnige Datei (Tiefe außerhalb 1..6, negatives
  Limit) wird ignoriert, nicht gemeldet; `reset` legt sie sauber neu an.
- `:checkhealth ui` zeigt, wohin gespeichert wird und was gerade gesetzt ist.
- Zustand vom 2026-09-21: kein Filetype-Schalter (`exclude_filetypes` und der
  globale Toggle reichen), Winbar (lspsaga, Markdown auf eine Heading gekürzt)
  und Overlay bleiben nebeneinander, Lambdas/Closures in Java/C#/Rust/Kotlin
  werden nicht gepinnt.
