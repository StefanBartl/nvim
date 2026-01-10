# WKD Neovim Roadmap

## Table of content

  - [Watch](#watch)
  - [MIXED](#mixed)
  - [neotree](#neotree)
   - [ideas](#ideas)
  - [Long run](#long-run)

---

## Watch

--

## MIXED

- neotest [lernen]()
- `lsp.tools.lsp_signature_tool` -> `/doc/lsp_signature_tool.txt` erstellen
- lsp.tools behandeln
- `:Glow`: `custom.markdown` mappings attachen; default 100% der UI ausfüllen - eventuell toggle.
- `custom,markdown`: `<C-f> / <C-p>` mit [:count] verbinden: `2<C-p>` spingt zum nächsten Level 2 Heading, `4<C-p>` zum letzen Level 4 Heading usw...
- `C:\Users\bartl\AppData\Local\nvim\lua\lib\notify`.safe() eininden
- In die wichtigsten picker wie zb leader fc oder leader leade ein mapping einbauen, dass eine neue file im ordner der trefferfile erstellt-

--

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

--

