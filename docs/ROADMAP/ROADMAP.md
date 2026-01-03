# WKD Neovim Roadmap

## Table of content

  - [Watch](#watch)
  - [MIXED](#mixed)
  - [neotree](#neotree)
#   - [ideas](#ideas)
  - [Long run](#long-run)

---

## Watch

- `<C-s>`: Manchmal springt es beim speichern in etwa in die Mitte oder ans Ende oder einen anderen Punk der file

---

## MIXED

- `/docs` schöner formatieren , Rechtschreibung usw...

- neotest [lernen]()

- `lsp.tools.lsp_signature_tool` -> `/doc/lsp_signature_tool.txt` erstellen

- lsp.tools behandeln


## Neotest

-- `config.neotest.commands`
    - ein zentrales :Neotest-Command mit Subcommands bauen
    - Telescope-Integration (:Telescope neotest)
    - Neo-tree Actions direkt auf diese Commands mappen
ein einziges :Neotest Dispatcher-Command bauen
oder Neo-tree Kontextmenü-Actions direkt an diese UserCommands binden

- `config.neotest.neotree` einbinden in neotree

### format sammelmodul

Vercshiedene formatierungs usercommands und keymaps sammeln, zb.:
- `custom.align_colum`:
    * Unterstützung für Multibyte-Zeichen
    * Ausrichtung mehrerer markierter Zeichen
    * Wiederholung der letzten Zielspalte
    * Presets pro Dateityp
    * Integration in Operator-Mappings
    * Multiselect: also mit ctrl-v mehrere start punkt markieren bzw.: echte markierungen und dort werden dann auf einmal alle ausgefphrt

---

## neotree

- enter setzt das au den ordner in der die file ist. kann auch ein M-CR sein oder ähnlich
- [Neotree]() mappings so schreiben, dass auch nvimtree/netrw möglich wäre
    . DAs bedeutet auch, dass alle lib funktionen inerhalb der filtree filesystem ist, danmit keine dependencies entstehen
    I. Die meisten helper sollten eigenltich als commands implementiert werden

---

## ideas

---

## Long run

- `custom.functions` verwenden, um funktionen, die sowohl mappings als auch usercommands begründen.

- workspace lsp warnings debuggen
    1. alle `disable-next-line` durchsehen
    2. Todo Coments anschauen und durchgehen

- probieren nvchad rauszunehmen und nochmal mit lazyvim

- experimental options:
   1. statusline und winbar breadcrumbs sollten sich ein modul teilen

- [nvim install doc](./NVIM-Install Doc/install_notes.md) fertig aufteilen

--

