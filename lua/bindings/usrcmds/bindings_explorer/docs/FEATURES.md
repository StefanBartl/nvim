# bindings-explorer — Features

`:Bindings` — Picker über die eigenen BINDINGS-Cheatsheets
(`docs/NOTES/PersonelPlugins/BINDINGS/` + `docs/NOTES/ExternPlugins/Bindings/`,
137 Dateien, drei Kategorien: Keymaps/Usercmds/Autocmds).
Vimdoc: `:help bindings_explorer` (siehe [`doc/bindings_explorer.txt`](../doc/bindings_explorer.txt)).
Diese Datei ist die aktuelle Doku — der ursprüngliche Konzept-Entwurf unter
`docs/ROADMAP/personal/bindings-explorer.nvim.md` wurde beim Aufräumen der
Roadmap gelöscht (Feature ist längst umgesetzt, Phase 1–3 alle fertig).

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

## Drift-Bericht (`:Bindings check`)

`:Bindings check [plugin]`

Read-only, kein Autofix (gleiche Haltung wie casedesks `:Cases doctor`) —
vergleicht dokumentierte Personal-Bindings gegen das, was gerade tatsächlich
registriert ist (`vim.api.nvim_get_keymap`/`nvim_get_commands`).
`drift.lua` parst dafür `records.lua`s Tabellenzeilen weiter: die lhs-Zelle
wird über `nvim_replace_termcodes` in die rohe Byte-Form gebracht (dieselbe
Form, die `nvim_get_keymap`s `.lhsraw`-Feld liefert — `<leader>` wird dabei
mit dem tatsächlichen `mapleader` expandiert), Usercmd-Zellen über ein
`:(%u[%w_]*)`-Pattern auf den Basisbefehl reduziert.

Bewusst eingeschränkter Scope (siehe `drift.lua`s Moduldoc für die volle
Begründung):

- **Keymaps: nur eine Richtung** (dokumentiert-aber-nicht-live). Die
  Rückrichtung würde gegen JEDEN globalen Keymap abgleichen (jedes Plugin,
  jeder Vim-Default) und wäre Rauschen ohne Ende.
- **Nur Personal, nicht Extern** — Extern dokumentiert fremde
  Plugin-Defaults, die dieses Config selbst meist nie registriert.
- **Buffer-lokale/filetype-gescopte Keymaps sind ein bekannter
  False-Positive-Fall**: `nvim_get_keymap` sieht nur globale Maps. UI-Plugins
  mit eigenem Buffer (filetree.nvim, github_stats.nvim, pickers.nvim, ...)
  tauchen deshalb systematisch als "missing" auf, obwohl sie korrekt
  registriert sind — manuell verifizieren, nicht blind vertrauen.
- **Noch nicht geladene Plugins werden übersprungen, nicht fälschlich als
  fehlend gemeldet**: `records.lua`s `plugin`-Feld wird gegen
  `require("lazy.core.config").plugins[name]._.loaded` geprüft; ein
  Plugin, das lazy.nvim in dieser Session noch nicht geladen hat, wird
  namentlich als "skipped" aufgeführt statt Falschalarme zu erzeugen.
  Empirisch wichtig: in einer frisch gestarteten Session war das kein
  Randfall — die Mehrheit der Personal-Keymaps-Plugins war noch ungeladen.
- **Usercmds: beide Richtungen**, da `nvim_get_commands({})` nie
  Vim-Defaults enthält (kein Rauschen von dort). Die Rückrichtung
  (live-aber-undokumentiert) zieht zur Rauschreduktion auch Extern-Doku
  heran, zeigt aber weiterhin Infra-/Plugin-Manager-Commands (`:Lazy`,
  `:Mason`, ...) an, für die keine Ignore-Liste gepflegt wird.

Gegen den echten, voll geladenen Bestand verifiziert (headless, über einen
`XDG_CONFIG_HOME`-Junction-Trick, der `stdpath("config")` auf diesen
Branch zeigen lässt, ohne `stdpath("data")`/die echten Plugin-Installationen
anzufassen — siehe git-Historie dieser Datei für die Kommandos): fand u.a.
`Usercmds/dap.nvimMERGE.md`s bereits in `BINDINGS-FORMAT.md` §5 als
Merge-Artefakt vermuteten `:Dap` und ein verwaistes `:LibLogger` in
`lib.nvim.md`.

Beispiele:

```vim
:Bindings check
:Bindings check images.nvim
```
