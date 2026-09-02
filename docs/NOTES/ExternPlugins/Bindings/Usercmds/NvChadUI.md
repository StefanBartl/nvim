# nvchad/ui — User-Commands

Zwei Quellen: die Upstream-Plugin-Commands aus (der lokal überschriebenen)
`nvchad.au` sowie die eigene Theme-/Transparenz-Steuerung in
[lua/wkdnvchad/usrcmd/](../../../../../lua/wkdnvchad/usrcmd). Registriert über
[lua/chadrc.lua](../../../../../lua/chadrc.lua) → `require("wkdnvchad").setup({ all = true })`
→ [lua/wkdnvchad/init.lua](../../../../../lua/wkdnvchad/init.lua) →
`require("wkdnvchad.usrcmd").setup()`.

## [default] Aus dem Plugin selbst

| Command | Quelle | Wirkung |
|---|---|---|
| `:MasonInstallAll` | [lua/nvchad/au.lua](../../../../../lua/nvchad/au.lua) (lokale Override-Kopie von `nvchad/au.lua`, siehe [Autocmds/NvChadUI.md](../Autocmds/NvChadUI.md)) | `require("nvchad.mason").install_all()` — installiert alle in NvChad-Config referenzierten Mason-Pakete. |
| `:Nvdash` | `lazy/ui/lua/nvchad/init.lua` | Toggle des NvChad-Dashboards: ist es offen (`vim.g.nvdash_displayed`), schließt `tabufline.close_buffer` seinen Buffer, sonst öffnet `nvchad.nvdash.open()`. |
| `:NvCheatsheet` | `lazy/ui/lua/nvchad/init.lua` | Toggle des NvChad-Cheatsheets: ist es offen (`vim.g.nvcheatsheet_displayed`), `:bw`, sonst `require("nvchad.cheatsheet." .. config.cheatsheet.theme)()`. Das Theme kommt aus `chadrc`. |

Beide Toggles sind **nicht** gebunden — es gibt in dieser Config keine Taste
für `:Nvdash` oder `:NvCheatsheet`; sie sind nur über die Command-Zeile
erreichbar.

Eine Namensnotiz, die beim Prüfen aufgefallen ist: das Repo heißt bei
lazy.nvim schlicht `ui` (`NvChad/ui`), dieses Blatt heißt `NvChadUI`. Die
Eigentümerspalte von `:Bindings check` nennt für die beiden folglich `ui`,
und kein Auflösungsschritt verbindet die zwei Namen automatisch — dieselbe
Stamm-gegen-Reponame-Frage, die auch `Telescope` → `telescope.nvim` und
`NeoTree` → `neo-tree.nvim` betrifft.

## [custom] `:UI` — Runtime-UI-Kontrolle

Registriert in [lua/wkdnvchad/usrcmd/init.lua](../../../../../lua/wkdnvchad/usrcmd/init.lua)
via `lib.nvim.bindings.usercmd.create` (dieselbe Composer-Basis wie z. B. `:Harpoon`).
Hier war kürzlich der E174-Bug ("command already exists") in `usercmd.create`
betroffen — der Fix dort erzwingt jetzt `force = true` als Default, damit ein
Reload (z. B. durch den `ReloadNvChad`-Autocmd, s. o.) das Command nicht mehr
gegen sich selbst kollidieren lässt.

Dispatcher-Command mit `nargs = "*"` und Tab-Completion pro Subcommand:

| Aufruf | Wirkung |
|---|---|
| `:UI` | Zeigt Hilfetext (Alias für `:UI help`). |
| `:UI transparency [on\|off]` | Transparenz umschalten/setzen (`base46.toggle_transparency`). Ohne Argument: Toggle. |
| `:UI theme` | Aktuelles Theme anzeigen (aus `chadrc.base46.theme`). |
| `:UI theme <name>` | Theme setzen — validiert gegen `base46.themes` (Fallback: fest kodierte Liste, falls Modul nicht ladbar), rekompiliert alle Highlights (`base46.load_all_highlights()`) und persistiert den neuen Namen zurück in `chadrc.lua` (Text-Ersetzung der `theme = "..."`-Zeile, async via `vim.schedule`). |
| `:UI themes` | Alle verfügbaren Themes auflisten, aktuelles mit `✓` markiert. |
| `:UI toggle` | Zwischen den in `chadrc.base46.theme_toggle` konfigurierten Themes wechseln (braucht ≥ 2 Einträge). |
| `:UI status` | Kompakte Status-Box: aktuelles Theme, Transparenz-Status, Toggle-Liste. |
| `:UI help` | Formatierte Hilfe-Box mit allen Subcommands. |

Completion: erstes Argument = Subcommand-Liste, zweites Argument kontext-
abhängig (`on`/`off` für `transparency`, Theme-Namen für `theme`).

## [custom] `:Theme` — Shortcut

| Aufruf | Entspricht |
|---|---|
| `:Theme [name]` | `:UI theme [name]` — `nargs = "?"`, Completion direkt über `theme.list_themes()`. |

## Persistenz-Hinweis

`:UI theme`/`:Theme`/`:UI toggle` schreiben den neuen Themennamen zurück in
[lua/chadrc.lua](../../../../../lua/chadrc.lua) (simple String-Ersetzung, kein
AST-Parser) — schlägt das fehl (Datei nicht gefunden, kein `theme = "..."`-Match),
bleibt die Änderung nur für die laufende Session aktiv und es kommt eine
Warnung.
