# hover.nvim — Keymaps Cheatsheet

Source: `E:/repos/hover.nvim/lua/hover/bindings/keymaps.lua`,
`lua/hover/config/DEFAULTS.lua`
Docs: `hover.nvim/docs/BINDINGS.md`, `docs/FEATURES/RESIZE.md`,
`docs/FEATURES/ZOOM.md`, `docs/FEATURES/ZEN.md`

**Fast alles hier ist geliehen, nicht besessen.** Die Tasten unten werden
global gebunden, solange *ein* Float auf dem Schirm ist, und in dem Moment
zurückgegeben, in dem es schließt — die verdrängte Zuordnung wird
**wiederhergestellt** (`maparg(…, true)` + `mapset`), nicht gelöscht. Das Float
ist `focusable = false`, bekommt also nie einen Tastendruck und kann keine
eigene Zuordnung halten.

Eine konfigurierte Liste **ersetzt** die Vorgabe, sie erweitert sie nicht; eine
leere Liste bindet gar nichts. **In dieser Config ist nichts davon
überschrieben** — `require("hover").enable()` ohne Optionen, alles unten sind
Plugin-Defaults. Zwischen dem 2026-09-03 und hover.nvim `21c4932` stimmte
dieser Satz nicht: dort stand ein `zoom_keys`-Workaround im Plugin-Spec, und
diese Zeile hat ihn nicht erwähnt. Er ist weg, weil der Default jetzt dasselbe
sagt.

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
| `F` | n | Float auf (fast) den ganzen Editor, und zurück; pinnt dabei | `zen_keys.toggle` | jedes Hover **mit Ziel** (Position-Hovers nicht) |
| `<M-PageDown>`, `<C-Down>` | n | nächster Bildschirm / nächste PDF-Seite | `scroll_keys.down` | nur scrollbar |
| `<M-PageUp>`, `<C-Up>` | n | zurück | `scroll_keys.up` | nur scrollbar |
| `+` | n | Float einen Schritt (×1,25) größer | `resize_keys.larger` | nur Hovers **mit Bild** |
| `-` | n | einen Schritt kleiner | `resize_keys.smaller` | nur Hovers **mit Bild** |
| `>` | n | einen Schritt in das Bild hinein | `zoom_keys.into` | Hovers, deren Bild **zoombar** ist |
| `\|` | n | einen Schritt heraus | `zoom_keys.out` | wie oben |
| `=` | n | zurück zum ganzen Bild | `zoom_keys.reset` | wie oben |
| `<M-n>` | n | zum nächsten Plugin, das zu dieser Stelle etwas zu sagen hat | `position_keys.next` | **nur Position-Hovers**, und nur wenn mehr als ein Beitrag registriert ist |
| `h` | n | vergrößerten Ausschnitt nach links bewegen | `nav_keys.left` | nur solange **gezoomt** |
| `l` | n | nach rechts | `nav_keys.right` | nur solange gezoomt |
| `k` | n | nach oben | `nav_keys.up` | nur solange gezoomt |
| `j` | n | nach unten | `nav_keys.down` | nur solange gezoomt |

Reihenfolge beim Binden: Dismiss vor Open vor Scroll vor Resize vor Zoom vor
Nav — eine Taste, die in zwei Listen steht, wird einmal genommen, und zwar für
die Bedeutung, die immer gilt.

## Owned — buffer-lokal, nur im `:Hover status`-Board

Weder geliehen noch global: diese Tasten leben auf dem Scratch-Buffer des
Boards und verschwinden mit dem Fenster. Nicht konfigurierbar — ausserhalb
dieses Fensters kann sie nichts erreichen, also gibt es nichts einzustellen.

| Key | Mode | Effect |
| --- | --- | --- |
| `<CR>`, `<Space>`, `<2-LeftMouse>` | n | Zeile unterm Cursor umschalten; auf der Mode-Zeile `auto` → `manual` → `off` |
| `+` | n | Zeile an — auf der Mode-Zeile `auto` |
| `-` | n | Zeile aus — auf der Mode-Zeile `off` |
| `<Tab>` / `<S-Tab>` | n | naechste / vorige schaltbare Zeile, Ueberschriften und Leerzeilen uebersprungen |
| `y` | n | das `:Hover ...` dieser Zeile yanken |
| `r` | n | Konfiguration neu lesen und zeichnen |
| `?` | n | Cheatsheet, aus derselben Tabelle erzeugt wie die Bindungen |
| `q`, `<Esc>` | n | Board zu |

Die Winbar zeigt, was hineinpasst, und pinnt `? Keys` — darueber ist der Rest
erreichbar. Keine Kollision mit irgendetwas in dieser Config: der Buffer ist
`nofile`/`wipe` und existiert nur, solange das Board offen ist.

## Kollisionen — was man wissen muss

| Taste | Was währenddessen nicht geht |
| --- | --- |
| `q` | zeichnet kein Makro auf, solange ein Float offen ist |
| `<Esc>` | was sonst darauf liegt, ist geliehen — und wird zurückgegeben |
| `gf` | verdrängt das Vim-Builtin; gewollt, weil das Float die Datei bereits aufgelöst hat, auch truncated und mit `:line:col` |
| `F` | die Rückwärts-Zeichensuche, und genau deshalb ist sie billig: `F` allein wartet auf ein zweites Zeichen und schließt von sich aus nichts ab — es wird also keine fertige Operation verdrängt. `Fx` geht währenddessen nicht; danach wieder wie immer |
| `<C-Down>` / `<C-Up>` | bewusst statt `<M-Down>`/`<M-Up>` (verbreitetes „move line") |
| `h` `j` `k` `l` | **nur während gezoomt** keine Cursorbewegung. Ohne diese Leihe würde `h` über einem vergrößerten Bild den Cursor bewegen und damit das Float wegnehmen |
| `>` `=` | nichts während eines Floats — beides sind **Operatoren**, sie bewegen keinen Cursor und schließen von selbst nicht ab. Danach wieder Einrücken und Ausrichten wie immer |
| `\|` | die Spaltenbewegung, und genau deshalb ist sie geliehen: ungebunden spränge der Cursor auf Spalte 1 und nähme das Float mit (Dismiss hängt an `CursorMoved`) |

**Warum `+`/`-` nur bei Bildern, das Rad aber überall:** das ist eine
Entscheidung über den *Preis* einer Taste, keine über die Fähigkeit — begründet
in `hover.nvim/docs/FEATURES/RESIZE.md`. Praktisch heißt es: auf einem
Text-Hover sind `+` und `-` frei und behalten ihre Zeilenbewegung; der
Tastaturweg dorthin ist `:Hover resize`.

**Und warum der Zoom seit dem 2026-09-03 blanke Tasten hat statt Alt-Akkorde:**
weil ein Akkord, den dieses Terminal nicht sendet, nichts verdrängt **und
nichts tut** — das ist keine billige Taste, sondern eine abwesende. Gemessen:
`:nnoremap <M-z> <Cmd>echo "da"<CR>` druckt auf keinen Druck, an kommt `<Esc>`
gefolgt von `z`, und `z` ist ein which-key-Präfix. `<` schied aus (which-key
normalisiert es zu `<lt>`, während die Zuordnung `<` bleibt → „Recursion
detected"), `-` ebenfalls: das hält `resize_keys.smaller`, Resize wird zuerst
gebunden, und jedes Hover mit Zoom-Taste hat ein Bild — es würde also
**immer** resizen. `:checkhealth hover` meldet diese Überschneidung.
Begründung in `hover.nvim/docs/FEATURES/ZOOM.md`.

## Reservierte Akkorde in dieser Config

Aussage über **diese** Config, nicht über das Plugin.

| Akkord | Status |
| --- | --- |
| `<C-+>` / `<C-->`, `<C-ScrollWheel>` | **ausgeschlossen** — allgemeiner Fenster-Zoom, gehört nicht dem Plugin |
| `<M-->` | **vergeben** an cascade.nvim (Bullet Points) |
| `<M-+>` | frei, aber ohne Partner — ein Regler mit einer Richtung ist keiner |
| `<M-ScrollWheelUp/Down>` | **vergeben** — hover.nvims Default fürs Rad |
| `<M-n>` | **vergeben** — hover.nvims Default fürs Durchblättern der Position-Antworten seit `ac0a372`. **Ungeprüft, ob er hier ankommt**, und nach dem Zoom-Befund unwahrscheinlich: derselbe Akkord-Typ wie `<M-z>`. Test ist eine Minute — `:nnoremap <M-n> :echo "kommt an"<CR>`. Ohne Taste bleibt `:Hover next` |
| `<M-z>` / `<M-Z>` / `<M-R>` | **wieder frei** seit hover.nvim `21c4932` — und zwar frei im Sinne von *unerreichbar*: dieses Terminal sendet keinen Tastatur-Alt-Akkord. `<M-r>` klein gehört NeoTree und bleibt unberührt |
| `>` / `\|` / `=` | **vergeben** — hover.nvims Zoom seit `21c4932`, geliehen nur solange ein zoombares Float steht |
| `F` | **vergeben** — hover.nvims Zen seit `c20191e`, geliehen bei jedem Hover mit Ziel. Kein Akkord, und das ist nach dem Zoom-Befund keine Vorliebe mehr, sondern die Bedingung: dieses Terminal sendet keinen Tastatur-Alt-Akkord |
| `z` | **ausgeschlossen** und war nie ein Kandidat — Präfix (`zz`, `zt`, `zb`, Folds, which-key). Eine geliehene Präfixtaste meldet sich nicht wie eine verdrängte, sie hängt und wartet auf ein Zeichen, das jetzt etwas anderes bedeutet |
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
  `usrcmds.routes()` am 2026-09-04: **vierundzwanzig** Routen, `scroll` ist
  keine). Die Zahl stand hier auf achtzehn und war seit `auto`, `border`,
  `status`-als-Board, `zen` und den beiden `shot`-Schaltern falsch.
- Warum welche Taste an welcher Bedingung hängt, steht im Repo und nicht hier:
  `docs/FEATURES/RESIZE.md` für `+`/`-`/Rad, `docs/FEATURES/ZOOM.md` für
  `h/j/k/l`, `docs/FEATURES/ZEN.md` für `F`.

## Changelog

- 2026-09-04 (2): **`F` legt das Float auf den ganzen Editor** (hover.nvim
  `c20191e`). Geliehen bei jedem Hover mit Ziel — die **weiteste** Bedingung
  in diesem Plugin, und zwar aus demselben Argument, mit dem die engsten
  begründet sind: es zählt, was eine Taste kostet, solange sie geliehen ist.
  `F` ist die Rückwärts-Zeichensuche, wartet allein gedrückt auf ein zweites
  Zeichen und schließt nichts ab — derselbe Handel wie `>` und `=`. Und
  anders als bei `+` ist der Gewinn gerade bei einem **Text**-Hover am
  größten: zwanzig Zeilen werden ~fünfzig.

  `z` war die naheliegende Merkhilfe und schied aus, ohne je Kandidat gewesen
  zu sein: es ist ein Präfix. Eine geliehene Präfixtaste verdrängt nicht, sie
  **verschluckt** — `zz`, `zt`, `zb`, jedes Fold-Kommando, und sie meldet sich
  dabei nicht.

  Zen ist dabei **nicht** „Fenster größer". Jede Vorschau rendert gegen ein
  Budget (`max_lines`/`max_width` entscheiden, wie viele Zeilen gelesen, mit
  welchem DPI eine Seite gerastert, wie groß ein Bild gezeichnet wird), also
  wird das Budget zum Bildschirm und die Vorschau neu gebaut. Ein bloß größer
  geöffnetes Float zeigte dieselben zwanzig Zeilen mit viel Rand.

  **Es pinnt per Default**, und das folgt aus einem Mechanismus, nicht aus
  Geschmack: das Float ist `focusable = false`, der Dismiss hängt an
  `CursorMoved` — ungepinnt schlösse ein bildschirmfüllendes Float beim ersten
  `j`. `zen = { pin = false }` gibt das transiente Verhalten zurück; hier ist
  nichts gesetzt, also Default. Beim Verlassen wird nur ein Pin gelöst, den
  Zen selbst genommen hat.

  Nebenbefund aus demselben Commit: der 📌-Marker im Rahmen ging bei **jedem**
  Re-Render verloren (Titel lebt am Fenster, `float.open` schließt und öffnet
  es neu) — seit es Pinnen gibt. Fiel nicht auf, solange Pinnen eine seltene
  Geste war.

- 2026-09-04: **das `:Hover status`-Board hat eigene Tasten** (hover.nvim,
  dieser Commit) — die ersten *besessenen* Tasten dieses Plugins ueberhaupt,
  und sie widersprechen der Regel darueber nicht: sie sind buffer-lokal auf
  einem Scratch-Buffer, der mit dem Fenster verschwindet, und verdraengen
  daher nichts. Der Grund fuer das Board steht in der Usercmds-Datei; kurz:
  `:Hover links on` schaltet nicht `web links`, weil das `:Hover links web on`
  heisst, und das Board zeigt zu jeder Zeile das Kommando, das sie schaltet.

- 2026-09-03 (2): **der Zoom hat blanke Tasten statt Alt-Akkorde** (hover.nvim
  `21c4932`). `>` hinein, `|` heraus, `=` zurück. Der Grund ist eine Messung
  und keine Geschmacksfrage: `<M-z>` erreicht dieses Terminal nicht — auf
  `:echo` gemappt druckt es nichts, an kommt `<Esc>`+`z`, und which-key geht
  auf dem Fold-Präfix auf. Ein Akkord, der nichts verdrängt und nichts tut,
  ist keine billige Taste.

  Zwei Kandidaten sind ausgeschieden, beide nachgemessen statt vermutet:
  **`<`**, weil which-key es zu `<lt>` normalisiert, während die Zuordnung `<`
  bleibt — daher „Recursion detected"; `|`, `_`, `>` und `=` normalisieren auf
  sich selbst. Und **`-`**, so naheliegend es neben einem `_` aussieht: das
  hält `resize_keys.smaller`, Resize wird vor Zoom gebunden, eine doppelt
  gelistete Taste wird einmal genommen — und jedes Hover, für das eine
  Zoom-Taste gebunden wird, hat ein Bild. Es würde bei **jedem** Druck
  resizen. `:checkhealth hover` meldet die Überschneidung jetzt.

  Nebenwirkung für diese Config: der `zoom_keys`-Workaround im Plugin-Spec ist
  weg, `require("hover").enable()` steht wieder ohne Optionen da.

- 2026-09-03: **`<M-n>` blättert zwischen Position-Antworten** (hover.nvim
  `ac0a372`). Mehrere Plugins können zu *einer* Stelle etwas sagen, und auf
  einem dotted name tun es regelmäßig zwei: documentation.nvim sagt, was das
  Modul ist, insights.nvim, wer es importiert. Bisher gewann der zuerst
  registrierte und der Rest war unsichtbar — entschieden von der
  Ladereihenfolge, also von niemandem.

  Geliehen wird die Taste nur für einen **Position**-Hover und nur, wenn
  überhaupt mehr als ein Beitrag registriert ist. Gezählt werden dabei
  *Registrierungen*, nicht Antworten: herauszufinden, wer antworten *würde*,
  hieße jeden Beitrag bei jedem Hover aufzurufen — genau die Kosten, gegen
  die `on_request` gebaut wurde. Deshalb gibt es auch keinen „2 von 3"-Zähler.

- 2026-09-02 (5): **Zoom-Tasten und `pan` heißt `nav`** (hover.nvim
  `efafb82`). `<M-z>` / `<M-Z>` / `<M-R>` sind neu und geliehen, sobald das
  Bild überhaupt zoombar ist — weiter als die `h/j/k/l`-Bedingung, weil
  Alt-Akkorde nichts verdrängen und `out`/`reset` bei Stufe 0 ohnehin
  ablehnen. `pan_keys` heißen `nav_keys`, die Route `:Hover pan` heißt
  `:Hover nav`; umbenannt statt aliasiert, weil ein Alias für eine umbenannte
  Operation genau der Bug von `bd72836` war.
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
