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
- `M-r` indent sind 4 chars, ich will aber nur 1

--

## MIXED

1. Usercommands so strukturieren:
    - `:DeleteCurrentFile` zu `:File delete`; `:Fileinfo` zu `File info`; Weiters `File rename;convert;`
    - ein usercommand, das alle emojis entfernt im buffer: `:Buffer remove emojis` `:Buffer remove empty_lines` `:Buffer translate de` `:Buffer translate_replace en ` `:Buffer insert ...`
2. Bug: `:copy path ...` kopiert immer cwd relativ. idealerweiße eines das "immer relativ zum nvim config cwd wennd dad geht. und ein `Copy path module lua/ts/go/...` das gleich ein import daraus macht
3.`lsp.tools.lsp_signature_tool` -> `/doc/lsp_signature_tool.txt` erstellen
4. lsp.tools behandeln
5-`C:\Users\bartl\AppData\Local\nvim\lua\lib\notify`.safe() eininden
6.`p` funktion im v oder v-line modus: soll zeilennummer und indent des zu überschreibednen (old) einhalten
7. in markdown diles wenn man in einer einer auflistung ist  mit <C-S-f> bbzw <C-S-p> zzwsichen den Punkten springen
8. In die wichtigsten picker wie zb leader fc oder leader leade ein mapping einbauen, dass...
    - eine neue file im ordner der trefferfile erstellt
    - background add und ersetzt aktuellen buffer
9. usrcmds.ui: Zukünftige Features
        - [ ] Theme-Previews in Floating Window
        - [ ] Theme-Export/Import
        - [ ] Custom Theme-Collections
        - [ ] Theme-Scheduler (basierend auf Tageszeit)
10. table of content ebtfernen als option in marksman als code action

---

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
