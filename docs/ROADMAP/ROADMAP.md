# Roadmap

* [ ] Inline-Images in Markdown-Files einbinden: snacks?
- github:stats.nvim besser machen
- checken, ob mit Snacks/image.nvim es nicht möglich ist, images zu öffnen
- [ ] `migrate.nvim` fertigstellen
- learn-cli.nvim vielleicht doch ?
- `mdview.nvim`: Das war eigentlich mein Websocket Lern Prozess...
- `lua/config/menu` nach `lua/wkdnvchad`?
- beim öfgfnen eienr datzei über harpoon aktualisere filetree.nvim den filetree noch nicht cwd_sync
- [ ] nvim/lua/autocmds analysieren, zb general -> no name guard in filetee.nvim buffer-ctx implementieren
- lernen: https://www.browserstack.com/

## Table of content

  - [ZIEL](#ziel)
  - [High](#high)
  - [LSP](#lsp)
  - [General](#general)
  - [Bugs](#bugs)

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
9. `/wkdoptions`
  1. UI Linemarker gehört README
  2. `wkdoptions` mit `options.lua` verheiraten (vielleicht als default_options)
10. `nvim/init.lua` durchgehen
11. [ ] Funktionen/Module identifizieren, die man mit FFI/C performanter machen könnte
  - [ ] `/nvim/lua/` – alle Module durchgehen und checken, ob sie irgendwo hineinpassen

---

## LSP

12. lightbulb: Manchmal stört sie und ich möchhte das schnell ausblenden können, am besten mit Keymap togglebnar (markdown lsp)

---

## General

13. lsp: Einen switch einbauen, mitdem ich regeln kann, was der root für lsp ist: Switch zwischen cwd/nächstes_git/pfad/ zb mit `leader lsp`öffnet ein `lib.nvim -> select` und den scope den man wählt wir lua_ls nochmal neu berechnet auf den scope
14. `ZenMode` sollte auch eienen usrcmds toggle schalter haben

---

## Bugs

16. manchmal bricht `C-c` mit sigint nvim ab, es solte aber alles kopieren des buffers

---

