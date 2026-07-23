# Roadmap

   Warn  3:37:11 PM notify.warn [filetree.pdf] pdfport.nvim not installed — opening PDF in system viewer


- nivm.ui.kit die buttons prompt ist cool, das würde ichgerne bei allen prompts haben, bei der man selection machen kann, alsoeigentlich alle select auf button variante umstellen, außer es gibt mehr als 4 selcts, denn dann würde se viele buttons geben
-  Könnte es nicht eine "neue art" software sein, alle meine nvim plugins entweder mit oder ohne einer nvim instanz gemeinesam bündeln und als bnary ausgheben, so das s man es wieder wie normales nvim aber halt mit + verewnden kann.

* [ ] Inline-Images in Markdown-Files einbinden: snacks?
  - checken, ob mit Snacks/image.nvim es nicht möglich ist, images zu öffnen
- [ ] `github_stats.nvim` besser machen
- [ ] `migrate.nvim` fertigstellen
- [ ] `learn-cli.nvim` vielleicht doch ?
- [ ] `lua/config/menu` nach `lua/wkdnvchad`?
- [ ] beim öffnen einer derzeit über `harpoon` aktualisiert `filetree.nvim` den filetree noch nicht `cwd_sync`
- [ ] `nvim/lua/autocmds` analysieren

## Table of content

  - [ZIEL](#ziel)
  - [High](#high)

---

## ZIEL

1. ROADMAP.md durchgehen
2. Alle plugin fähigen Module augliedern
3. Funktionen/Module/ganze Custom Plugins, die man mit ffi über vc performanter machen könnte?
  1.  Eventuell wie eine zweite runtime alle sinnvollen plugins darin laufen lassen, die mit nvim gemeinsam gestartet wir Eventuell wie eine zweite runtime alle sinnvollen plugins darin laufen lassen, die mit nvim gemeinsam gestartet wirdd
4. `BINDINGS.lua`: In der Descrtiptionder Keymaps und Usrcmds: Das plugin selbst nicht nennen,, wie zb.: "[iletree]:" in fileteree.nvim keymap descreiption
5. `/autcmds`
  1. passt zu `/bindings` ?
  2. autocmds aller folder zusammen in einer /autcmd und dort dann korrekte anordnung, also nach events usw,... sodass die performance steigt.
6. Checklisten anwenden
  1. ToDo's duchgehen
7. Branch küren (so wenig commits wit möglch, damit die .git folder nicht groß ist)

---

## High

8. `leader wq`: Alle issues lösen
  1. dass was wq macht in einem `lib.nvim / lib.nvim.ui` ausgeben
9. `/wkdoptions`
  1. UI Linemarker gehört README
  2. `wkdoptions` mit `options.lua` verheiraten (vielleicht als default_options)
10. `nvim/init.lua` durchgehen
11. [ ] Funktionen/Module identifizieren, die man mit FFI/C performanter machen könnte
  - [ ] `/nvim/lua/` – alle Module durchgehen und checken, ob sie irgendwo hineinpassen

---

