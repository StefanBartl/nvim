# Handover — hover.nvim: Website-Screenshot-Preview & Zen-Mode

**Repo:** `$REPOS_DIR\hover.nvim` (branch `main`, Remote `StefanBartl/hover.nvim`)
**Datum:** 2026-09-04, Stand fortgeschrieben am 2026-09-04 (4)
**Status:** **alles aus diesem Handover ist gebaut, einschließlich Abschnitt 6**
— der `auto_hover`-Bugfix (`c20191e`), Zen (`c20191e`), der Seitentext
(`9070b5e`), der Body-Cache (`6ebd232`), der Screenshot (`4e2ebeb`) und die
PDF-Links (`dbc2b87`). **Nichts ist mehr offen.** Was bleibt, ist eine
Handprüfung: die PDF-Link-Zeile in `MANUAL-EVIDENCE.md` steht auf *never*.

---

## 0. Ausgangslage — erledigt, mit einer Korrektur

**Der Pfad in der ersten Fassung war falsch.** Es gibt kein `$REPOS_DIR\hover.nvim`; das
Repo liegt auf `$REPOS_DIR\hover.nvim`, und dort war der Working Tree **sauber**. Die elf
uncommitteten Dateien der Session vom 2026-09-04 existierten in diesem Checkout nicht —
nachgeprüft, nicht vermutet: kein `M.page_text` in `preview/url.lua`, kein `auto_type` in
`switches.lua`, kein `TESTS/url_spec.lua`. Diese Arbeit war weg und ist neu geschrieben
worden.

Testlauf (die beiden env-Variablen werden nicht automatisch gefunden):

```bash
LIB_NVIM_DIR=/e/repos/lib.nvim PLENARY_DIR=/c/Users/bartl/AppData/Local/nvim-data/lazy/plenary.nvim HOVER_ALLOW_PENDING=1 bash scripts/test.sh
```

**(a) Der `auto_hover`-Bug — behoben, `c20191e`.** Ein Switch darf jetzt den
`auto_hover`-Namen deklarieren, den er produziert (`auto_type`: `web`/`fetch` → `url`,
`missing`, `office`, `positions` → `position`). `switches.on_report` hängt beim
Einschalten „…aber `url` öffnet noch nicht von selbst: `:Hover auto url`" an, `:Hover why`
nennt das Gate an der Cursorposition, `:checkhealth` bekommt dafür einen dritten Zustand
(`on, url on request`), und die Nachrichten-Fallback-Form von `:Hover status` trägt den
`auto`-Abschnitt, den das Board schon zeichnete. Vier Docs korrigiert.

Bewusst **nicht** in `implies` gefaltet: Implikation läuft zwischen Switches, die „darf das
überhaupt hovern" beantworten; `auto_hover` beantwortet „darf es *ungefragt* öffnen", und
ein Switch, der das still umlegt, kippt eine stehende Präferenz.

**(b) Seitentext im Fetch-Preview — gebaut, `9070b5e`.** `M.page_text` in
`lua/hover/preview/url.lua`, wie entworfen, plus Umbruch auf die Boxbreite (nötig, weil
`float.measure` Listeneinträge zählt und nicht Bildschirmzeilen). Kein eigener Schalter.
Zugeschnitten auf den *Rest* des Budgets, das der Aufrufer trägt — also zeigt `F` über
einem gefetchten Link eine Bildschirmseite statt zwanzig Zeilen.

Zwei Reihenfolge-Fehler haben die Specs gefunden, beide still: Kommentare wurden **nach**
dem `<main>`-Extrakt entfernt (ein auskommentiertes `</main>` beendete den Extrakt an einer
Grenze, die niemand geschrieben hat), und Quell-Whitespace wurde erst **nach** dem Einfügen
der Umbrüche kollabiert (ein eingerückter Absatz kam als fünf Zeilen an).

**Testlage:** 344 Specs grün, `stylua --check` sauber.

---

## 1. Reihenfolge-Empfehlung: Zen zuerst, Screenshot danach

Das ist keine Geschmacksfrage, sondern folgt aus einer Messung. Ein Screenshot ist
1280×900 px. Ein Default-Float ist 80×20 Zellen ≈ 640×340 px. Der Einpass-Faktor ist
**höhenbegrenzt auf ~0,38** — 16-px-Fließtext wird ~6 px. **Unlesbar.**

Ohne Zen-Mode ist die Screenshot-Preview also ein Feature, das man nach jedem Öffnen
erst zurechtzoomen muss. Zen zuerst gebaut macht sie überhaupt erst brauchbar — und Zen
nützt sofort auch Bildern, PDFs und Office-Dokumenten, die dasselbe Problem in
schwächerer Form haben.

---

## 2. Feature B — **gebaut** (`c20191e`)

Der Entwurf unten steht so, wie er beschlossen wurde; was davon abweicht, steht hier.
Ausführlich in `hover.nvim/docs/FEATURES/ZEN.md`, Specs in `TESTS/zen_spec.lua` (19).

- **Route** `:Hover zen [on|off|toggle]`, **Taste** `F` (`zen_keys.toggle`), geliehen bei
  jedem Hover **mit Ziel**. Position-Hovers bekommen sie nicht: Zen kann dort nur ablehnen,
  und eine Taste, die auf eine Absage gebunden ist, ist schlechter als eine ungebundene.
- **Budget statt Fenster.** `box()` in `init.lua` ist die eine Stelle, die Resize-Faktor
  *und* Zen-Basis kennt; `present` und `current_preview_opts` lesen beide daraus. Sie
  hatten vorher **zwei** Ableitungen derselben Zahl — genau die Form, an der dieses Repo
  schon einmal hängengeblieben ist.
- **Offene Frage 1 (`-` im Zen) — entschieden: verkleinert innerhalb.** Und zwar ohne
  eigenen Code: die Zen-Basis ist `columns - 4` / `lines - 4`, also genau die Decke, gegen
  die `float.size_for` ohnehin klemmt. `+` erzeugt dasselbe Float, `resize` sieht das und
  nimmt seinen Schritt zurück; `-` verkleinert. Zen endet, wenn man es sagt.
- **Offene Frage 2 (Cursor/Pin) — entschieden: Zen pinnt, konfigurierbar.**
  `zen = { pin = true }` per Default, weil das Float `focusable = false` ist und der
  Dismiss an `CursorMoved` hängt: ungepinnt schlösse ein bildschirmfüllendes Float beim
  ersten `j`. `zen.pin = false` gibt das transiente Verhalten zurück. Beim Verlassen wird
  **nur ein Pin gelöst, den Zen selbst genommen hat**.
- **Offene Frage 3 (eigene Taste vs. „resize bis es nicht mehr geht") — eigene Taste.**
  Gemessen: 210×55 hat Platz für fünf Schritte, 80×24 für **keinen**. „Vollbild" ist auf
  beiden ein Druck; „`+` bis es aufhört" ist auf einem fünf Drücke und auf dem anderen
  ein No-op. Und der Rückweg muss auch ein Druck sein.
- **Offene Frage 4 (Route *und* Taste) — beides**, nach der Hausregel.
- **Taste:** `F`, nicht `z`. `z` ist ein **Präfix** — die Leihe verschluckte `zz`, `zt`,
  `zb` und jedes Fold-Kommando, und ein verschlucktes Präfix meldet sich nicht wie eine
  verdrängte Taste, es hängt. `F` ist die Rückwärts-Zeichensuche: allein gedrückt wartet
  sie auf ein zweites Zeichen und schließt nichts ab, kostet also nichts, solange das
  Float steht — derselbe Handel wie `>` und `=`.
- **Position:** zentriert, über `opts.center` in `float.open`. Die einzige Stelle, an der
  ein Hover absichtlich nicht neben dem steht, was er beschreibt.
- **Nebenbefund, mitrepariert:** der 📌-Marker ging bei **jedem** Re-Render verloren (Titel
  lebt am Fenster, `float.open` schließt und öffnet neu) — seit es Pinnen gibt. Fiel nicht
  auf, solange Pinnen selten war; Zen pinnt per Default und machte es zum Normalfall.

### Was noch offen ist, hier notiert statt gebaut

**Ein gefetchter Link wird bei jedem `F`/`+`/`-` neu geholt.** `rerender` umgeht den
Preview-Cache (er ist nach Ziel-Identität verschlüsselt, nicht nach Boxgröße) und ruft
`build` direkt, und für `type == "url"` heißt das `url.fetch` — also eine zweite
HTTP-Anfrage an denselben Host. Das gilt schon länger für `:Hover resize`; Zen macht es
nur wahrscheinlich, weil `F` über einem Link jetzt die Geste ist, die sich lohnt. Ein
Session-Cache für den Body in `preview/url.lua` (Key: URL) wäre ~15 Zeilen und würde es
beseitigen. Nicht gebaut, weil es außerhalb des Auftrags lag.

### Der ursprüngliche Entwurf (zur Nachvollziehbarkeit)

### Was

Ein Kommando und eine geborgte Taste, die den offenen Float auf (fast) den ganzen Editor
aufziehen — und wieder zurück. Gilt für **alle** Preview-Typen, nicht nur für Websites:
Bild, PDF, Office-Seite, und Text (der dann einfach *mehr Zeilen* zeigt).

### Der Punkt, den man nicht übersehen darf

**Zen ist nicht „das Fenster größer machen".** Die Previewer rendern gegen ein Budget:
`preview_opts.max_lines` / `max_width` entscheiden, wie viele Zeilen gelesen, wie groß
eine PDF-Seite rasterisiert und wie groß ein Bild gezeichnet wird. Ein Float, der nur
größer aufgeht, zeigt dieselben 20 Zeilen mit viel Rand.

Zen muss also **neu rendern** mit einem Budget, das aus der Editorgröße kommt. Genau das
tut `M.resize` schon — nur mit einem Faktor statt mit einem Ziel.

### Vorhandene Nahtstellen (alles in `lua/hover/init.lua`)

| Stelle | Was sie ist |
| --- | --- |
| `RESIZE_STEP = 1.25` (Zeile 74) | Der Schrittfaktor |
| `resize_factor()` (Zeile 92) | `RESIZE_STEP ^ _open.resize` |
| `current_preview_opts()` (Zeile ~1086) | **Die eine Stelle**, die Scroll-Offset, Page, Resize-Level und Zoom in die Preview-Optionen faltet. Ihr eigener Doc-Kommentar sagt: „adding a fifth piece of state is one line rather than four." Zen ist dieses fünfte Stück. |
| `present()` → `scaled()` + `float.open` (Zeilen ~500–513) | Wo `max_width`/`max_height` ans Fenster gehen |
| `_open = { target = …, offset = 0, page = 1 }` (Zeile ~652) | Der State-Table, der `zen = true` bekäme |
| `M.resize(delta)` (Zeile ~1215) | Das Vorbild: Level ändern → `current_preview_opts()` → `build` → Cache umgehen → neu zeichnen |
| `float.measure` / `size_for` in `float.lua` (~Zeile 235) | Klemmt schon auf `vim.o.columns - 4` bzw. `vim.o.lines - 4` |

### Entwurf

- **State:** `_open.zen = true|false`.
- **Budget:** in `current_preview_opts()` und in `present`s `scaled()` — wenn `zen`, dann
  nicht `configured × factor`, sondern `vim.o.columns - margin` / `vim.o.lines - margin`.
  Der Resize-Level bleibt daneben bestehen, damit `-` aus dem Zen heraus wieder
  verkleinert (oder Zen beendet — Entscheidung offen, siehe unten).
- **Route:** `:Hover zen` (toggelt). Passt zu `:Hover pin`, das dieselbe Form hat
  („dieser Float gehört jetzt mir").
- **Taste:** geborgt, solange ein Float offen ist — über `keys.borrow` in `present`,
  konfigurierbar wie `zoom_keys`/`resize_keys`. **Achtung:** neue Key-Tabellen müssen
  `*_keys` heißen, dann greift `replace_key_lists` in `config/init.lua` automatisch
  (Regel: jeder `DEFAULTS`-Eintrag auf `_keys` plus `keymaps`).
- **Orthogonal zu `pin`:** beides sind eigene Flags auf `_open`, beide dürfen gleichzeitig
  an sein. Zen ohne Pin ist sinnvoll (Cursor bewegen schließt es), Zen mit Pin auch.
- **Position:** im Zen sollte der Float zentriert stehen, nicht am Cursor. `float.open`
  positioniert heute am Cursor — das ist der einzige Teil, der wirklich neu ist.

### Offene Fragen

1. Beendet `-` (resize kleiner) den Zen-Mode, oder verkleinert es innerhalb davon?
2. Schließt Cursor-Bewegung einen Zen-Float, oder impliziert Zen ein Pin?
3. Eigene Taste, oder ein weiterer Schritt von `resize` „bis es nicht mehr geht"?
   (Gegen Letzteres: `resize` steppt schon bis zum Bildschirmrand — ein Zen wäre dann
   nur „mehrmals `+` drücken". Dafür: kein neues Konzept.)
4. Braucht es `:Hover zen` überhaupt als Route, wenn eine Taste reicht? Hausregel im Repo:
   Routen existieren neben Tasten, „because a borrow is undiscoverable until it has been
   seen once" (`docs/commands.md`) — also ja, beides.

---

## 3. Feature A — **gebaut** (`4e2ebeb`)

Ausführlich in `hover.nvim/docs/FEATURES/SHOT.md`, Specs in `TESTS/shot_spec.lua` (20).
Der Entwurf unten steht unverändert; was davon abweicht, steht hier.

**Zwei Messwerte haben den Entwurf geändert, und beide waren im Handover anders.**

| | Handover | hier gemessen (2026-09-04, drei Läufe) |
| --- | --- | --- |
| Browserstart allein | 356 ms | **710 / 715 / 735 ms** |
| Chrome-Pfad | Chrome *und* Edge | nur Chrome, Edge nicht am genannten Ort |

Der Handover-Rechner war offenbar ein anderer — was zum falschen Repo-Pfad passt. Der
doppelte Startpreis stützt den Trigger-Schutz zusätzlich.

- **Config-Shape** wie entworfen, plus zwei Felder: `delay_ms` (die eigene Debounce, die
  der Entwurf verlangt, aber nicht benannt hat) und `command` (Browser direkt benennen).
- **`enabled` heißt `enabled`, `auto` heißt `eager`.** Route: `:Hover links web shot` und
  `:Hover links web shot eager`. `auto` als Switch-Name ging nicht — ein Switch, der
  etwas impliziert, darf nach `TESTS/switches_spec.lua` nicht auch als Top-Level-Route
  existieren, und `:Hover auto` existiert.
- **`height = 900`, nicht 4000.** Der Entwurf wollte eine Vollseite, damit `nav` sie
  abfährt. Gegenrechnung: ein Bild wird *eingepasst*, nicht beschnitten — 1280×900 passt
  in ein Zen-Float mit ~1,0 (16-px-Text bleibt 16 px), 1280×4000 ist auf 0,24
  höhenbegrenzt (4 px). Wer die Vollseite will, stellt `height` hoch und liest mit `>`.
- **Zoom war nicht geschenkt.** `can_magnify` und `zoomable` hingen an `target.path`, das
  ein URL-Target nicht hat. Sie fragen jetzt `shot.cached` — nur Cache, nie ein Browser,
  weil „ist das zoombar" keine Zwanzig-Sekunden-Antwort haben darf.
- **Offene Frage 1 (ersetzt oder beide) — ersetzt, beide über den Schalter.** `shot on`
  → Bild, `shot off` → Text. Das Float ist ein Canvas, also ohne Statuszeile.
- **Offene Frage 2 (Browsersuche) — PATH zuerst, dann die üblichen Installationsorte**,
  Reihenfolge chrome → chromium → brave → msedge, und über `links.shot.command`
  überschreibbar.
- **Offene Frage 3 (`--virtual-time-budget` vs. CDP) — Budget.** Gemessen: die Probe-Seite
  rendert in 768 ms bei Budget 5000, das Budget ist also keine Wartezeit. CDP wäre ein
  Socket und deutlich mehr Code für eine Vorschau.
- **Offene Frage 4 (ohne images.nvim) — verweigert und sagt warum**, und zwar *vor* dem
  Browserstart: ein Render in eine Datei, die niemand sehen kann, sind zwanzig Sekunden
  für nichts.

**Zwei Sicherungen, die im Entwurf nicht standen und nicht optional sind:**

1. **`--user-data-dir` auf ein Wegwerf-Verzeichnis.** Ohne das kann ein Headless-Chrome
   das *echte* Profil öffnen — die Cookies des Lesers gingen an den gehoverten Host, und
   was er eingeloggt sieht, wäre im Bild. Das ist der Unterschied zwischen „diese Seite
   rendern" und „diese Seite als ich rendern".
2. **Kein `--no-sandbox`.** Das übliche Mittel gegen einen Browser, der im Container nicht
   startet, und hier genau falsch: die Seite ist per Konstruktion nicht vertrauenswürdig.

### Der ursprüngliche Entwurf (zur Nachvollziehbarkeit)

## 3. Feature A: Website-Screenshot als Preview

### Was

Statt (oder neben) dem Textauszug: die Seite mit einem Headless-Browser rendern, als PNG
abgreifen, und über die **vorhandene** Bild-Pipeline in den Float zeichnen. Zoom
(`media.zoomed`, croppt) und Pan (`nav`) funktionieren dann geschenkt.

### Messwerte (2026-09-04, diese Workstation, Chrome headless)

Gemessen an `https://docs.tricentis.com/tosca-cloud/en-us/content/create_tests/shared_assets.htm`.

| Messung | Zeit |
| --- | --- |
| Chrome-Start allein (`about:blank`) | **356 ms** |
| Seite, `--virtual-time-budget=500` | 3 911 ms |
| Seite, Budget 5000 — drei Läufe | 4 713 / 6 067 / 5 544 ms |
| Seite, Budget 1500 | **19 624 ms** |
| Vollseite `--window-size=1280,4000` | 4 976 ms, 1280×4000 px, 306 KB |

**Der entscheidende Befund:** Chrome zu starten kostet 356 ms — der Rest ist die Seite
selbst (JS, Subresources, Fonts, Tracker). Und es ist **unvorhersehbar**: dieselbe URL,
einmal 3,9 s, einmal 19,6 s. Ein `curl`-Fetch derselben Seite ist so schnell, dass die
250 ms `placeholder_grace_ms` nicht mal greifen.

Vorhandene Binaries auf dieser Maschine:
`C:\Program Files\Google\Chrome\Application\chrome.exe` und
`C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe`.

Aufruf, der funktioniert hat:

```
chrome --headless=new --disable-gpu --hide-scrollbars --virtual-time-budget=5000 \
       --window-size=1280,900 --screenshot=OUT.png URL
```

### Entscheidung des Users (2026-09-04)

**Auto-Trigger: ja, und es muss änderbar sein.** Ich hatte `:Hover show`-only empfohlen
(Begründung unten); der User hat das überstimmt. Das ist so umzusetzen — mit den
Schutzmaßnahmen aus dem nächsten Abschnitt.

### Meine Bedenken, fürs Protokoll

Nicht als Einspruch, sondern damit sie beim Bauen nicht neu erarbeitet werden müssen:

1. **Sicherheit — der eigentliche Punkt.** `fetch` ist heute *ein* `curl`-GET, kein
   JavaScript, 2 MB Cap. Ein Screenshot heißt: die Seite wird **ausgeführt** — JS von
   jedem gehoverten Link, plus alle Subresources an alle Dritthosts. Das ist keine
   Abstufung von `fetch`, sondern eine andere Kategorie. **Darf deshalb nie von `fetch`
   impliziert werden.**
2. **Latenz am Auto-Trigger.** Bei 4–20 s pro Seite startet ein Dokument mit fünfzig
   Links beim Durchscrollen fünfzig Chrome-Prozesse. Das Repo hat dafür ein Präzedenz:
   `bare_git` ist `force`-only, **weil es 41 ms kostet**
   (`lua/hover/bare_git.lua`, und der
   `if force then`-Zweig in `init.lua` ~Zeile 264).
3. **Lesbarkeit** — siehe Abschnitt 1, deshalb Zen zuerst.

### Entwurf

**Config-Shape**, nach dem Vorbild von `office` (`lua/hover/config/DEFAULTS.lua`):

```lua
links = {
  shot = {
    enabled    = false,   -- der Schalter
    auto       = false,   -- ob der Auto-Trigger ihn auslösen darf  <- die "änderbar"-Anforderung
    timeout_ms = 15000,   -- gemessen: 4-20 s, also großzügig wie office.timeout_ms = 60000
    width      = 1280,
    height     = 4000,    -- Vollseite, damit nav/pan die ganze Seite abfährt
    cache_days = 7,       -- wie office.cache_days
  },
}
```

`auto` als **eigenes Feld neben `enabled`** ist der Kern der Anforderung: `auto_hover.url`
kann es nicht leisten, weil Textauszug und Screenshot denselben Target-Typ (`url`) haben —
„Text automatisch, Screenshot nur auf Anfrage" wäre sonst nicht sagbar.

**Schalter** in `lua/hover/switches.lua`:
ein Eintrag in `SWITCHES`, `implies = "web"` (nicht `"fetch"` — andere Kostenachse),
`auto_type = "url"`. Route wird daraus abgeleitet: `:Hover links web shot`.
Das `on_msg` muss die Disclosure beim Namen nennen, so wie `fetch` es tut.

**Dependency** in `docs/install.json`
deklarieren (`chrome` / `chromium` / `msedge`), `required: false`, mit `pkg`-Einträgen —
dann meldet `:checkhealth hover` es über `lib.nvim.deps` wie `soffice` und `pdftoppm`.
**Windows-Hinweis nicht vergessen:** Chrome ist nicht auf der PATH, es muss über die
bekannten Installationspfade gesucht werden (siehe die `soffice`-`why`-Notiz in
`install.json`, dort steht dasselbe Problem schon beschrieben).

**Async + Cache:** `lua/hover/preview/office.lua`
ist die Vorlage und erfüllt exakt denselben Vertrag — „gib zurück, was *jetzt* zu zeigen
ist (final oder `pending`), und ruf `on_result` wenn das Echte da ist". `build_async` in
`init.lua:334` und `placeholder_grace_ms` regeln den Rest. Der On-Disk-Cache dort ist das
Muster für den Screenshot-Cache; Key ist die URL, nicht Pfad+mtime.

**Trigger-Schutz** (weil Auto-Trigger gewünscht ist):
- eigener, deutlich längerer Debounce als `delay_ms = 250` — 4–20 s Arbeit hinter 250 ms
  Ruhe zu hängen ist zu wenig;
- Cache-Treffer müssen *vor* dem Browserstart geprüft werden;
- höchstens ein laufender Browser-Prozess gleichzeitig; ein zweiter Hover bricht den
  ersten ab (das Generation-Muster aus `build_async` deckt das Verwerfen schon ab, aber
  der Prozess muss auch wirklich getötet werden);
- die `_generation`-Prüfung ist Pflicht, sonst öffnet ein 19-Sekunden-Screenshot einen
  Float über einer Zeile, die längst verlassen ist.

### Offene Fragen

1. Ersetzt der Screenshot den Textauszug, oder kommen beide (Text im Float, Screenshot
   auf Taste)? **Empfehlung: beide.** Sie beantworten verschiedene Fragen — „was steht
   da" vs. „wie sieht die Seite aus".
2. Chrome-Suche: welche Binaries in welcher Reihenfolge, und wird sie konfigurierbar?
3. Reicht `--virtual-time-budget`, oder braucht es echtes Warten auf `networkidle`
   (dann CDP statt CLI, also deutlich mehr Code)?
4. Was passiert ohne images.nvim / ohne Kitty-Graphics? (Vermutlich: Screenshot-Schalter
   verweigert sich und sagt warum — so wie `inline_images` heute degradiert.)

---

## 4. Was ausdrücklich **nicht** gebaut werden soll

**Die HTML→PDF-Idee** (Seite über `soffice` in ein PDF wandeln und wie ein PDF anzeigen).
Am 2026-09-04 durchgesprochen und verworfen. Begründung, damit sie nicht wiederkommt:

- `soffice` ist zwar schon deklarierte Dependency, importiert HTML aber als
  Textverarbeitungs-Dokument: kein CSS, keine Webfonts, kein JS. Das Ergebnis wäre
  **schlechter lesbar als der Textauszug** — bei einem LibreOffice-Start pro Link.
- Ein Cache löst nur den zweiten Aufruf. Ein Hover hat aber genau einen ersten.

**Die eine Variante davon, die sich lohnt** — Links, die *schon jetzt* auf ein PDF zeigen
(`content-type: application/pdf`) — ist mit `dbc2b87` gebaut. Die Einschätzung „billig,
ehrlich, sofort nützlich" hat gehalten; die *Begründung* dafür in Abschnitt 6 war an zwei
Stellen falsch. Siehe dort.

---

## 5. Kurzfassung für den Einstieg

1. ~~`git status` klären~~ — erledigt; der Pfad in der ersten Fassung war falsch, das Repo
   liegt auf `$REPOS_DIR\hover.nvim`, und die dort beschriebene uncommittete Arbeit gab es in
   diesem Checkout nicht. Neu geschrieben, `c20191e` und `9070b5e`.
2. ~~**Zen-Mode bauen**~~ — gebaut, `c20191e`. `:Hover zen` / `F`,
   `docs/FEATURES/ZEN.md`, 19 Specs.
3. ~~**Screenshot-Preview bauen**~~ — gebaut, `4e2ebeb`. `:Hover links web shot` und
   `:Hover links web shot eager`, `docs/FEATURES/SHOT.md`, 20 Specs. Der Body-Cache aus
   dem Nachtrag zu Abschnitt 2 ist mit `6ebd232` erledigt.
4. ~~**PDF-Links bauen**~~ — gebaut, `dbc2b87`. `:Hover links web fetch pdf`,
   `docs/FEATURES/WEBPDF.md`, 12 Specs. Die beiden Fehleinschätzungen in
   Abschnitt 6 stehen dort korrigiert.
5. Nicht anfangen mit HTML→PDF (Abschnitt 4).

## 6. PDF-Links — gebaut (`dbc2b87`), und zwei Vorhersagen, die falsch waren

`:Hover links web fetch pdf`. Ein Link, dessen Server `application/pdf`
antwortet, wird nicht mehr als Größe angezeigt, sondern als seine erste Seite —
mit denselben Blättertasten, demselben scharfen Zoom, derselben Pipeline wie ein
lokales PDF. Ausführlich in `hover.nvim/docs/FEATURES/WEBPDF.md`, 12 Specs in
`TESTS/webpdf_spec.lua`, 380 grün.

**Der Zuschnitt hat gehalten. Zwei der vier Punkte darunter nicht** — und die
sind der eigentliche Ertrag dieses Abschnitts, weil beide plausibel klangen.

### Falsch 1: „die Bytes sind schon da"

Der Body-Cache (`6ebd232`) hält die letzte Antwort samt Body, also — so der
Schluss — bei `application/pdf` bereits die PDF-Bytes, ohne zweite Anfrage.

**Er hält sie, aber nicht unversehrt.** `lib.nvim.net.curl` ruft
`vim.system(..., { text = true })`, und diese Option **ersetzt `\r\n` durch `\n` in
der Ausgabe**. Für HTML unsichtbar. Für ein PDF tödlich: jedes
`0D 0A`-Bytepaar im Binärstrom wird stillschweigend umgeschrieben, und was
ankommt, ist eine Datei, die `pdftoppm` nicht öffnet. Der Fehler hätte
ausgesehen wie ein kaputter Renderer, nicht wie ein zerstörter Download.

Also **zweite Anfrage**, mit `curl -o` direkt in die Cache-Datei — die Bytes
kommen nie durch Lua. Das ist auch der Grund, warum das Feature einen Schalter
bekommen hat statt keinen: es kostet einen eigenen Round-Trip.

### Falsch 2: „es braucht keinen neuen Schalter"

Die Begründung war die des Seitentexts: `fetch` ist schon an, die Bytes sind
bezahlt. Der zweite Halbsatz stimmt nach Falsch 1 nicht mehr — und damit auch
der Schluss nicht. `pdf` ist ein eigener Schalter, `implies = "fetch"`.

Diese Implikation ist die **einzige im Repo, die ein Mechanismus statt einer
Politik ist**. Alle anderen wägen Kosten ab; diese stellt eine Abhängigkeit
fest: der **Content-Type des Servers** identifiziert den Link, und nur ein
Fetch erzeugt überhaupt einen. Nie die Endung im Pfad — ein `.pdf` im Pfad ist
das Wort des Autors, und ein `.pdf`, das auf eine HTML-Fehlerseite 404t, ist
häufig genug, um zu zählen.

### Richtig 1: die 2-MB-Deckelung war die Falle, als die sie notiert war

Und die zweite Anfrage ist genau das, was sie **beantwortbar** macht. Ein Fetch
deckelt bei 2 MB — richtig für eine Seite, viel zu klein für ein Dokument. Der
Content-Type ist aber erst bekannt, wenn die erste Antwort da ist, also kann
*eine* Anfrage nicht beide Zahlen tragen. Zwei können es.
`links.pdf.max_bytes` (25 MB) ist die zweite, und ein Dokument darüber wird
**abgelehnt statt abgeschnitten**, unter Nennung beider Zahlen: ein halbes PDF
ist kein kleineres PDF, es ist eine Datei, die nicht aufgeht.

### Richtig 2: `preview/shot.lua` war das Muster

Bytes auf Platte, synthetisches Target, ab da `preview.media`. Für ein PDF
`media.pdf` statt `canvas_for` — sonst identisch, inklusive Paging und
DPI-Zoom. Genau so gebaut.

**Ein Feld war trotzdem nötig**, und das war im Handover nicht vorhergesehen:
`scroll` und `zoom` leiteten „ist das geblättert" aus
`target.type == "pdf" or "office"` ab. Das war ein Stellvertreter für die
richtige Frage und hörte in dem Moment auf, ein genauer zu sein, als ein *Link*
mit einem PDF antworten konnte. `present` merkt sich jetzt `_open.paged` aus
dem Inhalt selbst — nur eine geblätterte Preview deklariert `scroll.page`.

### Was der Sabotage-Durchgang gefunden hat

Die Vollständigkeitsprüfung (`%PDF-` am Anfang, `%%EOF` am Ende) lief **nur
nach einem Download**. Die Datei, gegen die sie schützt, schreibt aber eine
*frühere* Session: curls Teilausgabe liegt bei einem Abbruch — Neovim
abgeschossen, Rechner im Standby, Netz weg — genau auf dem Cache-Pfad, und
nichts sonst sieht sie je wieder an. Ungeprüft wäre sie `cache_days` lang als
Datei ausgeliefert worden, die der Rasterizer nicht öffnet. Ein auf Platte
gefundener Kandidat wird jetzt an beiden Enden gelesen, bevor er übernommen
wird, und bei Misserfolg gelöscht.

Gefunden, weil die Hausregel „jede neue Spec sabotieren" beim Schreiben der
Sabotage die Frage aufwarf, wo die Prüfung eigentlich *nicht* läuft.

### Was offen bleibt

Nichts am Code. Die Zeile in `MANUAL-EVIDENCE.md` steht auf *never*: gegen
einen echten Server, der `application/pdf` antwortet, ist nichts davon gesehen
worden. Was dort zu prüfen ist, steht in der Zeile.
