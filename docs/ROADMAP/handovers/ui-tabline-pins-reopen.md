# ui.nvim Tableiste: Pinnen, „Tab wieder öffnen“ — Handover

> Stand 2026-09-21. Das Rechtsklick-Tab-Menü, das Ziehen der Tabs und der
> schnellere Close sind **fertig und gepusht** (ui.nvim `5bc0921`, Config
> `ed04b5abd`). Diese Akte hält die zwei danach besprochenen Features, ein
> optionales drittes und die Commit-Liste dieses Chats zum Gegenprüfen.

## Table of content

- [Regeln für diese Session](#regeln-für-diese-session)
- [Orte](#orte)
- [Aufgaben](#aufgaben)
  - [1. Tabs anpinnen](#1-tabs-anpinnen)
  - [2. Geschlossenen Tab wieder öffnen](#2-geschlossenen-tab-wieder-öffnen)
  - [3. Auto-Scroll beim Ziehen (optional, niedrige Priorität)](#3-auto-scroll-beim-ziehen-optional-niedrige-priorität)
- [Commits dieses Chats (zum Gegenprüfen)](#commits-dieses-chats-zum-gegenprüfen)
- [Handwerkszeug](#handwerkszeug)

---

## Regeln für diese Session

- Nie mehr als 1 Agent gleichzeitig; bei Bedarf mehrere Runden à 1 Agent.
- Antworten Deutsch, Quellcode (inkl. Kommentare und Commit-Nachrichten) Englisch.
- Keine Co-Autorenschaft von Claude in Commits.
- Nach jedem fertigen Schritt committen, pullen, nach `main` pushen; die laufende
  Config lädt ui.nvim aus `E:\repos\ui.nvim` (Checkout auf `main`).
- Code muss `stylua --check .` und `luacheck .` grün haben (stylua v2.5.2,
  luacheck 1.2.0); neue Features bekommen Specs im eigenen `TESTS/`.
- Plugin-Docs/README mitpflegen; ändert sich ein Binding, auch die
  Bindings-Notiz in dieser Config (`docs/NOTES/.../Keymaps/NvChadUI.md`).
- Vor jedem Commit `git status` lesen, nie `git add -A` in dieser Config (sie
  hat regelmäßig fremde, uncommittete ROADMAP-Dateien).
- Kein `git stash` zum Vergleichen: er räumt die eigene Arbeit weg. Für einen
  Baseline-Lauf einen Worktree nehmen.

## Orte

| Was | Wo |
|---|---|
| Tableiste (Render, Chips) | `ui.nvim/lua/ui/tabline/` (`modules.lua`, `utils.lua`, `menu.lua`, `drag.lua`, `layout.lua`) |
| Buffer-Liste `vim.t.bufs`, Schließen/Verschieben | `ui.nvim/lua/ui/bindings/keymaps/tabufline/state.lua` |
| Tab-Keymaps | `ui.nvim/lua/ui/bindings/keymaps/init.lua` (`<leader>tr/tl/tt`, `<leader>bc/bq`) |
| Tab-Menü und Maus-Doku | `ui.nvim/docs/BINDINGS.md` → „Tabline mouse“ |
| Specs | `ui.nvim/TESTS/tabline_menu_spec.lua`, `tabline_layout_drag_spec.lua`, `tabufline_state_spec.lua` |
| Tests laufen lassen | im Worktree `LIB_NVIM_DIR=E:/repos/lib.nvim PLENARY_DIR="$LOCALAPPDATA/nvim-data/lazy/plenary.nvim" scripts/test.sh` |
| Maus-Erkenntnisse | Memory `reference_tabline_mouse.md` (Klickprotokoll, RightMouse-Replay, Drag-Mappings, Headless-Test-Kniff) |

---

## Aufgaben

### 1. Tabs anpinnen

Angeheftete Tabs bleiben links stehen und sind beim „Close others“ ausgenommen.

**Verhalten (Vorschlag):**

- Menü-Eintrag `Pin` / `Unpin` im Tab-Menü (`ui.tabline.menu`, Gruppe des
  Dateinamens); Mittelklick und „x“ auf einem gepinnten Tab schließen **nicht**
  (oder fragen), damit ein Pin wirklich schützt.
- Gepinnte Tabs stehen immer vor allen anderen in `vim.t.bufs`. Die Invariante
  „Pins zuerst“ muss jede Stelle einhalten, die die Liste ändert:
  `move_buf_to` und `move_buf` klemmen das Ziel in den eigenen Bereich (ein
  Pin wandert nur unter Pins, ein normaler Tab nie in den Pin-Bereich), und der
  Drag in `drag.lua` läuft über `move_buf_to`, erbt das also.
- Die Chips optisch markieren (Pin-Glyph statt „x“, evtl. schmalere Chips);
  `style_buf` in `ui/tabline/utils.lua` kennt die Chip-Breite schon exakt, der
  Ersatz für den Close-Button hat dieselbe Breite (`close_width` cachet nur
  zwei Formen, hier käme eine dritte dazu).
- „Close others“, „Close to the left/right“, „Close saved“ nehmen Pins aus
  (in `menu.lua` beim Bilden der Mengen filtern). `<leader>bq` / der Button
  „Alle schließen“: **Entscheidung offen**, ob Pins überleben (Empfehlung: ja).

**Wo der Zustand liegt (Entscheidung offen):**

| Variante | Vorteil | Nachteil |
|---|---|---|
| tab-lokal `vim.t.ui_pinned` (Set der bufnr) | passt zu `vim.t.bufs` | Buffernummern gelten nur pro Sitzung |
| global über den Dateipfad | überlebt Buffer-Neuanlage | ein Buffer in zwei Tabs ist überall gepinnt |
| über `sessions.nvim` mitspeichern | überlebt Neustarts | koppelt an ein zweites Plugin, dort nachsehen wie Marks persistiert werden |

Empfehlung: erst tab-lokal ohne Persistenz, Persistenz als Folgeschritt.

**Zu beachten:**

- Die Überlauf-Logik in `modules.buffers` wirft Chips von vorn weg. Pins sollten
  **immer sichtbar** bleiben, sonst verschwindet genau das, was man behalten
  wollte. Das ändert die Breitenrechnung (`space` minus Pin-Chips).
- `<leader>tp` ist schon belegt (`lua/bindings/mappings/buf_win_tab.lua`), ein
  Keymap für Pin braucht einen freien Schlüssel; erst prüfen.
- Specs: Invariante nach jedem Verschieben/Ziehen, Close-Mengen ohne Pins,
  Sichtbarkeit bei Überlauf, Opt-out-Flag analog zu `context_menu`/`drag`.

### 2. Geschlossenen Tab wieder öffnen

Wie Strg+Shift+T im Browser: der zuletzt geschlossene Tab kommt zurück.

**Ansatz:**

- Ein Ring der zuletzt geschlossenen Dateien (Pfad, Cursorposition, Slot in
  `vim.t.bufs`), Größe ca. 20, gleicher Pfad nur einmal (der neueste zählt).
- Aufzeichnen in einem `BufDelete`-Autocmd. Im Handler existiert der Buffer
  noch, `nvim_buf_get_name` und `nvim_buf_get_mark(buf, '"')` liefern also noch
  Pfad und letzte Position. Nur echte Dateien: `buftype == ""`, Name nicht
  leer, Datei lesbar; keine `[No Name]`, Terminals, Quickfix.
- Der Autocmd gehört neben die bestehenden in `state.setup()`
  (`ui_tabufline_state`), damit er wie sie idempotent registriert wird.
- Wieder öffnen: `:edit <pfad>`, Cursor setzen, `move_buf_to` auf den gemerkten
  Slot (klemmt selbst). Schon offene Datei: nur dorthin wechseln.
- Auslöser: Tab-Menü-Eintrag „Reopen closed tab“ (Untermenü mit den letzten
  N über `ui.kit.select`) plus ein Keymap in `ui/bindings/keymaps/init.lua`.
  Schlüssel prüfen, `<leader>tp` ist vergeben.

**Grenzen, die dokumentiert gehören:** ungespeicherte Änderungen eines
verworfenen Buffers kommen **nicht** zurück (nur die Datei, wie sie auf der
Platte liegt); der Ring lebt nur in der Sitzung. Ob er pro Tab-Seite oder
global geführt wird, ist offen (Empfehlung: global, mit Tab-Seite als Merkmal).

Specs: Aufzeichnen (nur echte Dateien), Duplikate, Ringgröße, Wiederöffnen an
den Slot, gelöschte Datei auf der Platte (Hinweis statt Fehler).

### 3. Auto-Scroll beim Ziehen (optional, niedrige Priorität)

**Was gemeint ist:** Das Ziehen verschiebt einen Chip nur unter den Chips, die
gerade in die Leiste passen. Sind mehr Buffer offen als Platz ist, folgt der
sichtbare Ausschnitt dem aktuellen Buffer, und ein Chip lässt sich nicht bis an
das unsichtbare Ende ziehen. Auto-Scroll hieße: hält man die Maus beim Ziehen am
linken/rechten Rand und still, rückt der Ausschnitt von selbst weiter, wie
beim Ziehen in einer Liste mit Scrollbalken.

**Warum nur optional:**

- Braucht einen Timer, der auch ohne neue Mausereignisse weiterläuft (ein
  stilles Halten am Rand erzeugt keine `<LeftDrag>`-Events), und einen
  Sichtfenster-Offset in `modules.buffers`, den es heute nicht gibt: das
  Fenster wird aus dem aktuellen Buffer abgeleitet.
- Die Lücke ist klein: „Move to position…“ und die Menü-Einträge „Move to
  start/end“ erreichen jeden Slot ohne Sichtproblem.
- Wird Pinnen umgesetzt (Aufgabe 1), ändert sich die Breitenrechnung ohnehin;
  einen Sichtfenster-Offset dann in einem Zug mitplanen statt zweimal
  anzufassen.

Empfehlung: erst nach Aufgabe 1 bewerten, ob es im Alltag fehlt.

---

## Commits dieses Chats (zum Gegenprüfen)

| Repo | Commit | Inhalt |
|---|---|---|
| `ui.nvim` | `5bc09210a3c120875d09e940b2d818aa1c32b087` | `feat(tabline): per-tab right-click menu, drag to reorder, snappier close`, 15 Dateien, +1775/−36 |
| Config (`nvim`) | `ed04b5abdcd38bf5e5dd8c30ea5d84d0d4f03d67` | `feat(menu): step aside for ui.nvim's tab menu on a tab-bar right-click`, 4 Dateien, +46/−2 |
| Config (`nvim`) | dieser Handover-Commit | `docs(handover): …` — sein Hash steht nicht in der Datei selbst, `git log -1 -- docs/ROADMAP/handovers/ui-tabline-pins-reopen.md` |

Anschauen:

```bash
git -C E:/repos/ui.nvim show 5bc0921
git -C E:/repos/ui.nvim show --stat 5bc0921
git -C C:/Users/bartl/AppData/Local/nvim show ed04b5abd
```

**Wo beim Prüfen genauer hinschauen** (die Stellen mit dem meisten Risiko):

1. `state.lua` → `close_buffer`: der neue `is_current`-Zweig. Vorher sprang das
   aktuelle Fenster beim Schließen eines Hintergrund-Tabs zuerst auf dessen
   Nachbarn; jetzt bleibt es stehen. Auch der Zweig für ein Hintergrund-
   Terminal (Buffer wird nur ausgetragen, Job läuft weiter).
2. `drag.lua`: belegt `<LeftDrag>`/`<LeftRelease>` global (Modi `n i v t`) für
   genau eine Geste und stellt fremde Mappings über `maparg`/`mapset` wieder
   her; Sicherheitsnetz ist ein 5-s-Idle-Timer. Hier prüfen, ob in der Praxis
   irgendein Ziehen-zum-Markieren danach hängt.
3. `utils.lua` → `on_chip_click` / `on_close_click`: Button-Weiche (`l`/`r`/`m`)
   und `CLOSE_DELAY_MS = 25`. Der Rechtsklick öffnet das Menü per
   `vim.schedule`, nicht direkt im Klick-Handler.
4. `menu.lua`: Gating der Einträge, `close_set` (bei „Close others“ zuerst auf
   den angeklickten Tab wechseln, dann schließen), Prompt „Move to position…“.
5. `modules.lua`: `available_space` liefert jetzt zusätzlich den Text links von
   `buffers` (für `layout.lua`); reine Ergänzung, die Breitenrechnung selbst ist
   unverändert.
6. Config `lua/config/menu/mappings.lua`: der `<RightMouse>`-Dispatcher kehrt
   nach dem Nachspielen des Klicks zurück, wenn
   `ui.tabline.menu.pointer_on_tabline()` wahr ist.

Was nur Testcode belegt und was nicht: die Klick- und Drag-Specs rufen die
Callbacks direkt auf (`getmousepos` gestubbt). Die echten Mausereignisse liefen
nur als Wegwerf-Skript im Headless-Nvim mit Timer-Schleife; es liegt nicht im
Repo. **Eine Sichtprüfung im echten Terminal steht aus** (Menü-Optik, Gefühl
des Ziehens, Latenz des Schließens).

---

## Handwerkszeug

```bash
export LIB_NVIM_DIR=E:/repos/lib.nvim PLENARY_DIR="$LOCALAPPDATA/nvim-data/lazy/plenary.nvim"
scripts/test.sh TESTS/tabline_menu_spec.lua
scripts/test.sh TESTS/tabline_layout_drag_spec.lua
scripts/test.sh TESTS/tabufline_state_spec.lua
stylua --check . && luacheck .
```
