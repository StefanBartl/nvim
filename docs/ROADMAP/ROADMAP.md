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

1. find_config: fg soll nicht zuerst einen promotpt machen, sondern einfach live grep im config
2. find config soll path separators unenmofnlvh seion
3. ein usercommand, das alle emojis entfernt im buffer
4. neotest [lernen]()
5. `lsp.tools.lsp_signature_tool` -> `/doc/lsp_signature_tool.txt` erstellen
6. lsp.tools behandeln
7. `C:\Users\bartl\AppData\Local\nvim\lua\lib\notify`.safe() eininden

- In die wichtigsten picker wie zb leader fc oder leader leade ein mapping einbauen, dass eine neue file im ordner der trefferfile erstellt-
- new Reload module
- usrcmds.ui: Zukünftige Features
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

