# Roadmap

- spotlight checken und lernen
- images, das wäre für support wirklcih wichtig. eventuell en eigenses plugin bauen? das wäre



- p und strg-v verhalten sihcv nun anders, kannst du das anschauen

-  nC:\Users\bartl\AppData\Local\nvim\lua\usrcmdsach /bindings/usrcmds






- [ ]  Könnte es nicht eine "neue art" software sein, alle meine nvim plugins entweder mit oder ohne einer nvim instanz gemeinesam bündeln und als bnary ausgheben, so das s man es wieder wie normales nvim aber halt mit + verewnden kann.

* [ ] Inline-Images in Markdown-Files einbinden: snacks?
  - checken, ob mit Snacks/image.nvim es nicht möglich ist, images zu öffnen
- [ ] `github_stats.nvim` besser machen
- [ ] `learn-cli.nvim` vielleicht doch ?
- [ ] `lua/config/menu` nach `lua/wkdnvchad`?
- [ ] `nvim/lua/autocmds` analysieren
- [ ] finish & checkists & review in nvim config durchjagen

## ZIEL

1. Alle plugin fähigen Module augliedern
2. Funktionen/Module/ganze Custom Plugins, die man mit ffi über vc performanter machen könnte?
  1.  Eventuell wie eine zweite runtime alle sinnvollen plugins darin laufen lassen, die mit nvim gemeinsam gestartet wir Eventuell wie eine zweite runtime alle sinnvollen plugins darin laufen lassen, die mit nvim gemeinsam gestartet wirdd
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

