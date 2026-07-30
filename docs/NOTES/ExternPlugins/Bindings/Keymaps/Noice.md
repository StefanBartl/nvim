# Noice — Keymaps

Registriert in
[lua/bindings/mappings/noice.lua](../../../../../lua/bindings/mappings/noice.lua)
(aufgerufen aus `bindings.mappings.init`).

`noice.nvim` selbst liefert **keine** eigenen User-Keymaps aus — das Plugin
ersetzt nur die UI für Cmdline/Messages/Popupmenu/LSP-Hover. Alles unten ist
also zwangsläufig **[custom]**, es gibt keine Werkseinstellung, gegen die man
vergleichen könnte.

Die Maps werden **nicht global** gesetzt, sondern buffer-lokal per
`FileType`-Autocmd (Pattern `noice*`) — siehe
[Autocmds/Noice.md](../Autocmds/Noice.md). Sie greifen also nur in den
speziellen Noice-Buffern (z. B. dem LSP-Hover-Float), nicht editorweit.

---

## Buffer-lokal in `noice*`-Buffern

| Mapping | Modi | Aktion | Status |
|---|---|---|---|
| `<A-j>` | n, i, s | LSP-Float 4 Zeilen vorwärts scrollen (Fallback `<c-f>`, falls kein Noice-LSP-Float aktiv) | [custom] |
| `<A-Down>` | n, i, s | dasselbe wie `<A-j>` | [custom] |
| `<A-k>` | n, i, s | LSP-Float 4 Zeilen rückwärts scrollen (Fallback `<c-b>`) | [custom] |
| `<A-Up>` | n, i, s | dasselbe wie `<A-k>` | [custom] |
| `<A-x>` | n, i | UI dismissen (`require("noice").cmd("dismiss")`) | [custom] |

### Bezug zum Noice-README

Noice dokumentiert in seinem README unter "Lsp Hover Doc Scrolling" ein
Beispiel-Snippet, das exakt dasselbe tut (`require("noice.lsp").scroll(delta)`
mit `expr = true`-Fallback auf den plain Scroll-Key), dort allerdings mit
`<c-f>`/`<c-b>` als Tasten. Diese Config übernimmt **das Muster**
(`scroll()`-Wrapper + Fallback), **nicht die Tasten** — `<c-f>`/`<c-b>` sind
hier bereits anderweitig belegt, daher `<A-j/k/Down/Up>`. Für `<A-x>` (Dismiss)
zeigt das README kein Vorbild — der Key ist frei erfunden.

Die eigentliche Lazy-Loading-Absicherung: `require("noice.lsp")` passiert erst
**innerhalb** der Callback-Closures, nie beim `setup()` selbst — sonst würde
das Plugin bei jedem Start force-geladen, nur um Keymaps zu definieren, die
ohnehin erst in einem Noice-Buffer feuern können (siehe Kommentar in der
Quelle).

---

## Außerhalb von Noice-Buffern

Keine. Die Lazy-Spec in
[lua/plugins/ui.lua](../../../../../lua/plugins/ui.lua) definiert nur `cmd`-
Trigger (`Noice`, `NoiceAll`, `NoiceHistory`, `NoiceDismiss`, `NoiceError`),
keine `keys`-Tabelle — d.h. es gibt keinen globalen Keymap, der zu diesen
Commands führt, sie sind nur per `:Noice ...` erreichbar.
