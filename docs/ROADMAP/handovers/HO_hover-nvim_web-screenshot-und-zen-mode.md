# Handover — hover.nvim: Website-Screenshot-Preview & Zen-Mode

**Repo:** `E:\repos\hover.nvim` (branch `main`, Remote `StefanBartl/hover.nvim`)
**Datum:** 2026-09-04, Stand fortgeschrieben am 2026-09-04 (2)
**Status:** **Zen ist gebaut**, ebenso der `auto_hover`-Bugfix und der Seitentext.
Offen ist nur noch der **Screenshot** (Abschnitt 3).

---

## 0. Ausgangslage — erledigt, mit einer Korrektur

**Der Pfad in der ersten Fassung war falsch.** Es gibt kein `C:\repos\hover.nvim`; das
Repo liegt auf `E:\repos\hover.nvim`, und dort war der Working Tree **sauber**. Die elf
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

1. ~~`git status` klären~~ — erledigt; der Pfad in der ersten Fassung war falsch, das Repo
   liegt auf `E:\repos\hover.nvim`, und die dort beschriebene uncommittete Arbeit gab es in
   diesem Checkout nicht. Neu geschrieben, `c20191e` und `9070b5e`.
2. ~~**Zen-Mode bauen**~~ — gebaut, `c20191e`. `:Hover zen` / `F`,
   `docs/FEATURES/ZEN.md`, 19 Specs.
3. **Screenshot-Preview bauen** (Abschnitt 3) — **das ist die verbleibende Arbeit.**
   Auto-Trigger ist gewünscht und muss abschaltbar sein (`links.shot.auto`); die
   Disclosure gehört in die Ansage. Zwei Dinge, die seit dem ersten Entwurf dazugekommen
   sind und den Zuschnitt ändern:
   - **Zen ist da**, also ist die Lesbarkeitsfrage aus Abschnitt 1 beantwortet. Ein
     Screenshot soll die Boxgröße lesen, die `opts` trägt — im Zen ist das der ganze
     Bildschirm.
   - **`links.shot.auto` bekommt `auto_type = "url"`** in `switches.lua`, sonst läuft der
     Schalter in genau dasselbe stille Gate wie `:Hover links web on` (Abschnitt 0a).
   - Der Body-Cache aus dem Nachtrag zu Abschnitt 2 wäre hier ohnehin fällig: ein
     Screenshot pro `F`-Druck ist 4–20 s.
4. Nicht anfangen mit HTML→PDF (Abschnitt 4).
