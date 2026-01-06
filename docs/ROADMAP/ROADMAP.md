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

--

## Neotest

-- `config.neotest.commands`
    - ein zentrales :Neotest-Command mit Subcommands bauen
    - Telescope-Integration (:Telescope neotest)
    - Neo-tree Actions direkt auf diese Commands mappen
ein einziges :Neotest Dispatcher-Command bauen
oder Neo-tree Kontextmenü-Actions direkt an diese UserCommands binden
- `config.neotest.neotree` einbinden in neotree

### insert commands und mappiunmgs sammeln

  - usrcmds.insertfilepath
  - usrcmds.lua_module_annotation

---

### usrcmds.migrate opts und notify mergen

--

## `custom.format.text_width`

1. Limitationen: Hyphenation (geteilt mit -) und komplexe Worttrennungsregeln sind nicht implementiert. Listen- und Bullet-Erkennung ist eine einfache Heuristik: einfache Bullet-Marker wie - , * , + oder 1. werden auf der ersten Zeile beibehalten; Fortsetzungen werden passend eingerückt.
2. Erweiterungen, die man später leicht hinzufügen kann:
    - Bessere List- und Codeblock-Erkennung (z. B. Markdown-Codeblöcke ausschließen).
    - Hyphenation mittels externem Dienst oder Wörterbuch.
    - ? Buffer-locales Autowrap beim Tippen (z. B. über autocmd BufEnter,BufWinEnter + formatoptions oder textwidth während Insert).
    - SUPER: Verbinden mit marksman format + der Idee, dass man in codeblöcken lsp callt

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

