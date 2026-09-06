# Harpoon (harpoon2)

Referenz für die Harpoon-Config dieses Setups: `ThePrimeagen/harpoon`
(Branch `harpoon2`) + eine eigene Hardening-/Persistenz-Schicht darüber.

Plugin-Spec: [lua/plugins/misc.lua](../../lua/plugins/misc.lua)
Config-Module: `lua/config/harpoon/*`
Keymaps: [lua/bindings/mappings/harpoon.lua](../../lua/bindings/mappings/harpoon.lua)

---

## 1. Kernkonzept: EINE globale Liste

Harpoon2 schlüsselt seine Listen standardmäßig nach `settings.key()`, per
Default das rohe `vim.loop.cwd()` — im Ursprungszustand bekommt also jedes
Arbeitsverzeichnis seine eigene, leere Liste.

In dieser Config ist `settings.key` fest auf einen einzigen konstanten Wert
gepinnt:

```
PINS_KEY = vim.fn.stdpath("config")   -- z.B. C:\Users\...\AppData\Local\nvim
```

verdrahtet in `bindings/mappings/harpoon.lua` via `harpoon:setup({ settings = { key = function() return PINS_KEY end, ... } })`.

**Konsequenz:** Es gibt nur noch *eine* Harpoon-Liste, sichtbar und identisch
in jedem Projekt/Verzeichnis. `<C-e>` zeigt überall denselben Inhalt. Kein
"leeres Quick-Menu", weil man gerade in einem anderen Repo ist.

`config.harpoon.persist_paths.PINS_KEY` ist der Single-Source-of-Truth-Wert
(vom Mapping-Modul importiert, kein Drift möglich).

---

## 2. Persistente Default-Pfade (`config.harpoon.persist_paths`)

Datei: [lua/config/harpoon/persist_paths.lua](../../lua/config/harpoon/persist_paths.lua)

### Zwei Quellen für Defaults

1. **`target_specs`** — im Code fest definiert, git-getrackt, pro Aufruf von
   `persist_paths.setup({ target_specs = {...} })` in `misc.lua` gesetzt.
   Format: Liste von Segment-Arrays, erstes Segment darf eine Variable sein
   (`$REPOS_DIR`, `$HOME`, `$NVIM_HOME`), Rest wird per `vim.fs.joinpath`
   angehängt.

   Aktuell in [misc.lua](../../lua/plugins/misc.lua):
   - `stdpath("config")/lua/plugins/personal/init.lua`
   - `stdpath("config")/docs/ROADMAP/ROADMAP.md`
   - `$REPOS_DIR/WKDBooks/Spickzettel/spickzettel.md`
   - `$REPOS_DIR/WKDBooks/Development/wkdbook-Lua/Notes/LuaNotes.md`
   - `$REPOS_DIR/WKDBooks/Development/wkdbook-Neovim/Referenz_Notes/98_cheatsheets/tastaturkuerzel-konsolidiert.md`

   **Nur auf der Workstation** (`machine.is("workstation")`, siehe
   [lua/machine.lua](../../lua/machine.lua)) wird die Basisliste komplett
   ERSETZT (nicht ergänzt) durch die fünf Tricentis-Pfade unten plus genau
   die ersten drei der obigen Liste (`target_specs[1..3]`, per Index
   wiederverwendet) — die beiden neuen wkdbook-Lua/-Neovim-Einträge sind
   also bewusst **nur auf Nicht-Workstation-Maschinen** aktiv:
   - `$REPOS_DIR/WKDBook-Tricentis/Cases/Workflow/Workflow.md`
   - `.../Cases/Workflow/Templates/FirstResponse_Rick.md`
   - `.../Cases/Workflow/Templates/SAP_TBox_RequestInfos.md`
   - `.../Cases/Workflow/Templates/RequestMoreInfo.md`
   - `.../ToDo-Collection/SAP_Support_ToDo.md`
   - (plus `personal/init.lua`, `ROADMAP.md`, `spickzettel.md` von oben)

2. **User-Pins** — maschinenlokal, per `:HarpoonPin` gesetzt, gespeichert als
   JSON-Array unter `stdpath("state")/harpoon_user_pins.json`. **Nicht
   git-getrackt.** Werden bei der Auflösung hinter die `target_specs`
   angehängt (dedupliziert).

`resolve_targets()` liefert beide Quellen zusammen, in fester Reihenfolge,
dedupliziert nach normalisiertem Realpath.

### Erststart-Verhalten

Ein Marker unter `stdpath("state")/harpoon_persist_paths.initialized` trackt,
ob dieses Modul auf dieser Maschine schon einmal gelaufen ist:

- **Erster Start überhaupt:** Defaults werden automatisch einmalig injiziert
  (`VimEnter`, `once = true`), danach wird der Marker gesetzt.
- **Jeder weitere Start:** Nichts passiert automatisch. Das Bucket bleibt
  exakt so, wie es zuletzt verlassen wurde — Umsortieren/Löschen im
  Quick-Menu persistiert normal und wird **nicht** automatisch
  zurückgesetzt.

### Speicherort der Daten

Harpoon selbst persistiert nach `stdpath("data")/harpoon/<sha256(key)>.json`
(hier: `stdpath("data")/harpoon/<sha256(stdpath("config"))>.json`, da
`PINS_KEY = stdpath("config")`).

---

## 3. User-Commands

Ein einziges Verb `:Harpoon <subcommand>` (gebaut mit
`lib.nvim.bindings.usercmd.composer`, registriert in
[lua/config/harpoon/usrcmds.lua](../../lua/config/harpoon/usrcmds.lua)) plus
flache Aliase. Vollständige Referenz:
[ExternPlugins/Bindings/Usercmds/Harpoon.md](ExternPlugins/Bindings/Usercmds/Harpoon.md).

| Command | Zweck |
|---|---|
| `:Harpoon` | Quick-Menu öffnen/schließen (Bare-Form). |
| `:Harpoon menu [default\|telescope\|fzf]` | Listen-UI öffnen. |
| `:Harpoon add [pfad] [--front] [--permanent]` | Datei hinzufügen (Default: aktueller Buffer, ans Ende). `--front` = Slot 1, `--permanent` = zusätzlich als Default-Pin. |
| `:Harpoon remove [pfad]` | Eintrag aus der Live-Liste entfernen. |
| `:Harpoon pin [pfad] [--front]` | Dauerhaft als Default-Pin aufnehmen (`harpoon_user_pins.json`). |
| `:Harpoon unpin [pfad]` | Aus den Default-Pins nehmen; der Listeneintrag bleibt. |
| `:Harpoon defaults sync` | **Top-up**: fügt fehlende Default-Pfade (aus `target_specs` + User-Pins) ans Ende an. Bestehende Reihenfolge/Zusatzeinträge bleiben unangetastet. |
| `:Harpoon defaults reset` | **Hard-Reset**: leert das Bucket komplett und baut es exakt aus `target_specs` + User-Pins neu auf, in genau dieser Reihenfolge. Alles, was darüber hinaus manuell hinzugefügt wurde, geht verloren. |
| `:Harpoon select <n>` | Zu Eintrag *n* springen. |
| `:Harpoon preview <n>` | Vollbild-Preview von Eintrag *n* (siehe §5). |
| `:Harpoon debug` | Öffnet einen Scratch-Buffer mit Index + gekürztem Pfad-Label jedes aktuellen Listeneintrags. |
| `:Harpoon health` | Manueller Health-Check (Plugin geladen? plenary/fzf-lua/telescope optional vorhanden? Liste lesbar?) — äquivalent zu `:checkhealth`, nur direkt aufrufbar. |

Flache Aliase (bleiben bewusst bestehen):
`:HarpoonAddToList [pfad]` = `add --front`,
`:HarpoonAddToListPermanent [pfad]` = `add --front --permanent`,
`:HarpoonPin`, `:HarpoonUnpin`, `:HarpoonPersistPaths` (= `defaults sync`),
`:HarpoonSetDefaultPaths` (= `defaults reset`), `:HarpoonDebug`,
`:CheckHealthHarpoon`.

---

## 4. Keymaps

Alle Maps stehen als **ein which-key-Spec** (`wk.add`-Form) in
[bindings/mappings/harpoon.lua](../../lua/bindings/mappings/harpoon.lua). Die
rhs ist immer ein `<cmd>Harpoon …<cr>`, d.h. jede Keymap *ist* ihr
Usercmd-Aufruf — eine Map ohne Command-Entsprechung ist konstruktiv unmöglich.
Details: [ExternPlugins/Bindings/Keymaps/Harpoon.md](ExternPlugins/Bindings/Keymaps/Harpoon.md).

| Mapping | Modus | Aktion | = Command |
|---|---|---|---|
| `<leader>h` | n | Gruppe "Harpoon" (which-key), keine eigene Aktion. | — |
| `<leader>ha` | n | Aktuelle Datei ans Ende anhängen. Komprimiert vorher etwaige `nil`-Lücken (durch frühere Löschungen), damit neue Einträge wirklich ans Ende gehängt werden statt in eine Lücke zu fallen. | `:Harpoon add` |
| `<leader>hA` | n | Aktuelle Datei an den Anfang der Liste setzen. | `:Harpoon add --front` |
| `<leader>hp` | n | Aktuelle Datei an den Anfang + dauerhafter Default-Pin. | `:Harpoon add --front --permanent` |
| `<leader>hd` | n | Aktuelle Datei aus der Liste entfernen. | `:Harpoon remove` |
| `<leader>hm`, `<C-e>` | n | Quick-Menu öffnen/schließen (`harpoon.ui:toggle_quick_menu`). Zeigt die globale Liste, siehe §1. | `:Harpoon menu` |
| `<leader>ht` | n | Liste als Telescope-Picker öffnen (gekürzte Labels, `<CR>`/`<C-v>`/`<C-x>`/`<C-t>`). | `:Harpoon menu telescope` |
| `<leader>hf` | n | Liste als fzf-lua-Picker öffnen. | `:Harpoon menu fzf` |
| `<leader>hs` | n | Fehlende Default-Pfade nachziehen. | `:Harpoon defaults sync` |
| `<leader>hD` | n | Liste in Scratch-Buffer dumpen. | `:Harpoon debug` |
| `<M-1>` … `<M-9>` (Alt+1..Alt+9) | n | Vollbild-Preview von Eintrag *N* (siehe §5). | `:Harpoon preview <n>` |

Nicht gemappt (selten/zustandsverändernd, nur als Command): `:Harpoon select <n>`,
`:Harpoon unpin`, `:Harpoon defaults reset`, `:Harpoon health`.

**Im Quick-Menu selbst** (Harpoon-Standardverhalten, `filetype=harpoon`):
normaler Buffer-Editing-Flow — Zeilen umsortieren (verschieben wie normalen
Text), `dd` zum Löschen einer Zeile, `<CR>` zum Öffnen des Eintrags unter dem
Cursor, Fenster schließen persistiert automatisch (siehe §6).

---

## 5. Vollbild-Preview (`config.harpoon.preview`)

Datei: [lua/config/harpoon/preview.lua](../../lua/config/harpoon/preview.lua)

- `:Harpoon preview <n>` (gemappt auf `<M-1>`…`<M-9>`) öffnet Harpoon-Eintrag
  *N* in einem read-only, nicht-modifizierbaren Floating-Fenster, das den
  Editor weitgehend ausfüllt.
- Cursor springt auf die im Harpoon-Item gespeicherte Position
  (`context.row/col`).
- Einzelner wiederverwendeter Scratch-Buffer/Fenster (kein Leak bei
  mehrfachem Öffnen).
- Große Dateien (> 1.5 MB) werden nur bis `MAX_LINES = 4000` gelesen
  (`readfile` mit Zeilenlimit statt Volllesen).
- Filetype wird für Syntax-Highlighting automatisch erkannt
  (`vim.filetype.match`).
- Schließen mit `q` (`lib.nvim.window.nice_quit`).
- Scrollbar wie ein normaler Buffer, verändert nicht das bestehende
  Fenster-Layout (Float statt Split).

---

## 6. Hardening / Autosave (`config.harpoon.hardening`)

Datei: [lua/config/harpoon/hardening.lua](../../lua/config/harpoon/hardening.lua)
Setup in `misc.lua`: `debounce_ms = 200`, `autocmd_events = { "BufLeave", "FocusLost" }`.

- Debounced Save: mehrere schnelle Änderungen (Buffer-Wechsel etc.) werden zu
  einem einzigen Save-Aufruf zusammengefasst (`uv.timer`, konfigurierbares
  `debounce_ms`).
- Save-Trigger: `BufLeave`, `FocusLost` (konfigurierbar), zusätzlich beim
  Schließen des Quick-Menus (`ui.toggle_quick_menu` einmalig gewrappt).
- Finaler, **nicht** gedebounceter Flush auf `VimLeavePre`, damit die letzte
  Änderung vor dem Beenden nicht verloren geht.
- **Hinweis:** Harpoon2 selbst persistiert bereits automatisch bei jeder
  `ADD`/`REMOVE`/`REORDER`-Aktion (interner `sync_on_change`-Mechanismus).
  Diese Hardening-Schicht ist ein zusätzliches Sicherheitsnetz, kein
  Ersatz dafür.

### Tuning (aus `Cfg.Harpoon.HardeningOpts`, `types/init.lua`)

- **`debounce_ms`** (Default 200): gute Werte sind 150–300 ms auf lokalen
  SSDs, 300–600 ms auf Netzwerk-/Remote-Dateisystemen (SMB/NFS/SSHFS). Wenn
  trotzdem noch häufige Writes auffallen, in 100-ms-Schritten erhöhen. Bei
  sehr schnellem Beenden wird die letzte Änderung sonst gelegentlich nicht
  mehr persistiert — dafür sorgt der nicht gedebouncte Flush auf
  `VimLeavePre` (siehe oben); `debounce_ms` trotzdem moderat (≤ 400) halten.
- **`autocmd_events`** (Default `{ "BufLeave", "FocusLost" }`): zum Erweitern
  `"WinLeave"` (bei viel Fenster-/Tab-Wechsel), `"FocusGained"` (Save auch
  beim Zurückkehren zu Neovim), `"BufHidden"` (für Setups, die Buffer
  verstecken statt entladen), `"CmdlineLeave"` (falls eigene Commands
  Harpoon editieren). Mehr Events = mehr Save-Gelegenheiten, aber auch mehr
  Timer-Neustarts; ein Quit-Event ist nicht nötig (s. o.).

---

## 7. Sanitize & Dedup (`config.harpoon.utils.sanitize`)

Datei: [lua/config/harpoon/utils/sanitize.lua](../../lua/config/harpoon/utils/sanitize.lua)

- `sanitize_items_in_place(list)`: hebt rohe Strings und Legacy-Items
  (`{ path = ... }`) auf das einheitliche Format `{ value, context }` an,
  **ohne** `list.items` komplett zu ersetzen (UI-/Objekt-Identität bleibt
  erhalten).
- `dedup_in_place_safe(list)`: entfernt Duplikate anhand von
  `normkey(value)` (Pfad-Normalisierung inkl. `fs_realpath`, Windows:
  Drive-Letter groß, Slashes vereinheitlicht). Nutzt `list:remove()`, wenn
  vorhanden.

Beide werden von `persist_paths.inject_now()` / `set_defaults()` vor bzw.
während der Injektion aufgerufen.

---

## 8. Pin-Marker im Quick-Menu (`config.harpoon.pin_marks`)

Datei: [lua/config/harpoon/pin_marks.lua](../../lua/config/harpoon/pin_marks.lua)

Jede Zeile im Quick-Menu, deren Pfad zu einem Default-Pin (`target_specs` +
User-Pins) gehört, bekommt einen End-of-Line-Marker:

```
📌 pin
```

- Highlight-Gruppe `HarpoonPinMark`, standardmäßig auf
  `DiagnosticVirtualTextWarn` verlinkt (dezent, themeabhängig).
- Wird bei jedem Öffnen des Menüs (`FileType harpoon`) sowie live bei
  Änderungen im Menü-Buffer (`TextChanged`, `TextChangedI`) neu berechnet —
  Umsortieren/Löschen aktualisiert die Marker sofort.
- Ad-hoc über `<leader>ha`/`<leader>hA` hinzugefügte Einträge (keine Defaults)
  bleiben unmarkiert.
- Icon (`ICON`-Konstante oben in der Datei) und Highlight sind einzeilig
  anpassbar.

---

## 9. Debug/Health (`config.harpoon.debug`, `config.harpoon.health`)

- `:Harpoon debug` (`:HarpoonDebug`) — Scratch-Buffer, `nnn  <gekürzter Pfad>`
  pro Zeile (`lib.nvim.fs.path_shorten`, Style `"label"`).
- `:Harpoon health` (`:CheckHealthHarpoon`) — ruft
  `config.harpoon.health.check()` direkt auf: prüft ob `harpoon` ladbar ist, ob
  `plenary`/`fzf-lua`/`telescope` (optional) vorhanden sind, und ob
  `harpoon:list()` eine plausible Struktur zurückgibt.
- Registriert werden sie — wie alle Harpoon-Commands — in
  `config.harpoon.usrcmds.setup()` (aufgerufen in `misc.lua`).

---

## 10. Setup-Reihenfolge (`misc.lua`, `config = function()`)

```lua
config.harpoon.hardening.setup({ debounce_ms = 200, autocmd_events = {...} })
-- target_specs zusammenbauen (machine.is("workstation") gate)
config.harpoon.persist_paths.setup({ target_specs = target_specs })
config.harpoon.pin_marks.setup()
config.harpoon.usrcmds.setup()   -- :Harpoon-Verb + flache Aliase
```

Die `harpoon:setup({ settings = { key = ..., save_on_change = true, ... } })`-
Aufruf und die eigentlichen Keymaps (which-key-Spec: `<leader>h…`, `<C-e>`,
`<M-1>`…`<M-9>`)
laufen separat in `bindings/mappings/harpoon.lua` (`UIReady`-Phase, siehe
`init.lua`), **nach** dem Plugin-Setup.

---

## 11. Bekannte Abweichungen zu älteren Doku-Ständen

Zwei weitere Dateien im selben Ordner
(`lua/config/harpoon/docs/GoodToKnow.md`, `featurelist.md` teilweise)
beschreiben Konzepte, die **nicht** (mehr) implementiert sind, u. a.:
- Git-Root-basierter Project-Key (`GoodToKnow.md`) — tatsächlich: fester
  globaler Key, siehe §1.
- FZF-Menü auf `<C-h>` — `<C-h>` ist tatsächlich mit "Fenster nach links"
  belegt (`bindings/mappings/buf_win_tab.lua`); das FZF-Menü
  (`config.harpoon.ui.menu_fzf`) hängt an `<leader>hf` bzw.
  `:Harpoon menu fzf`.
- Modulpfade wie `utils.fs_project_key`, `config.harpoon_hardening` (ohne
  Punkt-Nesting) existieren in diesem Repo nicht; die echten Pfade sind
  `config.harpoon.*` wie oben referenziert.

Diese Datei (`docs/NOTES/Harpoon.md`) beschreibt ausschließlich verifizierten
Ist-Zustand.
