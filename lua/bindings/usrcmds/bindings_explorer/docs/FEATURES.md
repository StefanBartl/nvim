# bindings-explorer — Features

`:Bindings` — Picker über die eigenen BINDINGS-Cheatsheets
(`docs/NOTES/PersonelPlugins/BINDINGS/` + `docs/NOTES/ExternPlugins/Bindings/`,
137 Dateien, drei Kategorien: Keymaps/Usercmds/Autocmds). Konzept & offene
Punkte: [`docs/ROADMAP/personal/bindings-explorer.nvim.md`](../../../../../docs/ROADMAP/personal/bindings-explorer.nvim.md).
Vimdoc: `:help bindings_explorer` (siehe [`doc/bindings_explorer.txt`](../doc/bindings_explorer.txt)).

Module: `lua/bindings/usrcmds/bindings_explorer/` — `init.lua` (Composer-
Verb + Routen), `config.lua` (die zwei BINDINGS-Wurzeln), `search.lua` +
`ui.lua` (Phase 1 Fallback-Suche), `live.lua` (Phase 1 Live-Grep),
`records.lua` + `browse.lua` (Phase 2 Tabellen-Scraper + Picker).

## Volltextsuche (`:Bindings search`)

`:Bindings search [keymaps|usercmds|autocmds] [query]`

Durchsucht beide BINDINGS-Bäume (oder nur eine der drei Unterkategorien)
Zeile für Zeile nach `query`, case-insensitiv. Zwei Backends, automatisch
gewählt:

- **Live-Grep-in-Picker** (bevorzugt): über `pickers.nvim`s Engine-Schicht
  (`pickers.engines.load()` → `engine.live_grep({ roots, prompt, query })`),
  einheitlich über telescope/fzf-lua/snacks hinweg. Tippen filtert live,
  `<CR>` springt an die Fundstelle.
- **Fallback ohne Picker-Engine**: `kit.input` (Prompt für `query`, falls
  keiner mitgegeben wurde) → `kit.select` (statische Trefferliste). Greift
  automatisch, wenn keine Engine/kein ripgrep verfügbar ist.

Beispiele:

```vim
:Bindings search <leader>iv
:Bindings search keymaps redact
:Bindings search usercmds
:Bindings search autocmds BufEnter
```

## Wurzelpfade kopieren (`:Bindings path`)

`:Bindings path [personal|extern]`

Kopiert die BINDINGS-Wurzel(n) in die Zwischenablage — ohne Argument beide,
newline-getrennt. Löst denselben Zweck wie das ältere, separate
`:BindingsPath` (`lua/bindings/usrcmds/init.lua`), aber mit den zwei
tatsächlichen Pfaden statt dessen einzelnem, nie existierenden
`docs/NOTES/BINDINGS`.

```vim
:Bindings path
:Bindings path personal
:Bindings path extern
```

## Tabellenzeilen-Picker (`:Bindings browse`)

`:Bindings browse [keymaps|usercmds|autocmds] [personal|extern]`

Statt Volltext über rohe Zeilen durchsucht `browse` **geparste
Tabellenzeilen**: `records.lua` liest jede Cheatsheet-Datei, findet jede
`|…|…|`-Zeile unter der nächsten `##`/`###`-Überschrift darüber und macht
daraus einen Datensatz —

```lua
{ scope = "Personal"|"Extern",
  category = "Keymaps"|"Usercmds"|"Autocmds",
  plugin,       -- Dateiname ohne Endung, z.B. "images.nvim" oder "Telescope"
  heading,      -- die Überschrift direkt über der Tabelle
  columns,      -- Kopfzeile der Tabelle, Freitext, keine feste Spaltenzahl
  cells,        -- diese Zeile, gleiche Länge wie columns
  file, line }
```

Spaltenzahl/-namen sind bewusst nicht festgeschrieben (siehe
[`docs/NOTES/BINDINGS-FORMAT.md`](../../../../../docs/NOTES/BINDINGS-FORMAT.md)) —
`Keymaps/*.md` hat meist `Key|Mode|Effect|Option`, Extern-Dateien wie
`Telescope.md` bringen mehrere Tabellen unterschiedlicher Form mit. Dateien
ohne saubere Tabelle unter einer Überschrift liefern hier einfach keine
Treffer, bleiben aber über `:Bindings search` weiterhin auffindbar.

`browse.lua`s Picker (`kit.select`, wie Phase 1s Fallback) zeigt jede Zeile
als `[Scope/Plugin] Heading — Spalte1: Wert1  Spalte2: Wert2  ...`; `<CR>`
springt an die Fundstelle in der Quelldatei.

Beispiele:

```vim
:Bindings browse
:Bindings browse keymaps
:Bindings browse keymaps personal
:Bindings browse usercmds extern
```

Gegen den echten Bestand verifiziert (headless, 2026-08-09):
`records.list()` liefert 1641 Datensätze über den ganzen Korpus, davon 414
für `Keymaps personal` allein.

## Noch nicht implementiert

**Phase 3 — Drift-Erkennung** (`:Bindings check [plugin]`): dokumentierte
gegen tatsächlich registrierte Keymaps/Usercmds abgleichen
(`vim.api.nvim_get_keymap`/`nvim_get_commands`). Konzept in
[`docs/ROADMAP/personal/bindings-explorer.nvim.md`](../../../../../docs/ROADMAP/personal/bindings-explorer.nvim.md)
§3, noch nicht gebaut.
