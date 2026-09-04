# hover.nvim — User Commands Cheatsheet

New repository, 2026-09-01. Extracted from `lib.nvim.hover`, whose
`:Lib hover …` routes this replaces. Those are **gone** as of 2026-09-01
(lib.nvim `5450dd4`): the module, the routes, the `hover` field on
`Lib.NvimUsrCmds.Options` and the `hover = false` line in this config all went
together, so `:Lib hover …` no longer exists in any form.

Built on `lib.nvim.bindings.usercmd.composer`. Registered from
`plugin/hover.lua`, so `:Hover` exists before `setup()` runs and in a session
where nothing turned the hover on — which is the state someone typing
`:Hover mode auto` is most likely to be in.

Source: `lua/hover/bindings/usrcmds.lua` (routes generated from
`lua/hover/switches.lua`)
Docs: `docs/BINDINGS.md`, `doc/hover.txt`, `README.md`

## Routes

| Command | Args | Notes |
| --- | --- | --- |
| `:Hover show` | — | one hover, here, now; ignores every volume switch. Seit language.nvim `b592b9f` **auch eine Übersetzung** des Worts unter dem Cursor — nur hier, nie auf dem automatischen Trigger, weil jede Antwort eine Netzanfrage mit genau diesem Wort ist. Mehrere Antworten zu einer Stelle: `<M-n>` blättert |
| `:Hover status` | — | mode + alle zwölf Switches + `auto_hover`, als **Board**: `<CR>` schaltet die Zeile unterm Cursor, `+`/`-` explizit, `y` yankt das Kommando der Zeile, `?` listet die Tasten. Jede Zeile traegt ihr `:Hover ...` — genau deshalb, siehe Changelog 2026-09-04 |
| `:Hover why` | — | why nothing hovered here — names which gate declined |
| `:Hover next` | — | step to the next plugin with something to say about this place; wraps past the last |
| `:Hover pin` | — | keep this float on screen while the cursor moves away |
| `:Hover auto [type]` | `<type>\|all\|none` | welche Ziel**typen** von selbst öffnen. Omitted: listet, was öffnet und was auf eine Anfrage wartet. Die **zweite Achse** neben den Switches, und die, an der `:Hover links web on` bis `c20191e` still gescheitert ist |
| `:Hover border [style]` | `rounded\|single\|double\|heavy\|ascii\|dashed\|block\|solid\|shadow\|none` | Rahmenstil, wirkt auf das Float, das **schon offen ist** — ein Stil soll probiert und nicht entschieden werden. Omitted: meldet den aktuellen und listet den Rest |
| `:Hover zen [state]` | `on\|off\|toggle` | Float auf (fast) den ganzen Editor, und zurück. **Kein größeres Fenster**: das Budget der Vorschau wird der Bildschirm und die Vorschau neu gebaut, sonst zeigte es dieselben zwanzig Zeilen mit viel Rand. Pinnt per Default — ungepinnt schlösse es beim ersten `j`. Taste `F`, geliehen bei jedem Hover mit Ziel |
| `:Hover resize [direction]` | `bigger\|smaller` | make the hover on screen bigger or smaller. Omitted: **bigger**. **Any** hover — a picture is drawn larger, a text preview shows more lines. Gilt auch **innerhalb** von Zen: `+` ist dort schon an der Decke und wird zurückgenommen, `-` verkleinert, ohne Zen zu beenden |
| `:Hover zoom [direction]` | `in\|out\|reset` | magnify a *detail* of the picture on screen. Omitted: **in**. Bilder **und** PDF-Seiten seit hover.nvim `7fdfc09` — eine Seite wird dabei bei hoeherem DPI neu gerastert statt beschnitten. Ein Schritt kostet ~258 ms (Bild) bzw. 207–752 ms (Seite), also zu langsam zum Gedrueckthalten. Tasten seit `21c4932`: `>` / `\|` / `=`, blank statt Alt-Akkord, weil dieses Terminal keinen sendet |
| `:Hover nav {direction}` | `left\|right\|up\|down` | move the magnified view. Required argument. The keyboard counterpart to the borrowed `h/j/k/l`, which only exist while zoomed and are therefore undiscoverable |
| `:Hover mode [state]` | `auto\|manual\|off` | omitted: reports the current mode |
| `:Hover toggle` | — | off if on, back to `auto` if off |
| `:Hover links [state]` | `on\|off\|toggle` | whether link syntax hovers at all |
| `:Hover links web [state]` | `on\|off\|toggle` | http(s) links. Implies `links on` |
| `:Hover links web fetch [state]` | `on\|off\|toggle` | status code + title + — bei `text/html` — **was die Seite sagt**, seit hover.nvim `9070b5e`. Implies `links web on`. Kein eigener Schalter für den Seitentext: der Body wird ohnehin geladen, kostet also keine zweite Anfrage und keine zweite Disclosure. Zugeschnitten auf den Platz, den das Float hat — deshalb lohnt `F` über einem Link |
| `:Hover links web fetch pdf [state]` | `on\|off\|toggle` | ein Link, dessen Server `application/pdf` antwortet, wird heruntergeladen und als **erste Seite** gezeigt, seit hover.nvim `dbc2b87` — dieselben Blättertasten, derselbe scharfe Zoom, dieselbe pdfport/`pdftoppm`-Pipeline wie ein lokales PDF, denn die Bytes *sind* schon ein PDF. Implies `links web fetch on`, und das ist die **einzige Implikation im Repo, die ein Mechanismus statt einer Politik ist**: der Content-Type des Servers identifiziert den Link, und nur ein Fetch erzeugt einen — nie die Endung im Pfad, denn ein `.pdf`, das auf eine HTML-Fehlerseite 404t, ist häufig. **Kostet eine zweite Anfrage**, und genau die macht den Deckel erst beantwortbar: `links.pdf.max_bytes` (25 MB) statt der 2 MB des Fetch, die für eine Seite richtig und für ein Dokument viel zu klein sind |
| `:Hover links web shot [state]` | `on\|off\|toggle` | die Seite von einem Headless-Chromium rendern lassen und als **Bild** ins Float zeichnen, seit hover.nvim `4e2ebeb`. Implies `links web on` und ausdrücklich **nicht** `fetch`: ein Fetch ist ein `curl`-GET mit 2-MB-Deckel, ein Render **führt die Seite aus** — ihr JavaScript läuft, und jede Subresource, die sie nennt, wird von ihrem Host geholt. Wer `fetch` für einen Statuscode angeschaltet hat, darf davon keinen Browser bekommen |
| `:Hover links web shot eager [state]` | `on\|off\|toggle` | dasselbe für den **automatischen Trigger** statt nur für `:Hover show`. Eigener Schalter, weil `auto_hover.url` es nicht sagen kann: Textvorschau und Screenshot sind derselbe Zieltyp. Gemessen 2026-09-04 auf diesem Rechner: **710/715/735 ms** allein für den Browserstart (`about:blank`, ohne Netz), eine echte Doku-Seite 3,9–19,6 s. Eine Seite mit fünfzig Links ist fünfzig davon |
| `:Hover paths [state]` | `on\|off\|toggle` | bare paths in prose |
| `:Hover paths missing [state]` | `on\|off\|toggle` | mark a path that resolves to nothing |
| `:Hover paths code [state]` | `on\|off\|toggle` | hover a path inside executable code, not just comments and strings. **Default off.** Implies `paths on` |
| `:Hover images [state]` | `on\|off\|toggle` | draw pictures, or describe them |
| `:Hover positions [state]` | `on\|off\|toggle` | whether a plugin may speak about a cursor position that points at nothing |
| `:Hover office [state]` | `on\|off\|toggle` | render office docs via PDF |

Every `state` argument is an `enum`, so it completes. **Omitting it toggles** —
`:Hover links` flips, `:Hover links off` is explicit.

## Notes

- **Routes are generated, not written.** `switch_route(name)` builds one route
  per entry in `hover.switches`; the same table feeds `:Hover status` and the
  `:checkhealth hover` section. A thirteenth switch is one table entry and
  nothing else, and dispatch/completion/docs cannot drift apart. `paths code`
  was the eighth and cost exactly that — one entry plus one name in `ORDER`,
  and `pdf` as the twelfth cost the same again.

  **This has been the repository's recurring bug, three times.** Every place
  that kept its own list of switches by hand eventually fell behind the table
  without anything failing: `route_path` filed a new switch at top level
  instead of under its parent, `switches.effective` reported one as off while
  it was on (so `:Hover status` *and* `:checkhealth` both lied), and a preview
  badge advertised a command that no longer existed. All three are derived
  now. **The same applies to this file** — but see the next entry for what
  can and cannot check it.

- **`:Bindings check` does not cover this table, and it looks like it does.**
  Measured on 2026-09-02: a row was deleted from the table above and both
  `:Bindings check hover.nvim` and the full `:Bindings check` reported *no
  drift*. hover.nvim was loaded and checked — it does not appear under
  "not loaded this session, skipped" — so this is not a gap in coverage but
  in resolution.

  The reason: the checker compares documented commands against
  `nvim_get_commands({})`, which lists **top-level Vim commands only**. This
  plugin registers exactly one, `Hover`; every route above is a composer
  sub-route and is invisible there. All twenty-five rows collapse onto the same
  live name, it exists, and both directions pass trivially.

  So the authority for this table is **`composer.document("Hover")`**, which
  is the mechanical dump of the route tree. Note that it *writes a file* named
  after the command and returns `true` — it does not return the text.

  This is worth a bindings-explorer task: every plugin built on
  `usercmd.composer` has the same blind spot, and a passing check on a rotten
  table is worse than no check.

- **`web` and `fetch` nest under `links` in the command tree** even though
  they are flat entries in the switch table (`route_path()` maps them). The
  tree reads like the implication chain rather than like seven booleans.

- **Implication is upward only.** `fetch` → `web` → `links` on the write side.
  Downward is answered on the *read* side (`config.web_enabled()` is
  `links_enabled() and links.web`), so `:Hover links off` silences web links
  without clearing their flag — turn `links` back on and `web` is as you left
  it.

- **No range, deliberately.** Every route acts on the cursor position or on a
  session-wide switch; neither has a reading over a line range, and a route
  that accepted a range and ignored it would be worse than one that does not.

- **No count.** Nothing here is a motion. The two that are (`scroll(1)` /
  `scroll(-1)`) are keys, not commands, and borrowed ones at that — a count
  prefix typed at a borrowed key is indistinguishable from one meant for the
  mapping it displaced. Noted in the plugin's `docs/ROADMAP.md`.

- **`:Hover why` is the one route that answers about an *absence*.**
  Everything else acts or reports state; this one explains why nothing
  happened, by naming which of the gates declined — mode, a switch, the
  scope gate, no source, no preview, nothing under the cursor. It exists
  because "no float appeared" is the plugin's most common failure mode and
  was, until then, indistinguishable from "the plugin is broken".

- **`:Hover resize` exists for two reasons, and the second one grew.** First,
  the keys are a *borrow*: `+` and `-` are bound only while a hover with a
  picture is on screen, so someone who has never had one open has no way to
  find the feature — and `:Hover` completion is where the rest of this plugin
  is found. Second, since the rename (hover.nvim `8ec5b40`) `+` and `-` are
  deliberately **not** bound for a text hover at all, because they are motions
  there. For text this route *is* the keyboard way in; the wheel is the other.
  It also needs no chord, which matters for the reserved combinations listed
  in the keymaps file.

  It works at all because **entering the command line moves no cursor**: the
  float's dismissal hangs on `CursorMoved`, `InsertEnter`, `BufLeave` and
  `WinScrolled`, and typing `:` fires none of them. That is pinned by a spec
  rather than assumed — if it were false the route would be a command that
  closes the thing it acts on.

  Omitting the direction makes it **bigger**, not "toggle" like the switches:
  a step has no reverse reading, and `smaller` undoes a wrong guess in one
  keypress.

- **`:Hover pin` has no `unpin`.** A pinned float is dismissed the same way
  any float is; a second verb for the reverse would have to be typed *into*
  a window that is deliberately not focused.

- **`positions` guards a different trust boundary than the other switches.**
  The others decide which kind of *target* may hover. This one decides
  whether a registered plugin may speak about a position that points at
  nothing — which is the only class where the content is authored entirely
  elsewhere. With nothing registered it costs nothing: the trigger is not
  installed at all.

- **`paths code` is about *where*, not *what*.** Every other switch decides
  which kind of target may hover. This one decides whether the cursor's
  *position* disqualifies it: off, a spot Treesitter identifies as executable
  code is skipped, so `vim.api.foo` and `a / b` stop opening floats while a
  path in a comment or a string still does. Prose is untouched — no parser, no
  captures, or an unfamiliar capture family all fall through to "look anyway".
  `:Hover show` ignores it entirely.

## Changelog

- 2026-09-04 (5): **`:Hover links web fetch pdf` zeigt einen PDF-Link als
  Seite** (hover.nvim `dbc2b87`). Damit **fuenfundzwanzig** Routen und zwoelf
  Switches. Nichts wird konvertiert — die Bytes am anderen Ende sind bereits
  ein PDF und gehen in dieselbe pdfport/`pdftoppm`-Pipeline wie ein lokales.

  **Zwei Vorhersagen aus dem Handover waren falsch, und beide klangen gut.**
  Erstens „die Bytes sind schon da": der Body-Cache haelt sie, aber
  `lib.nvim.net.curl` laeuft mit `vim.system(..., { text = true })`, und das
  ersetzt CRLF durch LF. Fuer HTML unsichtbar, fuer ein PDF toedlich — was
  ankaeme, oeffnet `pdftoppm` nicht, und der Fehler saehe aus wie ein kaputter
  Renderer. Also `curl -o` an Lua vorbei. Zweitens „es braucht keinen
  Schalter": folgte aus dem ersten und faellt mit ihm.

  Die zweite Anfrage ist zugleich das, was den **Groessendeckel** erst
  beantwortbar macht: der Content-Type ist erst nach der ersten Antwort
  bekannt, also kann *eine* Anfrage nicht die 2 MB fuer eine Seite und die
  25 MB fuer ein Dokument zugleich tragen.

  Blaettern und Zoomen brauchten **ein Feld und sonst nichts**: `scroll` und
  `zoom` leiteten „ist das geblaettert" aus `target.type == "pdf"` ab, was ein
  Stellvertreter war und aufhoerte, ein genauer zu sein, sobald ein *Link* mit
  einem PDF antworten kann. `present` merkt sich das jetzt aus dem Inhalt.

- 2026-09-04 (4): **`:Hover links web shot` rendert die Seite** (hover.nvim
  `4e2ebeb`). Damit **vierundzwanzig** Routen. Ein Headless-Chromium legt die
  Seite auf 1280x900 aus, schiesst ein PNG, und ab da ist es ein Bild wie
  jedes andere — dieselbe Canvas-Groesse, dasselbe Zeichnen, derselbe
  `>`-Crop, dasselbe `h/j/k/l`.

  **Die Kategoriegrenze ist der ganze Entwurf**, und sie laeuft nicht zwischen
  „leise" und „laut": ein Fetch ist ein `curl`-GET, ein Render fuehrt die
  Seite aus. Deshalb impliziert `shot` **`web`** und niemals `fetch`.

  Zwei Sicherungen, die hier stehen sollen, weil sie beim naechsten Lesen
  nicht offensichtlich sind. Erstens **`--user-data-dir` auf ein
  Wegwerf-Verzeichnis**: ohne das kann ein Headless-Chrome das *echte* Profil
  oeffnen — die eigenen Cookies gingen an den gehoverten Host, und was man
  eingeloggt sieht, waere im Bild. Zweitens **kein `--no-sandbox`**: die
  Seite ist per Konstruktion nicht vertrauenswuerdig, und die Sandbox ist
  genau das, was zwischen ihr und dem Rechner steht.

  Auf diesem Rechner relevant: **Chrome ist installiert und auf keinem PATH**
  (`C:\Program Files\Google\Chrome\Application\chrome.exe`, gemessen). Der
  Previewer sucht die ueblichen Installationsorte selbst und findet ihn;
  `:checkhealth hover` nennt die Binary, die er starten wuerde, und sagt
  dazu, dass die `chrome NOT found`-Zeile aus dem deps-Abschnitt darunter
  erwartet ist. `links.shot.command` benennt eine direkt.

  Default-Capture ist 900 px hoch und nicht die ganze Seite: ein Bild wird
  ins Float einpasst, also entscheidet der Einpassfaktor. 1280x900 passt in
  ein Zen-Float mit ~1,0 (16-px-Text bleibt 16 px), 1280x4000 ist auf 0,24
  hoehenbegrenzt (dieselben 16 px werden 4 px). Wer die ganze Seite will,
  stellt `height` hoch und liest mit `>` — der Zoom schneidet.

- 2026-09-04 (3): **`:Hover zen`, und die zweite Achse sagt endlich etwas**
  (hover.nvim `c20191e`). Damit sind es **zweiundzwanzig** Routen — die Zahl
  stand in der Keymaps-Datei noch auf achtzehn und war seit `auto`, `border`
  und dem Board falsch. `:Hover auto` und `:Hover border` fehlten in dieser
  Tabelle **ganz** und sind jetzt drin.

  Der eigentliche Fund ist aber der Schalter, nicht die Route. `:Hover links
  web on` meldete „web links hover" — und nichts hoverte, weil
  `auto_hover.url` auf `false` steht. Beide Aussagen waren wahr: Web-Links
  hovern, und der Trigger öffnet sie nicht. Genau deshalb las es sich als
  kaputtes Feature, und genau deshalb ist die **Ansage** die Stelle zum
  Reparieren — man schaut in dem Moment auf genau eine Zeile, und es war die
  falsche.

  Ein Switch darf jetzt den `auto_hover`-Namen nennen, den er produziert
  (`web`/`fetch` → `url`, `missing`, `office`, `positions` → `position`), und
  `switches.on_report` hängt „…aber `url` öffnet noch nicht von selbst:
  `:Hover auto url`" an. **Nicht** in `implies` gefaltet: Implikation läuft
  zwischen Switches, die „darf das überhaupt hovern" beantworten;
  `auto_hover` beantwortet „darf es *ungefragt* öffnen", und ein Switch, der
  das still umlegt, kippt eine stehende Präferenz.

  `:Hover why` kannte das Gate ebenfalls nicht — das eine Kommando, das
  „warum passiert nichts" beantworten soll, antwortete „this should hover. If
  it does not, that is a bug worth reporting." Nennt es jetzt. `:checkhealth`
  bekommt dafür einen dritten Zustand (`on, url on request`), und die
  Nachrichten-Fallback-Form von `:Hover status` trägt den `auto`-Abschnitt,
  den das Board seit dem Vortag zeichnet.

  Praktisch heißt das hier: **`:Hover links web on` allein reicht nicht**, es
  gehört `:Hover auto url` dazu — oder `:Hover show` auf dem Link.

- 2026-09-04 (2): **Seitentext im Fetch-Preview** (hover.nvim `9070b5e`).
  `links.fetch` las den Body für `<title>` und `<meta description>`, zeigte
  zwei Zeilen daraus und warf den Rest weg. Jetzt wird er zu Prosa:
  `<main>`/`<article>` bevorzugt, `nav`/`header`/`footer`/`script`/`style`
  samt Inhalt raus, Listen behalten ihren Punkt, Block-Elemente ihren
  Umbruch, Entities werden aufgelöst, umgebrochen wird auf die Boxbreite.
  Kein dritter Schalter — der Body ist schon da.

- 2026-09-04: **`:Hover status` ist ein Board** (hover.nvim, dieser Commit).
  Anlass war eine konkrete Verwechslung an diesem Rechner: `:Hover status`
  sagte `link targets on` / `web links off`, darauf `:Hover links on` getippt
  — und `web links` blieb off. Nichts war kaputt. `web` ist ein **eigener**
  Switch und haengt im Kommandobaum unter `links`, das Kommando heisst
  `:Hover links web on`. Label und Route waren zwei verschiedene Strings, und
  nur einer davon stand auf dem Schirm.

  Deshalb traegt jetzt **jede Zeile ihr Kommando**, und die Einrueckung *ist*
  die Implikationskette. Die Route kommt aus `switches.route()`, das aus
  `usrcmds` dorthin gewandert ist — zwei Leser, eine Ableitung, sonst waere es
  der `route_path`-Bug eine Datei weiter.

  Drei Glyphen statt zwei: `●` on, `○` off, `◐` *hier gesetzt, oben
  abgeschaltet*. Das ist der Zustand, den eine flache on/off-Liste strukturell
  nicht sagen kann — `web = true` bei `links = false` las sich als schlichtes
  `off`, und das Wiedereinschalten von `links` sah dann aus, als schalte es
  etwas ein, das niemand wollte.

  Tasten (buffer-lokal, verschwinden mit dem Fenster, nicht konfigurierbar):
  `<CR>`/`<Space>`/`<2-LeftMouse>` toggle, `+` on, `-` off, `<Tab>`/`<S-Tab>`
  zur naechsten/vorigen schaltbaren Zeile, `y` yank, `r` neu lesen, `?`
  Cheatsheet, `q`/`<Esc>` zu. Winbar-Legende und `?`-Panel werden aus
  **derselben** Tabelle erzeugt, aus der die Tasten gebunden werden — Vorlage
  war reposcope.nvims `status_view`, gleiche Form fuer dasselbe Problem.

  Ebenfalls neu auf dem Board: `auto_hover` als dritter Abschnitt. `mode`,
  Switches und „was oeffnet von selbst" sind drei verschiedene Gruende, aus
  denen nichts hovert, und sie sahen von aussen identisch aus.
  `hover.status()` gibt jetzt `{ mode, switches, auto }` zurueck, jeder Switch
  mit `enabled` (Kette eingerechnet), `flag` (eigener Wert) und `route`.

  Ohne lib.nvims UI-Kit faellt es auf die Nachricht zurueck — die traegt seit
  demselben Commit ebenfalls die Routen statt nur der Labels.

- 2026-09-03: **`:Hover next` added** (hover.nvim `ac0a372`), the
  borrow-free half of `<M-n>`. Seventeen routes now. It steps between the
  plugins that answer for one *place* — until then the first registered one
  won and the rest were invisible, which plugin load order decided. Stepped
  rather than merged: `Hover.Content` is shaped for one answer, so two would
  mean two titles for one border and two filetypes for one highlight, and a
  picture cannot be merged with text at all.

- 2026-09-02 (4): **`:Hover pan` heißt `:Hover nav`** (hover.nvim `efafb82`).
  Weiter achtzehn Routen. Umbenannt statt aliasiert: `pan` ist das präzisere
  Wort für die Operation und das falsche für ein Verb, das jemand tippt — und
  ein Alias für eine umbenannte Operation ist genau der Bug von `bd72836`. Der
  Name war einen Tag alt.

- 2026-09-02 (3): **`:Hover zoom` und `:Hover pan` fehlten hier ganz** — seit
  hover.nvim `9fba190`. Damit sind es **achtzehn** Routen, nicht sechzehn.
  `zoom` ist nicht die alte Route unter altem Namen, sondern ein anderes
  Feature auf dem freigewordenen Wort: gleiche Kiste, Ausschnitt aus der
  Quelle, nur für Bilder, ~258 ms je Schritt.

- 2026-09-02 (2): **`hover.zoom()` ist kein Alias mehr** (hover.nvim
  `bd72836`) — und war seit `9fba190` auch keiner. Dort entstand ein echtes
  `M.zoom` als zweite Definition desselben Namens, und Lua nimmt die zweite;
  der Alias war ab dem Tag tot, ohne dass etwas fehlschlug. Der Eintrag
  darunter behauptet ihn noch — er bleibt stehen, weil er beschreibt, was
  damals stimmte.

- 2026-09-02: **`:Hover zoom` heißt `:Hover resize`** (hover.nvim `8ec5b40`),
  und die Argumente `in|out` heißen `bigger|smaller`. Immer noch sechzehn
  Routen. Der Grund ist kein Namensgeschmack: `zoom` las genau *ein* Feld,
  und das multiplizierte `max_width`/`max_lines` für eine Vorschau — also
  „größere Kiste, ganzes Bild hineinskaliert", nie ein Ausschnitt. Damit hat
  die Operation auch für Text eine Antwort (mehr Zeilen), und die Route gilt
  jetzt für **jeden** Hover statt nur für gezeichnete. `zoom_keys` wird von
  `config.normalize()` gefaltet, `hover.zoom()` bleibt als Alias.

- 2026-09-02: **`:Hover zoom [in|out]` added** (hover.nvim `2493e1b`). Sixteen
  routes now. Zoom itself shipped with `204d083` as borrowed keys only; this
  is the reachable-without-a-float-open half. Also corrected in the keymaps
  file: that one said a route existed for `scroll` and not for zoom — there is
  **no** `:Hover scroll` either, and there never was.

- 2026-09-02: three routes were missing here entirely — `:Hover why`,
  `:Hover pin` and `:Hover positions`. The file documented 7 of 15
  invocations and called the switch count eight when it was nine. Rebuilt
  against `composer.document("Hover")`, which is the mechanical dump, rather
  than against the README.
- 2026-09-01: `:Hover paths code` added (hover.nvim `b2b4b2c`) — eighth
  switch, default off. `:Hover status` now lists eight.
- 2026-09-01: `:Lib hover …` is gone rather than merely switched off —
  lib.nvim `5450dd4` deleted the module the routes drove.
