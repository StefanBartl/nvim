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

Ein anderer Ort geht über `state_file` im selben Block (`persist = true,
state_file = "~/…/sticky.json"`): `~` und `$VAR` werden aufgelöst, ein relativer
Pfad wird beim `setup` am aktuellen Verzeichnis verankert (ein späteres `:cd`
verschiebt die Datei nicht). Einen selbst gesetzten Pfad überschreibt/löscht das
Plugin nur, wenn er leer ist oder schon eine State-Datei dieses Plugins enthält
(nur die Schlüssel `max_level` und `lines`); eine Config-Datei, ein Ordner oder
andere JSON bleibt unberührt, es gibt eine Warnung, und der Wert gilt nur für die
Session. Am Standardpfad (dem eigenen Ordner des Plugins) wird jede reguläre
Datei ersetzt.

## Notes

- **Ein gespeicherter Wert schlägt die Config, bis `reset`.** Wer in
  `ui_statusline/init.lua` `max_lines` ändert und keinen Effekt sieht, findet in
  `:UI sticky status` den Override, der es verdeckt.
- Eine fehlende, kaputte oder unsinnige Datei (Tiefe außerhalb 1..6, negatives
  oder nicht endliches Limit, größer als 16 KiB, mehr als 64 Filetypes) wird beim
  Lesen ignoriert, nicht gemeldet; am Standardpfad ersetzt sie das nächste
  `depth`/`lines` oder `reset`.
- Die Bestätigung von `depth`/`lines` und `:UI sticky status` sagen „saved“ nur,
  wenn wirklich geschrieben wurde; sonst „this session only, saving failed“ (mit
  Warnung), und `:checkhealth ui` meldet es als Warnung.
- `:UI sticky lines inf` gilt als unbegrenzt (`0`); JSON kann `inf` nicht
  speichern, deshalb steht `0` in der Datei.
- Mehrere Neovim-Instanzen teilen sich die eine Datei; der zuletzt geschriebene
  Wert gewinnt, und eine Instanz behält, was sie bei ihrem Start gelesen hat.
- `:checkhealth ui` zeigt, wohin gespeichert wird (der aufgelöste Pfad) und was
  gerade gesetzt ist.
- Zustand vom 2026-09-21: kein Filetype-Schalter (`exclude_filetypes` und der
  globale Toggle reichen), Winbar (lsp.nvims eigener Breadcrumb, Markdown per
  `winbar.max_symbols = { markdown = 1 }` auf eine Heading gekürzt) und Overlay
  bleiben nebeneinander, Lambdas/Closures in Java/C#/Rust/Kotlin werden nicht
  gepinnt.
