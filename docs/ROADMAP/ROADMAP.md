# Roadmap

- [ ] `nvim/lua/autocmds`  nach `nvim/lua/Bindings`

case: move solved/assigned/unaasiugend/OtherAgent/... -> verschiednt ordner  zum ziel. case delete

- [ ] `bindings-explorer.nvim` — Phase 1 (`:Bindings search`/`path`) ist
  fertig. Offen: Phase 2 (jede Tabellenzeile aus den BINDINGS-Cheatsheets
  als durchsuchbarer Datensatz, `:Bindings browse`) und Phase 3
  (Drift-Erkennung: dokumentierte Keymaps/Usercmds gegen tatsächlich
  registrierte via `nvim_get_keymap`/`nvim_get_commands` abgleichen).
  Volles Konzept: `docs/ROADMAP/personal/bindings-explorer.nvim.md`.


- pdfport.nvim - pdf erstellings funkiton zb pandoc; im filetree wöre dass dan auch super: diese file/image als pdf erstellen, dann kann ich die pdf gleich im system app viewer aufmachen...
- spotlight checken und lernen
- documentation.nvim lernen


- [ ]  Könnte es nicht eine "neue art" software sein, alle meine nvim plugins entweder mit oder ohne einer nvim instanz gemeinesam bündeln und als bnary ausgheben, so das s man es wieder wie normales nvim aber halt mit + verewnden kann.

  - checken, ob mit Snacks/image.nvim es nicht möglich ist, images zu öffnen
- [ ] `learn-cli.nvim` vielleicht doch ?
- [ ] `lua/config/menu` nach `lua/wkdnvchad`?
- [ ] `nvim/lua/autocmds` analysieren
- [ ] finish & checkists & review in nvim config durchjagen

## ZIEL

1. Alle plugin fähigen Module augliedern
2. Funktionen/Module/ganze Custom Plugins, die man mit ffi über vc performanter machen könnte?
  1.  Eventuell wie eine zweite runtime alle sinnvollen plugins darin laufen lassen, die mit nvim gemeinsam gestartet wir Eventuell wie eine zweite runtime alle sinnvollen plugins darin laufe n lassen, die mit nvim gemeinsam gestartet wirdd
-2. `BINDINGS.lua`: In der Descrtiptionder Keymaps und Usrcmds: Das plugin selbst nicht nennen,, wie zb.: "[iletree]:" in fileteree.nvim keymap descreiption
3. `/autcmds`
  1. passt zu `/bindings` ?
  2. autocmds aller folder zusammen in einer /autcmd und dort dann korrekte anordnung, also nach events usw,... sodass die performance steigt.
4. Checklisten anwenden
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


---

## MyPlugin-Notes ausgewertet (2026-08-08)

`E:/repos/Notes/MyPlugin-Notes/` (125 Dateien) wurde vollstaendig gegen den
aktuellen Code geprueft und in die Roadmaps verteilt. Neu bzw. ergaenzt:

- `personal/gopath.nvim.md`, `personal/cmdlog.nvim.md`, `personal/markdown.nvim.md`,
  `personal/pickers.nvim.md`, `personal/replacer.nvim.md`, `personal/reposcope.nvim.md`,
  `personal/documentation.nvim.md`, `personal/lsp.nvim.md`,
  `personal/color_my_ascii.nvim/color_my_ascii.md`
- neu: `personal/learn-cli.nvim.md`, `personal/IDEAS/slots.nvim.md`,
  `personal/IDEAS/typepilot.nvim.md`
- uebergreifend: `personal/00_MISC.md` (Spawn-/Env-Falle, API-Key-Regel,
  README-Videos, Quickfix-Ausgang)
- extern: `telescope.nvim.md`

Bestaetigt sich der Befund aus `personal/All/Roadmap-Effort-Overview.md`: der
groessere Teil der Notizen war laengst gebaut. Bei `replacer.nvim` waren 26 von
27 Wuenschen umgesetzt. Was jeweils erledigt ist, steht in den Dateien mit drin,
damit es nicht erneut als offen gelesen wird.

`nvim-containers` aus den Notizen ist `sandbox.nvim` (drei Engines inkl.
nerdctl, Volumes, Compose, Registry, Telescope-Extension — laut eigener
`docs/ROADMAP.md` dort bereits vollstaendig abgearbeitet); kein separater
Eintrag hier noetig. Das Patch-System aus den Notizen wird nicht
weiterverfolgt.
