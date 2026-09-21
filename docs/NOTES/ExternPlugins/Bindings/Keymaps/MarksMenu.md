# Marks-Menü (kit) — Keymaps

Source: `sessions.nvim/lua/sessions/marks/menu.lua` (`open_kit`),
`ui.nvim/lua/ui/kit/shortlist.lua`, `ui.nvim/lua/ui/kit/chooser.lua`
Docs: `sessions.nvim/docs/marks.md` (Abschnitt „Working in the kit menu's
preview“), `ui.nvim/lua/ui/kit/README.md` (Abschnitt „Shortlist“)

`:Session marks` öffnet die Marks-Liste im `kit`-Menü (die Voreinstellung von
`marks.menu.ui = "auto"`): oben die Preview der Datei, darunter die Liste. Die
Tasten unten sind **popup-lokal** — buffer-lokal auf genau diesen zwei Fenstern,
nichts davon ist eine globale Map dieser Config, und sie verschwinden mit dem
Popup. Deshalb kann `:Bindings check` sie nicht sehen; dieses Blatt ist die
einzige Stelle in der Config, die sie nennt.

Die Preview ist ein echtes, **schreibgeschütztes** Fenster mit dem Highlighting
der Datei: alles, was nur liest, geht dort (Bewegungen, `/`, Visual-Mode, `y`),
verändern lässt sich der Buffer nicht. So kann man weiter in eine Datei
hineinlesen und etwas kopieren, bevor man sie öffnet.

---

## Maps

| Mapping | Fenster | Aktion | Status |
|---|---|---|---|
| `<C-f>`, `<PageDown>` | Liste, Preview | Preview eine Seite nach unten | [default] `ui.kit.shortlist` |
| `<C-p>`, `<C-b>`, `<PageUp>` | Liste, Preview | Preview eine Seite nach oben | [default] `ui.kit.shortlist` |
| `<C-d>`, `<C-u>` | Liste, Preview | Preview eine halbe Seite nach unten / oben | [default] `ui.kit.shortlist` |
| `<Tab>`, `<C-w>w`, `<C-w><C-w>`, `<C-w>W` | Liste, Preview | zwischen Liste und Preview wechseln (bleibt im Popup) | [default] `ui.kit.shortlist` |
| `<CR>` | Liste | Eintrag öffnen, wo man ihn verlassen hat | [default] `ui.kit.chooser` |
| `<C-x>`, `<C-v>`, `<C-t>` | Liste | in Split, Vsplit oder Tab öffnen | [default] `sessions.marks.menu` |
| `<CR>` | Preview | Datei **an der Zeile des Preview-Cursors** öffnen | [default] `sessions.marks.menu` |
| `q`, `<Esc>` | Liste, Preview | Popup schließen | [default] `ui.kit.chooser` / `ui.kit.shortlist` |

---

## Notes

- **Eine Seite** ist die von Vim: Fensterhöhe minus zwei Zeilen Überlappung.
  `<C-p>` blättert hoch, obwohl Vim damit „eine Zeile hoch“ meint: es bildet das
  Paar zu `<C-f>`, `<C-b>` steht als Alias für Vims eigenes Paar daneben. In der
  Liste bleiben `j`/`k`/Pfeile die Zeilennavigation.
- **`<C-w>w` bleibt im Popup.** Unbehandelt liefe der Fensterwechsel weiter ins
  Editorfenster darunter und ließe das Popup darüber stehen. Aus demselben Grund
  schließt das Popup, sobald der Fokus in ein anderes Fenster geht (Klick in den
  Editor, `<C-w>j`, Tab-Wechsel).
- Das fokussierte Fenster hat einen hervorgehobenen Rahmen (`KitAccent`), und
  jedes Fenster trägt eine Fußzeile mit den Tasten, die dort gelten.
- **Umkonfigurieren:** `marks.menu.preview_keys` im `sessions`-Spec dieser
  Config (`lua/plugins/personal/init.lua`, Block `marks`). Gruppen:
  `scroll_down`, `scroll_up`, `half_down`, `half_up`, `focus`, `cycle`, `close`,
  `submit`; eine Liste ersetzt die Tasten der Gruppe, `false` schaltet sie ab,
  `preview_keys = false` alle. Diese Config setzt derzeit nichts, es gelten die
  Voreinstellungen.
- Getestet in `ui.nvim/TESTS/ui_kit_shortlist_preview_spec.lua` (die Tasten
  werden über `nvim_feedkeys` gedrückt) und in `sessions.nvim/TESTS/marks_spec.lua`
  (Öffnen an der Preview-Zeile, `preview_keys` durchgereicht).
- 2026-09-21: neu (ui.nvim `7d2f872`, sessions.nvim `04ec151`). Vorher lief
  `<C-w>w` in den Editor, `q` tat in der Preview nichts, und die Liste konnte
  die Preview nicht scrollen.
