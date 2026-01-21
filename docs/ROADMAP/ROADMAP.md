# WKD Neovim Roadmap

## Table of content

- [WKD Neovim Roadmap](#wkd-neovim-roadmap)
  - [Table of content](#table-of-content)
  - [Watch](#watch)
  - [Important](#important)
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

-

:lua vim.cmd('profile start /tmp/profile.log') vim.cmd('profile func *') require('lib')
## MIXED

1. Usercommands so strukturieren:
    - `:DeleteCurrentFile` zu `:File delete`; `:Fileinfo` zu `File info`; Weiters `File rename;convert;`
    - ein usercommand, das alle emojis entfernt im buffer: `:Buffer remove emojis` `:Buffer remove empty_lines` `:Buffer translate de` `:Buffer translate_replace en ` `:Buffer insert ...`
2.`lsp.tools.lsp_signature_tool` -> `/doc/lsp_signature_tool.txt` erstellen
3. lsp.tools behandeln
4. usrcmds.ui: Zukünftige Features
        - [ ] Theme-Previews in Floating Window
        - [ ] Theme-Export/Import
        - [ ] Custom Theme-Collections
        - [ ] Theme-Scheduler (basierend auf Tageszeit)
5. `:CwdHere` fixen
6. "a" in neotree scheint nicht mehr ganz typsiereungen ezuer rstellen
7.--

## Neotest

1. neotest [lernen]()
2. `config.neotest.commands`
    - ein zentrales :Neotest-Command mit Subcommands bauen
    - Telescope-Integration (:Telescope neotest)
    - Neo-tree Actions direkt auf diese Commands mappen
3. ein einziges :Neotest Dispatcher-Command bauen oder Neo-tree Kontextmenü-Actions direkt an diese UserCommands binden
4. `config.neotest.neotree` einbinden in neotree

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
