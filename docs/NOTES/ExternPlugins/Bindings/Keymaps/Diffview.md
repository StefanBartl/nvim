# Diffview — Keymaps

Zwei Quellen:

1. Config-eigene Maps zum Öffnen/Schließen der Ansicht — registriert im
   Lazy-Spec [lua/plugins/git.lua](../../../../../lua/plugins/git.lua)
   (`sindrets/diffview.nvim`, `config = true`) und in
   [lua/bindings/mappings/git.lua](../../../../../lua/bindings/mappings/git.lua).
2. Die Maps **innerhalb** einer offenen Diffview (Dateibaum, Diff-Fenster,
   History-Panel, …) — vollständig durch das Plugin selbst gesetzt. Der
   Plugin-Spec ruft `config = true` auf, also `require("diffview").setup({})`
   **ohne** eigene `keymaps`-Overrides — `disable_defaults` bleibt `false`.
   Alle Einträge in Abschnitt 2 sind daher **[default]**, direkt aus
   `nvim-data/lazy/diffview.nvim/lua/diffview/config.lua`
   (`M.defaults.keymaps`) übernommen.

---

## 1. Maps zum Öffnen/Schließen (config-eigen)

| Mapping | Aktion | = Command | Status |
|---|---|---|---|
| `<leader>dv` | Diffview öffnen | `:DiffviewOpen` | [custom] |
| `<leader>dc` | Diffview schließen | `:DiffviewClose` | [custom] |
| `<leader>dh` | File-History-Panel öffnen | `:DiffviewFileHistory` | [custom] |
| `<Leader>dt` | Diff für alle Fenster im aktuellen Tab an/aus (`windo diffthis`/`diffoff`) | — (kein Diffview-eigener Command, nutzt natives `:diffthis`/`:diffoff`) | [custom] |

Alle vier sind einfache `map("n", …)`-Aufrufe in
`bindings/mappings/git.lua` (`M.setup`), ohne which-key-Spec-Tabelle wie bei
Harpoon — die Beschreibungen kommen direkt aus dem `desc`-Feld der Maps.

---

## 2. Maps innerhalb der Diffview (Plugin-Default)

### `view` — aktiv in den Diff-Buffern, wenn der aktuelle Tab eine Diffview ist

| Taste | Aktion | Status |
|---|---|---|
| `<Tab>` / `<S-Tab>` | Diff der nächsten/vorherigen Datei öffnen | [default] |
| `[F` / `]F` | Diff der ersten/letzten Datei öffnen | [default] |
| `gf` | Datei im vorherigen Tabpage öffnen | [default] |
| `<C-w><C-f>` | Datei in neuem Split öffnen | [default] |
| `<C-w>gf` | Datei in neuem Tabpage öffnen | [default] |
| `<leader>e` | Fokus auf das Datei-Panel | [default] |
| `<leader>b` | Datei-Panel togglen | [default] |
| `g<C-x>` | Layout zyklisch wechseln | [default] |
| `[x` / `]x` | Im Merge-Tool: vorherigen/nächsten Konflikt anspringen | [default] |
| `<leader>co` / `<leader>ct` / `<leader>cb` / `<leader>ca` | Konflikt: OURS/THEIRS/BASE/ALL wählen | [default] |
| `dx` | Konfliktregion löschen | [default] |
| `<leader>cO` / `<leader>cT` / `<leader>cB` / `<leader>cA` | Konflikt: OURS/THEIRS/BASE/ALL für die gesamte Datei wählen | [default] |
| `dX` | Konfliktregion für die gesamte Datei löschen | [default] |
| Fold-Commands (`zo`/`zc`/`za`/`zR`/`zM`, kompatibel) | Standard-Fold-Verhalten | [default] |

### `diff1` / `diff2` / `diff3` / `diff4` — je nach Layout

| Taste | Kontext | Aktion | Status |
|---|---|---|---|
| `g?` | alle | Hilfe-Panel öffnen | [default] |
| `2do` | diff3/diff4 | Hunk von OURS übernehmen | [default] |
| `3do` | diff3/diff4 | Hunk von THEIRS übernehmen | [default] |
| `1do` | diff4 | Hunk von BASE übernehmen | [default] |

### `file_panel` — Dateibaum-Panel

| Taste | Aktion | Status |
|---|---|---|
| `j` / `<Down>`, `k` / `<Up>` | Nächster/vorheriger Eintrag | [default] |
| `<CR>` / `o` / `l` / `<2-LeftMouse>` | Diff für gewählten Eintrag öffnen | [default] |
| `-` / `s` | Eintrag stagen/unstagen | [default] |
| `S` / `U` | Alles stagen / unstagen | [default] |
| `X` | Eintrag auf Zustand der linken Seite zurücksetzen | [default] |
| `L` | Commit-Log-Panel öffnen | [default] |
| `zo`/`h`/`zc`/`za`/`zR`/`zM` | Fold expand/collapse/toggle/all | [default] |
| `<C-b>` / `<C-f>` | Ansicht hoch/runter scrollen | [default] |
| `<Tab>` / `<S-Tab>`, `[F` / `]F` | Nächste/vorherige bzw. erste/letzte Datei | [default] |
| `gf`, `<C-w><C-f>`, `<C-w>gf` | Datei öffnen (vorheriger Tab / Split / neuer Tab) | [default] |
| `i` | Zwischen „list“- und „tree“-Ansicht wechseln | [default] |
| `f` | Leere Unterverzeichnisse in Tree-Ansicht flach darstellen | [default] |
| `R` | Datei-Liste aktualisieren | [default] |
| `<leader>e` / `<leader>b` | Fokus Datei-Panel / Datei-Panel togglen | [default] |
| `g<C-x>` | Layout wechseln | [default] |
| `[x` / `]x` | Vorheriger/nächster Konflikt | [default] |
| `g?` | Hilfe-Panel | [default] |
| `<leader>cO`/`cT`/`cB`/`cA`, `dX` | Konflikt für gesamte Datei wählen/löschen | [default] |

### `file_history_panel` — Datei-Historie

| Taste | Aktion | Status |
|---|---|---|
| `g!` | Options-Panel öffnen | [default] |
| `<C-A-d>` | Eintrag unter Cursor in eigener Diffview öffnen | [default] |
| `y` | Commit-Hash unter Cursor kopieren | [default] |
| `L` | Commit-Details anzeigen | [default] |
| `X` | Datei auf Zustand des gewählten Eintrags zurücksetzen | [default] |
| Navigation/Fold/Split-Maps | wie im `file_panel` (`j`/`k`/`<CR>`/`o`/`l`, Folds, `<Tab>`/`<S-Tab>`, `gf`, …) | [default] |
| `<leader>e` / `<leader>b` / `g<C-x>` | Fokus/Toggle/Layout wie oben | [default] |
| `g?` | Hilfe-Panel | [default] |

### `option_panel`

| Taste | Aktion | Status |
|---|---|---|
| `<Tab>` | Aktuelle Option wechseln | [default] |
| `q` | Panel schließen | [default] |
| `g?` | Hilfe-Panel | [default] |

### `help_panel`

| Taste | Aktion | Status |
|---|---|---|
| `q` / `<Esc>` | Hilfe-Menü schließen | [default] |

---

Deaktivierbar insgesamt über `keymaps.disable_defaults = true` im
Diffview-`setup()` — in dieser Config nicht gesetzt (`config = true`, keine
Opts-Overrides).
