# Roadmap
- pdfport.nvim - pdf erstellings funkiton zb pandoc

- spotlight checken und lernen
- documentation.nvim lernen

Ein zusätzlicher Use-Case, den du nicht genannt hast und der für dich beruflich wahrscheinlich der wertvollste ist: Clipboard-Bild direkt in ein Markdown-File einfügen — Screenshot machen, :Image paste, das Bild landet als Datei neben dem Dokument und der Link wird geschrieben. Für Support-Dokumentation ist das der Alltagsfall schlechthin, und es ist weit einfacher zu bauen als das Renderin

- [ ]  Könnte es nicht eine "neue art" software sein, alle meine nvim plugins entweder mit oder ohne einer nvim instanz gemeinesam bündeln und als bnary ausgheben, so das s man es wieder wie normales nvim aber halt mit + verewnden kann.

  - checken, ob mit Snacks/image.nvim es nicht möglich ist, images zu öffnen
- [ ] `github_stats.nvim` besser machen
- [ ] `learn-cli.nvim` vielleicht doch ?
- [ ] `lua/config/menu` nach `lua/wkdnvchad`?
- [ ] `nvim/lua/autocmds` analysieren
- [ ] finish & checkists & review in nvim config durchjagen

## ZIEL

1. Alle plugin fähigen Module augliedern
2. Funktionen/Module/ganze Custom Plugins, die man mit ffi über vc performanter machen könnte?
  1.  Eventuell wie eine zweite runtime alle sinnvollen plugins darin laufen lassen, die mit nvim gemeinsam gestartet wir Eventuell wie eine zweite runtime alle sinnvollen plugins darin laufe n lassen, die mit nvim gemeinsam gestartet wirdd
3. `BINDINGS.lua`: In der Descrtiptionder Keymaps und Usrcmds: Das plugin selbst nicht nennen,, wie zb.: "[iletree]:" in fileteree.nvim keymap descreiption
4. `/autcmds`
  1. passt zu `/bindings` ?
  2. autocmds aller folder zusammen in einer /autcmd und dort dann korrekte anordnung, also nach events usw,... sodass die performance steigt.
5. Checklisten anwenden
  1. ToDo's duchgehen

---

## High

6. `leader wq`: Alle issues lösen
  1. dass was wq macht in einem `lib.nvim / lib.nvim.ui` ausgeben
7. `/wkdoptions`
  1. UI Linemarker gehört README
  2. `wkdoptions` mit `options.lua` verheiraten (vielleicht als default_options)
8. `nvim/init.lua` durchgehen
9. [ ] Funktionen/Module identifizieren, die man mit FFI/C performanter machen könnte
  - [ ] `/nvim/lua/` – alle Module durchgehen und checken, ob sie irgendwo hineinpassen

---

