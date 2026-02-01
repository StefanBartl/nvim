# WKD Neovim Roadmap

## Table of content

- [WKD Neovim Roadmap](#wkd-neovim-roadmap)
  - [Watch](#watch)
  - [Important](#important)
  - [MIXED](#mixed)
  - [UI](#ui)
  - [Neotest](#neotest)
  - [`custom.format.text_width`](#customformattext_width)
  - [ideas](#ideas)
  - [Long run](#long-run)

---

## Watch

---

## Important

---

## MIXED

1. Usercommands so strukturieren:
    - `:DeleteCurrentFile` zu `:File delete`; `:Fileinfo` zu `File info`; Weiters `File rename;convert;`
    - ein usercommand, das alle emojis entfernt im buffer: `:Buffer remove emojis` `:Buffer remove empty_lines` `:Buffer translate de` `:Buffer translate_replace en ` `:Buffer insert ...`
2. lsp.tools behandeln
3. wkdnvchad.ui.usrcmd: Zukünftige Features
        - [ ] Theme-Previews in Floating Window
        - [ ] Theme-Export/Import
        - [ ] Custom Theme-Collections
        - [ ] Theme-Scheduler (basierend auf Tageszeit)
4. `:CwdHere` fixen
5. "a" in neotree scheint nicht mehr ganz typsiereungen ezuer rstellen
6. `:LuaFileStats` eine option machen, die keine file erzeugt sondern nur eine ausgabe im stdout/noify
7. `leader fg` soll nicht zuerst eine prompt haben, sondern gleich den picker aufmachen.
    - jeder buchstabe ist in der trefferliste eingetragen
    - Was siond die stats neben der prompt? weeenn ich `nvim_set_current_win` eingebe steht 2871/6343649
8. `sessions` überarbeiten
9. `Recommender`
    - so machen, dass ein telescope oder ein selection aufgemacht wird, und dort kann man dann aussuchen ,welche auf einmal angewandt werden

--

## UI

Implementieren in `:UI` sowie auch als config
- `autocmds.auto-center-fexplorer` (hat aber eigentlcih nichts mitr nvchad ui zu tun, also eigene oder wkdoptions/ui/config)

- `:UI` -> `:NvChadUI` / `:WKDUI`--> `:UI NvChad bzw :UI WKD`


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

--

## ideas

---

## Long run

- `editor_interface` verwenden, um funktionen, die sowohl mappings als auch usercommands begründen.
- autocmds fokussieren, so dass sie sich die durchgänge teilen
- workspace lsp warnings debuggen
    . Todo Coments anschauen und durchgehen
- probieren nvchad rauszunehmen und nochmal mit lazyvim
- experimental options:
- [nvim install doc](./NVIM-Install Doc/install_notes.md) fertig aufteilen
-- WKDBook lua und Neovim mit Notes zusammenführen

---
