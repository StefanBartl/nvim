# hover.nvim — Keymaps Cheatsheet

Source: `E:/repos/hover.nvim/lua/hover/bindings/keymaps.lua`,
`lua/hover/config/DEFAULTS.lua`
Docs: `hover.nvim/docs/BINDINGS.md`, `docs/FEATURES/RESIZE.md`,
`docs/FEATURES/ZOOM.md`

**Fast alles hier ist geliehen, nicht besessen.** Die Tasten unten werden
global gebunden, solange *ein* Float auf dem Schirm ist, und in dem Moment
zurückgegeben, in dem es schließt — die verdrängte Zuordnung wird
**wiederhergestellt** (`maparg(…, true)` + `mapset`), nicht gelöscht. Das Float
ist `focusable = false`, bekommt also nie einen Tastendruck und kann keine
eigene Zuordnung halten.

Eine konfigurierte Liste **ersetzt** die Vorgabe, sie erweitert sie nicht; eine
leere Liste bindet gar nichts. **In dieser Config ist nichts davon
überschrieben** — `require("hover").enable()` ohne Optionen, alles unten sind
Plugin-Defaults.

## Owned — bei setup gebunden, bleibt

| Key | Mode | Effect | Option/Source |
| --- | --- | --- | --- |
| *(keine)* | — | — | `keymaps.show`, Default **`false`** |

Kein Key wird per Default beansprucht: ein Plugin, von dem andere Plugins
abhängen, vergibt keine Taste in deren Namen. `:Hover show` deckt dasselbe ab.
Lohnt sich in `mode = "manual"` — `:checkhealth hover` warnt genau bei dieser
Kombination. **Hier nicht gesetzt.**

## Borrowed — bei jedem Hover

| Key | Mode | Effect | Option/Source |
| --- | --- | --- | --- |
| `q` | n | Hover wegwischen, bis der Cursor ein anderes Ziel erreicht | `dismiss_keys` |
| `<Esc>` | n | dito | `dismiss_keys` |
| `gf` | n | öffnen, was das Float zeigt — über open.nvim, sonst `vim.ui.open` | `open_keys` |
| `<M-ScrollWheelUp>` | n | einen Schritt größer, **nur solange der Zeiger über dem Float steht** (Rahmen zählt mit) | `resize_keys.wheel_larger` |
| `<M-ScrollWheelDown>` | n | einen Schritt kleiner, gleiche Bedingung | `resize_keys.wheel_smaller` |

## Borrowed — nur bei passendem Inhalt

| Key | Mode | Effect | Option/Source | Bedingung |
| --- | --- | --- | --- | --- |
| `<M-PageDown>`, `<C-Down>` | n | nächster Bildschirm / nächste PDF-Seite | `scroll_keys.down` | nur scrollbar |
| `<M-PageUp>`, `<C-Up>` | n | zurück | `scroll_keys.up` | nur scrollbar |
| `+` | n | Float einen Schritt (×1,25) größer | `resize_keys.larger` | nur Hovers **mit Bild** |
| `-` | n | einen Schritt kleiner | `resize_keys.smaller` | nur Hovers **mit Bild** |
| `h` | n | vergrößerten Ausschnitt nach links schwenken | `pan_keys.left` | nur solange **gezoomt** |
| `l` | n | nach rechts | `pan_keys.right` | nur solange gezoomt |
| `k` | n | nach oben | `pan_keys.up` | nur solange gezoomt |
| `j` | n | nach unten | `pan_keys.down` | nur solange gezoomt |

Reihenfolge beim Binden: Dismiss vor Open vor Scroll vor Resize vor Pan — eine
Taste, die in zwei Listen steht, wird einmal genommen, und zwar für die
Bedeutung, die immer gilt.

## Kollisionen — was man wissen muss

| Taste | Was währenddessen nicht geht |
| --- | --- |
| `q` | zeichnet kein Makro auf, solange ein Float offen ist |
| `<Esc>` | was sonst darauf liegt, ist geliehen — und wird zurückgegeben |
| `gf` | verdrängt das Vim-Builtin; gewollt, weil das Float die Datei bereits aufgelöst hat, auch truncated und mit `:line:col` |
| `<C-Down>` / `<C-Up>` | bewusst statt `<M-Down>`/`<M-Up>` (verbreitetes „move line") |
| `h` `j` `k` `l` | **nur während gezoomt** keine Cursorbewegung. Ohne diese Leihe würde `h` über einem vergrößerten Bild den Cursor bewegen und damit das Float wegnehmen |

**Warum `+`/`-` nur bei Bildern, das Rad aber überall:** das ist eine
Entscheidung über den *Preis* einer Taste, keine über die Fähigkeit — begründet
in `hover.nvim/docs/FEATURES/RESIZE.md`. Praktisch heißt es: auf einem
Text-Hover sind `+` und `-` frei und behalten ihre Zeilenbewegung; der
Tastaturweg dorthin ist `:Hover resize`.

## Reservierte Akkorde in dieser Config

Aussage über **diese** Config, nicht über das Plugin.

| Akkord | Status |
| --- | --- |
| `<C-+>` / `<C-->`, `<C-ScrollWheel>` | **ausgeschlossen** — allgemeiner Fenster-Zoom, gehört nicht dem Plugin |
| `<M-->` | **vergeben** an cascade.nvim (Bullet Points) |
| `<M-+>` | frei, aber ohne Partner — ein Regler mit einer Richtung ist keiner |
| `<M-ScrollWheelUp/Down>` | **vergeben** — hover.nvims Default fürs Rad |
| `<S-+>` / `<C-S-+>` und Gegenstücke | frei, **aber ungeprüft** — siehe Notes |

## Notes

- **Kein which-key** — geprüft und verneint: `lua/hover/` hat kein
  `which_key`-Modul und keinen `which_key`-Config-Key. Es gäbe auch nichts zu
  gruppieren: der einzige besessene Key ist `keymaps.show` (per Default
  ungebunden), alles andere existiert nur, solange ein Float offen ist.
- **`<S-+>` ist ungeprüft, und das ist keine Kleinigkeit.** Neovim *nimmt* die
  Schreibweise an und hält sie von `+` getrennt (mit `maparg` nachgemessen
  2026-09-02). Ob das Terminal sie je **sendet**, ist eine andere Frage: auf
  deutscher Tastatur ist Shift+`+` das Zeichen `*`. Der Test ist eine Minute:
  `:nnoremap <S-+> :echo "kommt an"<CR>`. Entscheidet nur über Komfort — über
  Rad und `:Hover resize` ist die Funktion ohne jede Leihe erreichbar.
- **Das Rad braucht `'mouse'` im passenden Modus.** Ohne das erreicht gar kein
  Radereignis Neovim und die Zuordnung ist wirkungslos statt kaputt;
  `:checkhealth hover` sagt es, weil beides identisch aussieht.
- **Gescrollt wird ausschließlich über die geliehenen Tasten** — eine
  `:Hover`-Route für `scroll` gibt es nicht (nachgezählt gegen
  `usrcmds.routes()`: achtzehn Routen, `scroll` ist keine).
- Warum welche Taste an welcher Bedingung hängt, steht im Repo und nicht hier:
  `docs/FEATURES/RESIZE.md` für `+`/`-`/Rad, `docs/FEATURES/ZOOM.md` für
  `h/j/k/l`.

## Changelog

- 2026-09-02 (4): **`pan_keys` ergänzt** — `h/j/k/l`, seit hover.nvim
  `9fba190` geliehen, solange ein Hover gezoomt ist. Fehlten hier ganz. Dabei
  die Datei auf das Cheatsheet-Format zurückgeschnitten: die Begründungen zu
  Leih-Bedingungen, Radmessungen und Tastenpreis stehen jetzt einmal im Repo
  (`docs/FEATURES/RESIZE.md`, `docs/FEATURES/ZOOM.md`) statt zweimal.
- 2026-09-02 (3): **`hover.zoom()` ist kein Alias für `resize` mehr**
  (hover.nvim `bd72836`). Es war seit `9fba190` auch keiner: dort entstand ein
  echtes `M.zoom`, das die zweite Definition desselben Namens war und still
  gewann. Der Name gehört jetzt eindeutig dem echten Zoom.
- 2026-09-02 (2): **`zoom_keys` heißt `resize_keys`** (hover.nvim `8ec5b40`),
  und das Rad gilt für **jeden** Hover statt nur für gezeichnete. `+` und `-`
  bleiben bei Bildern, weil sie Motions sind. Alte Schreibweise wird von
  `config.normalize()` gefaltet.
- 2026-09-02: **das Rad ist gebaut** (hover.nvim `83922f0`).
  `<M-ScrollWheelUp/Down>`, mit der Zusatzregel, dass es nur wirkt, solange der
  Zeiger über dem Float steht. `getmousepos()` kann diese Frage nicht
  beantworten — bei einem `focusable = false`-Float meldet sein `winid` das
  Fenster darunter —, also rechnet `hover.float.contains` das Rechteck selbst.
- 2026-09-02: `zoom_keys` fehlten hier ganz (seit hover.nvim `204d083`), dazu
  der Abschnitt über reservierte Akkorde.
- 2026-09-02: `open_keys` (`gf`) fehlte hier ganz (seit hover.nvim `f2e0788`).
- 2026-09-01: unverändert durch hover.nvim `b2b4b2c` (`:Hover paths code`).
