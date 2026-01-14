# WKD Neovim Roadmap

## Table of content

- [WKD Neovim Roadmap](#wkd-neovim-roadmap)
  - [Watch](#watch)
  - [MIXED](#mixed)
  - [Neotest](#neotest)
  - [`custom.format.text_width`](#customformattext_width)
  - [ideas](#ideas)
  - [Long run](#long-run)

---

## Watch

---

## Important

- `wkddap`: README.md, doc/, docs/, test, Mappings/Usercommands ausbauen usw..
- `lib` konsolidieren, beispiel `lib.cross_plattform` vs. `lib.cross`
- `nf` und `pf` sollen aktuellen buffer erstzen `nF` und `pF` nicht

---

## MIXED

1. ein usercommand, das alle emojis entfernt im buffer
2. neotest [lernen]()
3. `lsp.tools.lsp_signature_tool` -> `/doc/lsp_signature_tool.txt` erstellen
4. lsp.tools behandeln
5. `C:\Users\bartl\AppData\Local\nvim\lua\lib\notify`.safe() eininden
6. `p` funktion im v oder v-line modus: soll zeilennummer und indent des zu überschreibednen (old) einhalten
7. in markdown diles wenn man in einer einer auflistung ist  mit <C-S-f> bbzw <C-S-p> zzwsichen den Punkten springen
8. In die wichtigsten picker wie zb leader fc oder leader leade ein mapping einbauen, dass...
    - eine neue file im ordner der trefferfile erstellt
    - background add und ersetzt aktuellen buffer
9. usrcmds.ui: Zukünftige Features
        - [ ] Theme-Previews in Floating Window
        - [ ] Theme-Export/Import
        - [ ] Custom Theme-Collections
        - [ ] Theme-Scheduler (basierend auf Tageszeit)

---

## Neotest

-- `config.neotest.commands`
    - ein zentrales :Neotest-Command mit Subcommands bauen
    - Telescope-Integration (:Telescope neotest)
    - Neo-tree Actions direkt auf diese Commands mappen
ein einziges :Neotest Dispatcher-Command bauen
oder Neo-tree Kontextmenü-Actions direkt an diese UserCommands binden
- `config.neotest.neotree` einbinden in neotree

## `custom.format.text_width`

1. Limitationen: Hyphenation (geteilt mit -) und komplexe Worttrennungsregeln sind nicht implementiert. Listen- und Bullet-Erkennung ist eine einfache Heuristik: einfache Bullet-Marker wie - , * , + oder 1. werden auf der ersten Zeile beibehalten; Fortsetzungen werden passend eingerückt.
2. Erweiterungen, die man später leicht hinzufügen kann:
    - Bessere List- und Codeblock-Erkennung (z. B. Markdown-Codeblöcke ausschließen).
    - Hyphenation mittels externem Dienst oder Wörterbuch.
    - ? Buffer-locales Autowrap beim Tippen (z. B. über autocmd BufEnter,BufWinEnter + formatoptions oder textwidth während Insert).
    - SUPER: Verbinden mit marksman format + der Idee, dass man in codeblöcken lsp callt

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

---

