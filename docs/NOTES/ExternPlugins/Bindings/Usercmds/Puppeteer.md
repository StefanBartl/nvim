# ~~nvim-puppeteer~~ — User-Commands

**Deinstalliert am 2026-09-19.** Was `chrisgrieser/nvim-puppeteer` tat —
`"…"` wird zu `` `…` ``, sobald `${` auftaucht (JS/TS), `"…"` zu `f"…"` bei
`{name}` (Python), und zurück, wenn die Interpolation verschwindet — ist
seitdem cascade.nvims `strings`-Domain (`lua/cascade/strings/`), mit
denselben Guards (leere Literale, > 200 Zeichen, Tagged Templates, `{}`/`{0}`
in Python). Die Lua-Variante (`"%s"` → `("%s"):format()`) ist dort
absichtlich aus (`strings.features.lua_format = false`).

Die drei Puppeteer-Commands hatten genau eine Aufgabe, das Verhalten
buffer-lokal abzuschalten; das übernimmt jetzt ein Subcommand:

| Vorher | Jetzt |
|---|---|
| `:PuppeteerDisable` | `:Cascade strings off` (setzt `b:cascade_strings = false`) |
| `:PuppeteerEnable` | `:Cascade strings on` |
| `:PuppeteerToggle` | `:Cascade strings` / `:Cascade strings toggle` |
| — | `:Cascade strings now` — einmalig am Cursor konvertieren |

Keine Keymaps, wie vorher. Siehe cascade.nvims [`docs/FEATURES/STRINGS.md`]($REPOS_DIR/cascade.nvim/docs/FEATURES/STRINGS.md)
(kein eigenes `Cascade.md` in diesem Ordner).
