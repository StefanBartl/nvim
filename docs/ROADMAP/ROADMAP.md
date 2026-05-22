# WKD Neovim Roadmap

<<<<<<< HEAD
- Fighting Game
- WebAssembly
- nvim-nexus
- Portfolio (mit den nvim plugins, htmx, Zertifikate, fighting game einbinden)

## Table of content

- [WKD Neovim Roadmap](#wkd-neovim-roadmap)
  - [Table of content](#table-of-content)
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

1. toc ??
2. Fehler meldungen mit  ⚠️ versehen; generell notifys aufhübschen
3. chrome debnug adapter -> js debug adapter
4. `custom.insert` nach `usrcmds.isnert` ?
5. trroublke bzw workspacve diagonisc sollen die zeile hervorheben in der man ist
6. `mappings.` nach `.config` refactoren


## MIXED

1. Usercommands so strukturieren:
    - `:DeleteCurrentFile` zu `:File delete`; `:Fileinfo` zu `File info`; Weiters `File rename;convert;`
    - ein usercommand, das alle emojis entfernt im buffer: `:Buffer remove emojis` `:Buffer remove empty_lines` `:Buffer translate de` `:Buffer translate_replace en ` `:Buffer insert ...`
2. lsp.tools behandeln
3. `:CwdHere` fixen
4. "a" in neotree scheint nicht mehr ganz typsiereungen ezuer rstellen
5. `:LuaFileStats` eine option machen, die keine file erzeugt sondern nur eine ausgabe im stdout/noify
6. `leader fg` soll nicht zuerst eine prompt haben, sondern gleich den picker aufmachen.
    - jeder buchstabe ist in der trefferliste eingetragen
    - Was siond die stats neben der prompt? weeenn ich `nvim_set_current_win` eingebe steht 2871/6343649
7. `sessions` überarbeiten
8. `Recommender`
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
=======
1. `nvim-container` really needed or should i disable it? `Arch`?

## Neotree

### `leader fm` - open in file manager

   Warn  9:58:23 AM notify.warn [config.neotree.open.filemanager.win] Open in Explorer: no path under cursor
   Warn  9:58:23 AM notify.warn [cfg.neotree.keymaps.fs.info] Failed to open in file manager

>>>>>>> 5257a2b (custom trouble spell)

---
