# nvim-dap-virtual-text — User-Commands

**Repo:** `theHamsta/nvim-dap-virtual-text` — der Stamm `DapVirtualText` löst
normalisiert auf `nvim-dap-virtual-text` auf.

Vier Commands, alle **[default]**. Sie zeigen beim Debuggen die aktuellen
Variablenwerte als Virtual Text hinter der Quellzeile an — die Anzeige, die
man beim Steppen sieht, ohne ins Scopes-Fenster zu schauen.

## Sie existieren nur, wenn `enable_commands` an ist

Anders als bei den meisten Plugins stehen diese vier **nicht** in einer
`plugin/`-Datei. `nvim-dap-virtual-text.setup()` legt sie zur Laufzeit an, und
nur wenn `options.enable_commands` wahr ist (der Default):

```lua
if options.enable_commands then
  vim.cmd [[
  command! DapVirtualTextEnable :lua require'nvim-dap-virtual-text'.enable()
  ...
  ]]
end
```

Kein Setup, keine Commands — ein Fall der dokumentierten Klasse „lazy, noch
nicht ausgelöst", und zwar eine Stufe tiefer als sonst: hier reicht es nicht,
dass das *Plugin* geladen ist, sein `setup()` muss gelaufen sein.

## [default] Alle vier

| Command | Wirkung |
|---|---|
| `:DapVirtualTextEnable` | Virtual Text einschalten (`require("nvim-dap-virtual-text").enable()`). |
| `:DapVirtualTextDisable` | Ausschalten. |
| `:DapVirtualTextToggle` | Umschalten. |
| `:DapVirtualTextForceRefresh` | Neu zeichnen. Für den Fall, dass der Debug-Adapter sein Ende nicht gemeldet hat und veraltete Werte stehen bleiben — die Plugin-Doku nennt genau diesen Grund. |

## Die Eigentümerspalte sagt hier `vimscript script_id=-8`

Und das ist kein Defekt, sondern der ausdrückliche Rückfall von
`:Bindings check`. Weil die vier über `vim.cmd [[command! …]]` **aus einer
Lua-Funktion heraus** entstehen, gibt es kein gesourcetes Vimscript, dem
Neovim sie zuschreiben könnte; die `script_id` ist negativ und
`vim.fn.getscriptinfo` kann sie nicht auflösen.

Der Bericht druckt dann lieber ein erkennbares Nicht-Ergebnis als einen
geratenen Namen. Diese vier Commands sind der erste echte Beleg dafür, dass
dieser Zweig gebraucht wird — bis dahin war er nur eine Vorsichtsmaßnahme.

## Abgrenzung zu `:DapView…VirtualText…`

`nvim-dap-view` hat eine eigene, gleichnamige Funktion mit den Commands
`:DapViewVirtualTextEnable` / `…Disable` / `…Toggle`
([DapView.md](./DapView.md)). Zwei Plugins, zwei Implementierungen, ähnliche
Namen — wer eine Anzeige nicht loswird, hat womöglich die andere erwischt.
