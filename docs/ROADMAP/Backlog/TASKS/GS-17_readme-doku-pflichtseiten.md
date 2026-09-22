# GS-17 — README-Doku: Pflichtseiten

**Repo:** gitsuite.nvim · **Nutzen** 3 · **Risiko** niedrig · **Welle** 4
(Dokumentation) · erledigt 2026-09-22.

## Ausgangslage

Das Root-README verwies bereits per Fassung-3-Format (nur `## Documentation`
+ `## License`) auf `docs/`, aber fünf der dort verlinkten Pflichtseiten
(`requirements.md`, `installation.md`, `quickstart.md`, `configuration.md`,
`commands.md`) existierten nicht — der Doku-Abschnitt endete stattdessen mit
einem Platzhaltersatz ("more documentation ... lands next").

## Umsetzung

Alle fünf Seiten nach `TEMPLATES/README-NVIM-PLUGIN/README.template.md`
(Fassung 3) angelegt, jede gegen den echten Code verifiziert statt von einem
Nachbar-README übernommen:

- `requirements.md`: Pflicht- (lib.nvim, diff.nvim, `git`) und
  Optional-Tabelle (gitsigns, diffview, neogit, `lazygit`, `nvr`,
  open.nvim, pickers.nvim), jede Zeile mit dem konkreten Feature, das sie
  trägt bzw. ohne sie ausfällt — aus `health.lua` und den Adapter-Dateien
  gelesen, nicht geschätzt.
- `installation.md`: lazy.nvim/packer.nvim/vim-plug/mini.deps, lazy.nvim-
  Snippet 1:1 aus der echten nvim-Config (`lua/plugins/personal/init.lua`)
  übernommen; erklärt, warum `open.nvim`/`pickers.nvim` bewusst nicht als
  harte `dependencies` gelistet sind.
- `quickstart.md`: `:Git status repo` und `:Git conflict list`/`ours` als
  erste Befehle, `<Tab>`-Vervollständigung erwähnt.
- `configuration.md`: alle vier `setup()`-Schlüssel (`features`, `commands`,
  `keymaps`, `browse`) mit Default, aus `config/DEFAULTS.lua` übernommen.
- `commands.md`: die Composer-Route-Baum-Erklärung (ein Baum treibt
  Dispatch, `<Tab>`-Completion und `BINDINGS.md` zugleich), Verweis auf
  `commands.git` zum Umbenennen.

Root-README aktualisiert: die volle Fassung-3-Doku-Liste (The Basics /
Configuration / The Rest) statt des Platzhaltersatzes, jeder Link gegen
`ls docs/` geprüft.

## Nicht Teil des Plan-Umfangs, aber nötig

`docs/README.md` (Index) und `docs/integrations.md` existierten noch nicht,
wurden aber von der Checkliste selbst verlangt (Index optional 🟢, aber
guter Stil; `integrations.md` **Pflicht** 🔴, sobald
`lua/gitsuite/integrations/` existiert — hier zwei Dateien:
`menu.lua`/`pickers_nvim.lua`). Beide zusammen mit GS-17/GS-18 in einem
Commit ergänzt, siehe [GS-18](GS-18_readme-doku-rest.md) für den Rest.

## Ergebnis

CI grün auf allen drei Systemen. `stylua`/`luacheck` unberührt (kein Lua
geändert). Karte zusammen mit GS-18 in einem Commit umgesetzt, da
`docs/README.md` und das Root-README beide Seiten aus beiden Karten
verlinken.
