# Handover — hover.nvim: Website-Screenshot-Preview & Zen-Mode

**Repo:** `C:\repos\hover.nvim` (branch `main`, Remote `StefanBartl/hover.nvim`)
**Datum:** 2026-09-04
**Status:** nichts davon gebaut. Das hier ist der Entwurf plus die Messwerte, auf denen er steht.
**Vorher lesen:** der Abschnitt „Ausgangslage" — im Repo liegen **uncommittete Änderungen**.

---

## 0. Ausgangslage — was im Working Tree liegt

In der Session vom 2026-09-04 sind zwei Dinge passiert, **beide uncommittet**. Wer hier
weitermacht, muss das zuerst klären (committen oder bewusst verwerfen), sonst baut die
neue Arbeit auf einem Baum, den niemand eingecheckt hat.

```bash
cd /c/repos/hover.nvim && git status --short
```

Elf geänderte Dateien plus `TESTS/url_spec.lua` (neu). Inhalt:

**(a) Der `auto_hover`-Bug.** `:Hover links web on` meldete „web links hover", und nichts
hoverte — weil `auto_hover.url = false` ist (`lua/hover/config/DEFAULTS.lua`),
eine zweite Achse, die mit `e8cde0e` (2026-09-03) dazukam. Behoben an vier Stellen:
`:Hover why` kennt das Type-Gate jetzt, `switches.set` sagt es beim Einschalten dazu
(neues Feld `auto_type` auf `web`/`positions`/`office`/`missing`), der `notify_status`-
Fallback trägt den `auto`-Abschnitt, und vier Docs, die `:Hover links web on` als
Ein-Befehl-Workflow versprachen, sind korrigiert.

**(b) Seitentext im Fetch-Preview.** `M.page_text` in
`lua/hover/preview/url.lua` — HTML→Text
per Pattern, bevorzugt `<main>`/`<article>`, wirft `script`/`style`/`nav`/`header`/
`footer`/`aside`/`form`/`button` raus, Block-Enden werden Zeilenumbrüche, Listenpunkte
kriegen `•`, Entities werden dekodiert, bricht selbst auf `max_width` um. Nur bei
`text/html`. **Kein neuer Request** — der Body war beim Fetch schon da, deshalb ist es
kein eigener Schalter.

**Testlage:** 330 Specs grün, `stylua --check lua/ plugin/ TESTS/ scripts/` sauber.

Testlauf (die beiden env-Variablen werden hier nicht automatisch gefunden):

```bash
LIB_NVIM_DIR=/c/repos/lib.nvim PLENARY_DIR=/c/Users/StefanBartl/AppData/Local/nvim-data/lazy/plenary.nvim HOVER_ALLOW_PENDING=1 bash scripts/test.sh
```

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

## 2. Feature B (zuerst bauen): Zen-Mode / Vollbild für den Float

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

**Die eine Variante davon, die sich lohnt** und noch offen ist: Links, die *schon jetzt*
auf ein PDF zeigen (`content-type: application/pdf`). Da fällt jede Konversion weg — die
Bytes gehen direkt in die vorhandene pdfport/pdftoppm-Pipeline. Heute zeigt so ein Link
nur `HTTP 200 OK / application/pdf · 2.3 MB`. Billig, ehrlich, sofort nützlich. Eigener
kleiner Task, unabhängig von allem oben.

---

## 5. Kurzfassung für den Einstieg

1. `git status` in `C:\repos\hover.nvim` klären — 11 geänderte Dateien + `TESTS/url_spec.lua` liegen uncommittet.
2. **Zen-Mode bauen** (Abschnitt 2). Klein, nützt allen Preview-Typen, und ist die
   Voraussetzung dafür, dass ein Screenshot überhaupt lesbar ist.
3. **Screenshot-Preview bauen** (Abschnitt 3). Auto-Trigger ist gewünscht und muss
   abschaltbar sein (`links.shot.auto`); die Disclosure gehört in die Ansage.
4. Nicht anfangen mit HTML→PDF (Abschnitt 4).
