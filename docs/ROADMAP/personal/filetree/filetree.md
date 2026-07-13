# `filetree.nvim`

[s](docs/ROADMAP/personal/filetree/tester.lua)
[s](./tester.lua)
[s](docs/ROADMAP/personal/filetree/tester2.lua)
[s](./test2.lua)

- Es funkltiert, als das anpasen der refrenezen, aber wenn man "update all references" auswählt, alks nicht per oicker, dann wird nur eine refenez angepast, nicht alle die exosistieren. Und das auch nicht zuverlöässig: der markdown link relativ zum cwd ist, dann scheint er den link nicht zu finden. Beispiel:

```lua
[s](docs/ROADMAP/personal/filetree/tester.lua)
[s](./tester.lua)
[s](docs/ROADMAP/personal/filetree/tester2.lua)
[s](./test2.lua)
```

wenn ich jetz im filetree tester.lua zu testing.lua umbenne, und auf update all refreences klicke, dann erzeugt er:

```lua
[s](docs/ROADMAP/personal/filetree/tester.lua)
[s](docs/ROADMAP/personal/filetree/testing.lua)
[s](docs/ROADMAP/personal/filetree/tester2.lua)
[s](./test2.lua)
```

Infos:
 - Aktuelles cwd ist nvim config, aslso `./docs/ROADMAP/personal/filetree/tester.lua` existiert tatsächlich
 - Die datei, in der das steht (und geäbndert wurde) ist `./docs/ROADMAP/personal/filetree/filetee.md`, also stimmt von der file aus gesehen auch der pfad ./tester.lua bzw ./testing.lua

- Noch ein wichtigewr punkt: Momentan dauerst es sehr sehr lange, 20-30 Sekunden, nachdem man "d" bzw "r" oder "m" eingeben hat auf einer node. Kann man da performace technisch etwas machen?Bei der perorfmacne momentan, müssen wir es fast opt in machen und default mäßig deaktivieren. GIbt es viellecht den ein oder anderen "schmäh" den wir anwenden können? zb.: schon wenn man das keymap drückt, gleich starten miut dem suchen der referenzen, noch bevor bzw in dem zeitnkjt, wo der user auswähöt eiunen eeuen namen bzw welche option man wäht zum ref updaten. wenn man dan wählt, keine updaten, na dann ist es halt so, aber wenn man gleich beim satrt der keymap einen asynchronen prozess startet, dann könnte das etwaws bringen, oder nicht? sicherlich am meisten beim renaimng, denn da muss der user jha einen neuen namen eingeben -> viel zeiut. aber auch beim "x" muss der user eine neue standort suchen und dort hin mocven, -> auch 7eiot... Was dnekst du? mach einen schlachtplan für das performance problem

## Table of content

  - [Neue Features](#neue-features)
  - [Bugs](#bugs)
  - [General](#general)
  - [Filetree Manager spezifische Features](#filetree-manager-spezifische-features)
    - [neotree spezifisch](#neotree-spezifisch)
      - [sources](#sources)
  - [Später](#spter)
  - [ANFRAGE](#anfrage)

---

## Neue Features

- [ ] **filetree.nvim-Integration von mdview.nvim**: auf einer Markdown-File-Node
  ein Usrcmd/Keymap anbieten, das die Datei direkt via mdview öffnet. e:\repos\mdview.nvim

---

## Bugs

---

## General

1. Alle keymaps prüfen

---

## Filetree Manager spezifische Features

1. neotree, nvimtre, netrwq, oil, minifiles spezifische features sammeln (features, die diese plugins selbst anbieten)

---

### neotree spezifisch

| Datei | Was drin | Für filetree.nvim? |
| ----- | -------- | ------------------ |
| `utils/selective_callback_guard.lua` | Monkey-patcht `neo-tree.events._handlers` für Event-Transitionen | **NEIN** — neotree-intern, aber inspiriert `watcher_quarantine` neotree-Adapter-Integration |
| `utils/event_patch.lua` | Patcht `neo-tree.sources.filesystem.lib.fs_watch` für EPERM-Suppression | **NEIN** — komplett neotree-intern |

---

#### sources

| **sources/ + icons/** | Lazy Source Registry, 3 Icon-Familien (nerd/codicons/common), responsive Größe |

`sources`-Feature von neotree nachbilden — 🔲 **Phase 4, niedrige Priorität.** Verifiziert: `lua/config/neotree/sources/registry.lua` ist aktuell ein simpler Lazy-Loader (register/load/is_loaded/list), kein Template-System — der Wunsch existiert im Code noch nicht. Statt eines vollen Template-Engines: erstmal eine kleine Recipe-/Copy-Paste-Config-Sammlung (2-3 gängige Source-Setups) im `filetree.nvim`-README oder `docs/` — deckt den eigentlichen Schmerzpunkt ("Einrichtung war Pain") günstiger ab als ein neues System.

---

## Später

1. `?`-Cheatsheet mit allen Keymaps — ✅ **Phase 2 umgesetzt.**
   - neotree: ✅ FIXED (native `?`/show_help bereits vollständig über `attach.lua`s `window.mappings`-Injection).
   - **Recherche (Quellcode von nvim-tree.lua geklont und gelesen):** `g?`/`toggle_help` baut seine Liste, indem es `on_attach` erneut auf einem **Scratch-Buffer** ausführt und dessen Keymaps ausliest (`nvim-tree/keymap.lua:generate_keymap`) — keine Live-Buffer-Introspektion. filetree.nvim's Keys (separat per `FileType`-Autocmd gebunden) tauchen dort grundsätzlich nie auf, außer man hängt sich in nvim-trees `on_attach`-Callback selbst ein — das wäre ein Umbau der kompletten Keymap-Architektur des nvimtree-Adapters, kein Cheatsheet-Feature mehr. Netrw's `?` ist zudem eine statische Hilfeseite; oil/minifiles nicht verifiziert.
   - **Nebenfund (nicht behoben, separater Punkt):** `node_info` und vermutlich weitere Features hardcoden `pattern = {"neo-tree", "NvimTree"}` in ihrem `FileType`-Autocmd statt `adapter.filetypes` zu nutzen — würde für netrw/oil/minifiles vermutlich gar nicht binden. Nicht Teil dieser Phase, aber ein Hinweis, dass die nvimtree/netrw/oil/minifiles-Unterstützung insgesamt noch nicht durchgängig verifiziert ist.
2. Cross-Check mit [Keymaps.md](../../../NOTES/neotree/Keymaps.md) & [Auto-Usrcmds-EventHandler.md](../../../NOTES/neotree/Auto-Usrcmds-EventHandler.md)

---

## ANFRAGE

Alten Config-Code entfernen, der bereits in filetree.nvim abgedeckt ist — ✅ **erste Runde umgesetzt** (nur die zweifelsfrei toten Dateien; der Rest bleibt bewusst offener Folgepunkt).

   - **Analyse:** Ein Explore-Agent hat den kompletten `lua/config/neotree/**`-Baum (~150 Dateien) von den beiden echten Einstiegspunkten (`plugins/neotree.lua`, `config.neotree.init.setup()`) aus auf Erreichbarkeit geprüft. Ergebnis: ~40 Dateien komplett unreferenziert (`open/**`, `init/**`, `state/*`, `refresh_adapter/`, `undo/`, diverse `actions/*`, fast alle `keymaps/filesystem/*.lua` außer `files.lua`, u.a.), eine weitere Gruppe (`trash/*`, `safety/*`, `current_hl/*`, u.a.) nur noch über `:NeoTreeCheckHealth`-Diagnose-Probes "geladen" (praktisch tot, aber Löschen bräuchte eine Begleitänderung in `checkhealth/*`), und `commands/*` (die neo-tree-Custom-Commands-Registry) technisch noch eingehängt aber fast durchgängig ohne Tastenbindung.

   - **Umgesetzt:** nur die zweifelsfrei tote erste Gruppe gelöscht (~50 Dateien). Die checkhealth-verknüpfte Gruppe und `commands/*` bewusst **nicht** angefasst — eigener Folgepunkt.

   - ⚠️ **Zwei Fehler dabei gefunden und korrigiert:**

     1. `lua/config/neotree/keymaps/filesystem/images.lua` hatte bereits *vor* dieser gesamten Session nicht-committete Änderungen (stand von Anfang an als `M` im `git status`) — versehentlich mitgelöscht, ohne vorher `git diff` zu prüfen. Auf den letzten committeten Stand wiederhergestellt (`git checkout HEAD --`); die eigentliche unfertige Änderung ist nicht wiederherstellbar (keine Swap-/Undo-Datei gefunden). **Der User weiß ggf. noch, was dort geändert war.**

     2. Der Agent-Bericht behauptete, `trash/defaults.lua` würde trotz `lazy.require(...)` nie wirklich dereferenziert — falsch: `require("config.neotree")` brach danach mit einem echten Fehler ab. Datei wiederhergestellt, danach alle ~51 gelöschten Dateien manuell per grep gegengeprüft (nicht mehr blind dem Agenten vertraut).

   - **Verifiziert:** `require("config.neotree")`, `require("config.neotree").setup({…echte Live-Optionen…})` und `:NeoTreeCheckHealth` laufen alle fehlerfrei durch.

   - **Runde 2 (checkhealth-verknüpfte Gruppe): ✅ ebenfalls umgesetzt.** Vor dem Löschen `git status` auf jede Zieldatei geprüft (Lehre aus Runde 1) — sauber, keine vorbestehenden Änderungen. Gelöscht: `trash/{init,platform,validation,confirmation,operations}` (aber **nicht** `trash/defaults.lua` — bleibt wegen des `lazy.require`-Verhaltens aus Runde 1 nötig), `safety/**` komplett, `current_hl/**` komplett, `utils/{tree,buffer,platform}.lua`. Begleitend die zugehörigen Probe-Blöcke aus `checkhealth/{features,utils}.lua` entfernt.

   - **Folgefund dabei:** `actions/copy/{entries,folders}` requiren `config.neotree.utils.tree` auf Modul-Top-Level (nicht in einer Funktion) — durch das Löschen von `utils/tree.lua` wäre das kaputt (harmlos dank `pcall`, aber inkonsistent) geblieben. Da beide ohnehin schon tot waren (einziger Caller: die längst tote `keymaps/filesystem/path.lua`), auf Rückfrage mitgelöscht inkl. ihrer beiden `checkhealth/actions.lua`-Probe-Einträge.

   - **Verifiziert (erneut vollständig):** alle verbleibenden ~51 Referenzen manuell per grep gegen die komplette Löschliste geprüft (keine Treffer außer den bekannten, `pcall`-geschützten), `config.neotree.setup()` mit echten Live-Optionen und `config.neotree.checkhealth().check()` laufen beide fehlerfrei durch.

   - **`commands/*`-Registry: Entscheidung — so lassen.** Technisch noch in `neo-tree.setup()` eingehängt, aber `run_command`/`custom_add`/`telescope_find`/`telescope_grep`/`diff_files`/`markdown_links*`/`mark` fast durchgängig ohne Tastenbindung (filetree.nvim deckt dieselbe Funktionalität ab). Bewusst **nicht** entfernt: würde den `opts.commands`-Aufbau in der live `plugins/neotree.lua` direkt anfassen — zentraler und sensibler als alles bisher Gelöschte, für reinen Aufräum-Nutzen ohne funktionalen Vorteil. Nur `commands/source` ist noch aktiv gebunden (`keymaps/init.lua`) und bleibt so oder so unangetastet.



---





Kannst dud das weiter machen, also ales ewas in gfiletree.nvim bererits implementiert ist, aus meiner nvim/lua/config/neotree /nvim/lua/config/fzf.lua bzw nvim/lua/plugins/telescope.lua / nvim/lua/plugins/fzf.lua entfernen.

Alles was dann noch über ist: auflisten und in bereiche einteilen, mal schauen was wir damit machen werden

---

