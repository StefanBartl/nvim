# Gitsigns — Keymaps

Registriert in
[lua/bindings/mappings/git.lua](../../../../../lua/bindings/mappings/git.lua)
(aufgerufen aus `bindings.mappings.init`) sowie in
[lua/wkdoptions/hl_config/features/diff_peek.lua](../../../../../lua/wkdoptions/hl_config/features/diff_peek.lua)
(Feature-Toggle `enable_diff_peek`, Default `true` — siehe
[lua/wkdoptions/config/data/highlight.lua](../../../../../lua/wkdoptions/config/data/highlight.lua)).

**Wichtig:** `gitsigns.nvim` bringt selbst **keine** globalen Default-Keymaps
mit. Der Plugin-Spec ruft nur `config = true` auf
([lua/plugins/git.lua](../../../../../lua/plugins/git.lua)), also
`require("gitsigns").setup({})` ohne `on_attach`-Callback — es wird also
keine der im gitsigns-README dokumentierten `on_attach`-Beispielmaps
(`]c`/`[c`, `<leader>hs`, `<leader>hr`, `<leader>hb`, `ih`, …) tatsächlich
gesetzt. Alle Maps unten sind daher **[custom]** by construction; sie rufen
aber ausschließlich öffentliche Gitsigns-API-Funktionen auf
(`toggle_word_diff`, `toggle_linehl`, `preview_hunk_inline`, `preview_hunk`).

---

## Maps

| Mapping | Aktion | Quelle | Status |
|---|---|---|---|
| `<leader>di` | **ToggleInlineDiff**: invertiert `toggle_word_diff()` + `toggle_linehl()`, danach `preview_hunk_inline()` (Fallback `preview_hunk()`, falls in der installierten Version nicht vorhanden) für den Hunk unter dem Cursor | `bindings/mappings/git.lua` (`M.toggle_inline_diff`) | [custom] |
| `gh` | Git-Hunk-Peek: `preview_hunk_inline()` (Fallback `preview_hunk()`) für den Hunk unter dem Cursor | `wkdoptions/hl_config/features/diff_peek.lua` | [custom] |

Zu `gh`: ist gitsigns beim Setzen der Map nicht ladbar, wird stattdessen ein
Platzhalter-Mapping installiert, das nur eine Notify auslöst
("Diff peek requires gitsigns.nvim") — kein Fehler, aber auch keine Aktion.
Das Feature lässt sich über `enable_diff_peek = false` global abschalten;
dann wird die Map beim nächsten Reload wieder entfernt (`vim.keymap.del`).

---

## Zum Vergleich: von gitsigns.nvim dokumentierte (aber hier NICHT gesetzte) Beispielmaps

Aus der README des installierten Plugins
(`nvim-data/lazy/gitsigns.nvim/README.md`, Abschnitt „Keymaps“) — rein
informativ, da in dieser Config kein `on_attach` konfiguriert ist:

| Vorschlag (README) | Aktion |
|---|---|
| `]c` / `[c` | Zum nächsten/vorherigen Hunk springen (im Diff-Modus: `]c`/`[c` nativ) |
| `<leader>hs` / `<leader>hr` | Hunk stagen / zurücksetzen (auch visuell) |
| `<leader>hS` / `<leader>hR` | Gesamten Buffer stagen / zurücksetzen |
| `<leader>hp` | Hunk-Preview (Popup) |
| `<leader>hi` | Hunk-Preview (inline) |
| `<leader>hb` | Vollständige Blame-Zeile |
| `<leader>hd` / `<leader>hD` | Diff gegen Index / gegen `~` |
| `<leader>hQ` / `<leader>hq` | Alle Hunks / Buffer-Hunks in die Quickfix-Liste |
| `<leader>tb` | `toggle_current_line_blame` |
| `<leader>tw` | `toggle_word_diff` |
| `ih` (o/x) | Textobjekt „Hunk“ |

Keine dieser Maps ist in dieser Config aktiv — sie tauchen hier nur auf, um
Verwechslungen mit den tatsächlich gesetzten `[custom]`-Maps oben zu
vermeiden.
