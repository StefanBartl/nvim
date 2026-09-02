# nvim-puppeteer — User-Commands

**Repo:** `chrisgrieser/nvim-puppeteer` — der Stamm `Puppeteer` löst
normalisiert auf `nvim-puppeteer` auf.

Alle drei Commands sind **[default]**, registriert in
`plugin/puppeteer-autocmds.lua` des Plugins. Diese Config registriert keinen
eigenen und konfiguriert nichts: der Spec ist
`{ "chrisgrieser/nvim-puppeteer", lazy = false }`
([lua/plugins/editing.lua](../../../../../lua/plugins/editing.lua)).

## Was das Plugin tut

Es wandelt Strings automatisch in Template-Strings um, sobald man eine
Interpolation hineinschreibt — und wieder zurück, wenn man sie entfernt. In
JavaScript/TypeScript werden `"…"` zu `` `…` ``, sobald `${` auftaucht; für
Python (f-Strings), Ruby, Bash und Lua gilt dasselbe Prinzip. Es läuft über
Autocmds, ohne Keymap und ohne Aufruf.

Genau deshalb sind die drei Commands überhaupt interessant: sie sind der
einzige Weg, das Verhalten abzuschalten, wenn es einmal im Weg ist.

## [default] Alle drei

**Alle drei wirken buffer-lokal** (`vim.b.puppeteer_enabled`), nicht global —
abschalten gilt für den aktuellen Buffer, nicht für die Session.

| Command | Wirkung |
|---|---|
| `:PuppeteerDisable` | `vim.b.puppeteer_enabled = false` für den aktuellen Buffer, plus eine Notify „Disabled". |
| `:PuppeteerEnable` | Dasselbe mit `true`. |
| `:PuppeteerToggle` | Kippt den Wert. Ein Buffer, in dem noch nie etwas gesetzt wurde (`nil`), gilt als **aktiviert** — der erste Toggle schaltet also ab. |

## Keine Keymaps

nvim-puppeteer bindet nichts, und diese Config bindet nichts darauf. Es gibt
folglich kein `Keymaps/Puppeteer.md`, und das ist kein Versäumnis.
