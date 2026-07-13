# `filetree.nvim`

## Table of content

  - [Schlachtplan (Prioritäten)](#schlachtplan-prioritten)
  - [Neue Features](#neue-features)
  - [Bugs](#bugs)
  - [General](#general)
  - [Filetree Manager spezifische Features](#filetree-manager-spezifische-features)
    - [neotree spezifisch](#neotree-spezifisch)
      - [sources](#sources)
  - [hooks](#hooks)
    - [state/windows.lua & state/tree.lua](#statewindowslua-statetreelua)
  - [Später](#spter)
  - [möglicherweise](#mglicherweise)
  - [Gelöst: Delete + Markdown-Referenzen](#gelst-delete-markdown-referenzen)

---

## Schlachtplan (Prioritäten)

Stand: gegen den aktuellen Code verifiziert (filetree.nvim, nvim-config, markdown.nvim, open.nvim).

| Phase | Thema | Status |
| ----- | ----- | ------ |
| 0 | Doc-Hygiene (dieser Durchgang) | ✅ erledigt |
| 1 | Keymap-Audit (General #1) | ✅ umgesetzt (siehe unten) |
| 2 | `?`-Cheatsheet für nvimtree/netrw/oil/minifiles | ✅ umgesetzt (siehe unten) |
| 3 | Delete + Markdown-Referenzen-Feature | ✅ umgesetzt (siehe unten) |
| 4 | Sources-Templates + Community-Config-Sharing | 🔲 niedrige Priorität, übersprungen |
| 5 | Restliche "Später"/"möglicherweise"-Punkte | 🔲 Backlog (Später #6: erste Runde ✅, siehe unten) |

Bereits vorhanden (verifiziert, nicht mehr offen):
- `hooks_api` (E:\repos\filetree.nvim\lua\filetree\features\infra\hooks_api\init.lua) — voller Event-Bus (`on`/`once`/`off`/`emit`), inkl. `before_delete`/`after_delete` Events. Deckt das Listener-Pattern von `state/windows.lua` ab.
- `commands.lua` — generisches `:Filetree`/`:Ft` mit Tab-Completion über alle Features. Deckt den Kern von "Später" #3 ab.
- `org/session` — Cursor/Scroll/Root/expanded-dirs Persistenz (best-effort). Deckt die `state/tree.lua`-Inspiration ab.
- `bindings/keymaps.lua` — zentraler Keymap-Katalog, Quelle für `docs/BINDINGS/`-Cheatsheet, dokumentiert bereits einen Konflikt inline.

---

## Neue Features

---

## Bugs

---

## General

1. Alle keymaps prüfe

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

1. `sources`-Feature von neotree nachbilden — 🔲 **Phase 4, niedrige Priorität.** Verifiziert: `lua/config/neotree/sources/registry.lua` ist aktuell ein simpler Lazy-Loader (register/load/is_loaded/list), kein Template-System — der Wunsch existiert im Code noch nicht. Statt eines vollen Template-Engines: erstmal eine kleine Recipe-/Copy-Paste-Config-Sammlung (2-3 gängige Source-Setups) im `filetree.nvim`-README oder `docs/` — deckt den eigentlichen Schmerzpunkt ("Einrichtung war Pain") günstiger ab als ein neues System.
2. Endpoint/Webseite für User-Konfigurationen + Screenshots — 🔲 **Phase 4, außerhalb des Codebase-Scopes** (eigenes Infra-Projekt), bleibt reine Backlog-Notiz.

---

## hooks

---

### state/windows.lua & state/tree.lua

- `state/windows.lua` — Window-State-Registry (open/position/source, Listener-Pattern, Snapshot-Cache). ✅ **Bereits abgedeckt:** `filetree.nvim`s `hooks_api` (`lua/filetree/features/infra/hooks_api/init.lua`) ist ein vollwertiger Event-Bus (`on`/`once`/`off`/`emit`/`clear`) mit eingebauten Events (`before_delete`, `after_delete`, `before_move`, `after_move`, `before_copy`, `after_copy`, `node_open`, `tree_open`, `tree_close`, `session_save`, `session_restore`, `root_change`, `refresh`) — deckt das Listener-Pattern ab und ist bereits der zentrale Event-Bus, den die alte Notiz noch als offen ("gehört aber in einen zentralen Event-Bus") beschreibt.

`lua/config/neotree/state/tree.lua`

- `state/tree.lua` — Cursor-Position + expanded-Nodes speichern/restoren. Nutzt neotree-interne APIs, nicht übertragbar. ✅ **Inspiration bereits umgesetzt:** `lua/filetree/features/org/session/init.lua` persistiert Adapter, Root, Scroll-Position, Cursor-Zeile und (best-effort) expandierte Ordnerpfade pro Projekt-Root, inkl. `:FiletreeSessionSave/Restore/Clear`.

---

## Später

1. `?`-Cheatsheet mit allen Keymaps — ✅ **Phase 2 umgesetzt.**
   - neotree: ✅ FIXED (native `?`/show_help bereits vollständig über `attach.lua`s `window.mappings`-Injection).
   - **Recherche (Quellcode von nvim-tree.lua geklont und gelesen):** `g?`/`toggle_help` baut seine Liste, indem es `on_attach` erneut auf einem **Scratch-Buffer** ausführt und dessen Keymaps ausliest (`nvim-tree/keymap.lua:generate_keymap`) — keine Live-Buffer-Introspektion. filetree.nvim's Keys (separat per `FileType`-Autocmd gebunden) tauchen dort grundsätzlich nie auf, außer man hängt sich in nvim-trees `on_attach`-Callback selbst ein — das wäre ein Umbau der kompletten Keymap-Architektur des nvimtree-Adapters, kein Cheatsheet-Feature mehr. Netrw's `?` ist zudem eine statische Hilfeseite; oil/minifiles nicht verifiziert.
   - **Entscheidung: der in der Notiz selbst vorgesehene Ausweg** — eigenes, adapter-unabhängiges Cheatsheet-Popup gebaut statt pro Adapter zu reverse-engineeren.
   - **Umgesetzt:** neues Feature `cheatsheet` (`filetree/features/ui/cheatsheet/init.lua`, Default-Keymap `?`). Baut die Anzeige aus dem bereits vorhandenen `bindings.keymaps()`-Katalog (derselbe, der `docs/BINDINGS.lua` speist), gefiltert auf tree-scoped Bindings deren Feature gerade aktiv ist (`filetree.is_feature_enabled`). No-op auf dem neotree-Adapter (dessen native Hilfe bleibt die bessere Lösung) und bei Adaptern ohne (oder fehlerhaftem) `filetypes`-Feld. Bindet generisch über `adapter.filetypes` statt hartcodierter Adapter-Namen — funktioniert dadurch für nvimtree/netrw/oil/minifiles gleichermaßen.
   - **Test-getriebener Bugfund:** Der erste Wurf reichte `adapter.filetypes` ungeprüft als Autocmd-`pattern` durch; Stub-Adapter mit Catch-all-`__index`-Metatable liefern dafür eine *Funktion* statt `nil`/Tabelle, was crashte (`test/smoke.lua` hat das sofort aufgedeckt). Gefixt mit einer expliziten Typ-Prüfung; 9 neue Tests in `test/units.lua` decken Bind/Show/Toggle/neotree-Skip/fehlendes-`filetypes` ab. Alle 127 Unit-Tests grün.
   - **Nebenfund (nicht behoben, separater Punkt):** `node_info` und vermutlich weitere Features hardcoden `pattern = {"neo-tree", "NvimTree"}` in ihrem `FileType`-Autocmd statt `adapter.filetypes` zu nutzen — würde für netrw/oil/minifiles vermutlich gar nicht binden. Nicht Teil dieser Phase, aber ein Hinweis, dass die nvimtree/netrw/oil/minifiles-Unterstützung insgesamt noch nicht durchgängig verifiziert ist.
2. Cross-Plattform-/Cross-Filetree-Check — 🔲 **wiederkehrender Punkt**, kein einmaliger Task, bleibt offen als laufende Checkliste.
3. Keymaps auch als adapter-unabhängige usrcmds — ✅ **im Kern bereits vorhanden:** `lua/filetree/commands.lua` implementiert ein generisches `:Filetree`/`:Ft <subcommand>` mit Tab-Completion über praktisch alle Features (trash, marks, diff, git, safety, session, find, grep, filter, size, rename, template, reveal, resize, watcher, clipboard, breadcrumbs, open, openas, mdlink, hooks, smartrename, copy, search, create, filelist, require, traverse, info, health). Offen bleibt nur die Feinheit aus Punkt 3.2 der alten Notiz (adapterlos, "nur mit Zeilen/Cols/Chars" arbeitend, falls gar kein Tree-Plugin läuft) — als kleiner Rest-Punkt im Backlog.
4. Cross-Check mit [Keymaps.md](../../../NOTES/neotree/Keymaps.md) & [Auto-Usrcmds-EventHandler.md](../../../NOTES/neotree/Auto-Usrcmds-EventHandler.md) — 🔧 **Linkfix:** die alten relativen Pfade (`../../NOTES/...`) zeigten eine Ebene zu flach ins Leere; jetzt korrigiert auf `../../../NOTES/...`. Der eigentliche Cross-Check (Inhalt gegen aktuellen Stand prüfen) bleibt offen.
5. Features durchgehen — 🔲 offen, wiederkehrend.
6. Alten Config-Code entfernen, der bereits in filetree.nvim abgedeckt ist — ✅ **erste Runde umgesetzt** (nur die zweifelsfrei toten Dateien; der Rest bleibt bewusst offener Folgepunkt).
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

## möglicherweise

1. Adapter-Methode `get_target_nodes()` (neo-tree native Visual-Markierung `explicitly_marked_node_ids`) — ❌ **Prämisse verworfen.** Installiertes neo-tree (v3.x) direkt durchsucht: `explicitly_marked_node_ids` existiert dort nicht. Das einzige "marked" im Renderer sind normale Vim-Marks (`vim.fn.getmarklist`) zur Cursor-Wiederherstellung, kein visuelles Multi-Select. Ein echtes natives Multi-Mark-System (`api.marks.toggle`/`bulk.*`) gibt es stattdessen in **nvim-tree**, nicht in neo-tree — vermutlich eine Verwechslung in der ursprünglichen Notiz. filetree.nvim's eigenes `marks`-Feature bleibt damit die einzige Option für neo-tree — nichts zu bauen.
2. `e:\repos\filetreepicker.nvim` — ⚠️ **existiert noch nicht**, nur als auskommentierter Lazy-Spec-Eintrag in [`lua/plugins/personal/init.lua:359-366`](../../../../lua/plugins/personal/init.lua) vorgemerkt (Idee, kein Code).
3. `e:\repos\neotree-fs-refactor.nvim` — ❌ **leerer Ordner** (angelegt 2025-07-06, kein Git-Repo, keine Dateien) — derselbe Zustand wie `filetreepicker.nvim`, nur der Ordner existiert schon. Nichts zu sichten.

---

## Gelöst: Delete + Markdown-Referenzen

> Ursprüngliche Frage: Beim Löschen einer Datei prüfen, ob Markdown-Dateien im cwd darauf verlinken (`[label](./pfad)`), im Trash/Undo-Confirm-Popup anzeigen und optional Referenzen bereinigen/durch `REF!` ersetzen. Unklar war, ob das eher zu `filetree.nvim` (Delete/Undo/Trash-Ownership) oder `markdown.nvim` (Link-Wissen) gehört — und wie `open.nvim`s eigene Delete-Usrcmds (`:File delete %`) das mit abdecken.

**Entscheidung: Ownership bei `filetree.nvim`, Scan-Logik als kleine öffentliche API in `markdown.nvim`.**

- `filetree.nvim` besitzt bereits den kompletten Delete/Trash/Undo/Confirm-Flow (`features/fileops/trash/*`, `util/confirm.lua`) **und** den `hooks_api`-Eventbus mit fertigen `before_delete`/`after_delete`-Events — die Erweiterung ist ein natürlicher Zusatzschritt in der bestehenden Pipeline, keine neue Architektur.
- `markdown.nvim` bekommt eine schlanke, wiederverwendbare Funktion `find_references(target_path, search_root) -> {file, line}[]` (reine Link-Suche, kein Delete-Wissen nötig) — wiederverwendbar auch für andere Zwecke ("wer linkt auf diese Datei").
- `filetree.nvim`s `trash`-Feature ruft diese Funktion optional im `before_delete`-Hook auf (`pcall(require("markdown").find_references, ...)`, soft-dep wie beim `fenced-scope`-Feature in color_my_ascii) und erweitert das bestehende Confirm-Popup um "N Referenzen gefunden — mitbereinigen? [y/N/nur zeigen]".
- `open.nvim`s `:File delete %` ruft dieselbe `filetree.trash`-API auf statt eigene Delete-Logik zu bauen — kein Duplikat.
- Warum nicht `markdown.nvim` als Owner: Filesystem-Delete/Undo/Trash ist Dateiverwaltung, nicht Markdown-Domäne; `markdown.nvim` bleibt so schlank wie möglich (Referenzen finden ist der einzige Teil, der wirklich Markdown-Wissen braucht).
- Aufwand: mittel — eigene Implementierungsrunde (Phase 3).

**✅ Umgesetzt:**
- `markdown.nvim`: `util/path.lua` bekam `M.resolve_from(target, base_dir)` (Link-Resolution gegen einen beliebigen Basisordner, nicht nur den aktuellen Buffer); neues `core/file_refs.lua` mit `M.find_references(target_path, opts)` (scannt `**/*.md` unter `opts.root`, ignoriert `.git`/`node_modules`/etc., matched über `link_scan` + `resolve_from`); öffentlich unter `require("markdown_nvim").find_references(...)`. Test: `TESTS/file_refs_spec.lua`.
- `filetree.nvim`: `features/fileops/trash/init.lua` bekam `check_markdown_refs` (default `true`). Vor dem Confirm-Popup wird optional (`pcall`, soft-dep) `markdown_nvim.find_references()` aufgerufen (Suchwurzel via `project_root.find()`); werden Referenzen gefunden, ersetzt ein Chooser das normale y/N-Popup. Bei "cleanup" wird pro betroffener Zeile `](target)` → `](REF!)` ersetzt (Datei-für-Datei gebündelt, ein Read/Write pro Datei). Test: Block "trash: markdown.nvim soft-dep" in `test/units.lua`.
- `open.nvim`-Teil nicht umgesetzt: `open.nvim` hat aktuell keine eigenen Delete-Usrcmds, also nichts zum Umleiten — bleibt Backlog, falls das Feature dort mal gebaut wird (dann auf `filetree.trash.delete()` mappen).

**✅ Erweiterung: "Inspect references first" — Picker mit Preview + Multi-Select.** Statt nur "N Referenzen gefunden" jetzt eine vierte Chooser-Option, die die Referenzen in einem Picker mit Datei-Preview zeigt und eine gezielte Teilauswahl erlaubt, bevor bereinigt wird.
- Neuer Chooser: `✓ Delete + remove all references` / `◐ Inspect references first` / `• Delete, keep references` / `✗ Cancel`.
- Neues, wiederverwendbares Util-Modul `filetree/util/refs_picker.lua`: `M.pick(refs, opts, on_confirm, on_cancel)`. Backend-Kaskade wie bei `grep_in_dir` (`_cfg.prefer`: `"auto"|"telescope"|"fzf-lua"|"quickfix"`):
  - **Telescope** (Standard, wenn installiert): custom Picker mit `conf.grep_previewer` (dieselbe Datei+Zeile-Preview wie bei `live_grep`). `<Tab>`/`<C-a>` sind Telescopes eigene Multi-Select-Defaults; `<CR>` bestätigt die Multi-Selektion, oder — falls keine getroffen wurde — den Eintrag unter dem Cursor. `<Esc>` → `on_cancel()`.
  - **fzf-lua** (falls `prefer="fzf-lua"`): Einträge im ripgrep/vimgrep-Format (`file:line:col:text`), fzf-lua's eingebauter Previewer erkennt das automatisch. `<Tab>` ist fzfs eigener Multi-Select-Default; `<C-a>` wird explizit auf `select-all` gelegt (Standard in fzf-lua ist dort `beginning-of-line`). **Wichtiger Fund beim Bauen:** fzf-lua ruft bei Esc gar keinen Callback auf (`fn_selected` wird nur bei echter Selektion aufgerufen) — Fix: ein `actions["esc"]`-Eintrag lässt fzf-lua automatisch `--expect=esc` gegen den fzf-Prozess setzen (`actions.lua:M.expect`), wodurch Esc als echter Tastendruck durchgereicht wird statt den Callback stillschweigend zu überspringen.
  - **Quickfix-Fallback** (kein Telescope/fzf-lua installiert): Referenzen in die Quickfix-Liste, `:copen`. Da eine reine Quickfix-Liste kein "Picker geschlossen"-Event hat, kuratiert der User sie selbst (Zeilen löschen für Referenzen, die NICHT bereinigt werden sollen) und bestätigt über `:Filetree mdrefs confirm` (matched verbleibende Zeilen zurück gegen die ursprüngliche Ref-Liste über normalisierten Pfad+Zeile) bzw. bricht mit `:Filetree mdrefs cancel` ab.
- Test: `TESTS`-Skript für den Quickfix-Pfad isoliert (Prune+Confirm, Cancel) sowie ein Ende-zu-Ende-Test über den echten `delete_current()`-Flow in `test/units.lua` ("trash+inspect"). Telescope/fzf-lua selbst sind wie bei `grep_in_dir` nicht headless testbar (Standard-Einschränkung dieser Testumgebung). Alle 131 Unit-Tests grün.
- Alle bestehenden Tests laufen weiterhin grün (filetree.nvim: 118/118 units; markdown.nvim: 9/9 specs).

---
