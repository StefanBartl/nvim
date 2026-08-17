# Link-Hover-Preview — Analyse & Konzept

Cursor/Maus über einem Markdown-Link ⇒ Popup-Preview des Ziels, egal ob
Bild, Markdown-Datei, PDF, sonstige Datei oder Web-URL.

**Ergebnis vorab:** Die Idee ist gut und **überraschend billig** — vier
der fünf nötigen Bausteine existieren bereits in deinen Plugins. Der
eigentliche Entwurfsentscheid ist nicht *wie*, sondern **wo es hingehört**
(§3) — und da spricht die Faktenlage gegen `mdview.nvim`.

---

## 1. Was es dafür braucht

| # | Schritt | Zuständig |
|---|---|---|
| 1 | Link unter Cursor/Maus finden | Detection |
| 2 | Zieltyp bestimmen (Bild/MD/PDF/Datei/URL/Anker) | Klassifikation |
| 3 | Vorschau erzeugen | Previewer je Typ |
| 4 | Im Float darstellen | Präsentation |
| 5 | Auslösen + entprellen | Trigger |

## 2. Bestandsaufnahme: das meiste existiert schon

| Baustein | Vorhanden? | Wo |
|---|---|---|
| **Link-Erkennung** | ✅ **fertig** | `markdown.nvim` `core/link_scan.lua`: `from_line(line, lnum)` — behandelt `[text](target)`, bare URLs, `<…>`-Autolinks, Klammer-/Satzzeichen-Trimming, überlappungsfreie Byte-Ranges |
| **Ziel-Auflösung / Existenzprüfung** | ✅ **fertig** | `markdown.nvim` `core/link_diagnostics.lua`: `collect(bufnr)` / `check(bufnr)` prüft bereits, ob Ziele existieren |
| **URL unter Cursor** | ✅ **fertig** | `lib.lua.strings.links.url_under_cursor(line, col)` |
| **Bild-Preview** | ✅ **fertig** | `images.nvim`: `M.show(path)`, `M.hover()` und `images.resolve.under_cursor()` — es gibt also **bereits einen Hover**, nur bild-exklusiv |
| **PDF-Preview** | ✅ **fertig** | `pdfport.render_page(path, page, opts, cb)` → echter PNG-Pfad. Sein Docstring nennt als Zweck wörtlich: *"lets consumers like images.nvim show a PDF page as an image"* |
| **Web-Preview** | ✅ Bausteine | `lib.nvim.net.curl` (`fetch_raw`, neuer `download`-Tier) |
| **Float-Fenster** | ✅ | `lib.nvim.window` (`make_scratch`, `close_on_focus_lost`), `lib.nvim.ui.kit` |
| **Entprellung** | ✅ | `lib.nvim.debounce` |
| **Typ-Dispatcher** | ❌ **fehlt** | — das ist das eigentlich Neue |

**Fazit:** Zu bauen ist im Kern *ein Dispatcher* plus vier dünne
Previewer-Adapter. Alles andere ist Verdrahtung.

## 3. Der eigentliche Entwurfsentscheid: wo gehört es hin?

| Kandidat | Dafür | Dagegen |
|---|---|---|
| **`mdview.nvim`** | Name passt semantisch („markdown view"); der Wunsch kam hier auf | Seine gesamte Architektur ist **Browser/Server**: `adapter/browser/`, `ws_client`, `server_args`, `inbound_poll`, `preview_tab`. Ein In-Editor-Float ist eine andere Achse. Es besitzt **keine** Link-Erkennung |
| **`markdown.nvim`** ⭐ | Besitzt Links bereits vollständig (`link_scan`, `link_diagnostics`, `wrap_link`). Schritt 1+2 sind dort **schon fertig**. Der Dispatcher säße direkt an seinen Daten | „view" steckt nicht im Namen — kosmetisch |
| **`images.nvim`** | Hat mit `M.hover()` + `resolve.under_cursor()` schon einen Hover | Würde es zum Universal-Previewer aufblähen; Bilder sind sein Kern |
| **Eigenes Plugin** | Saubere Trennung | Ein Plugin mehr für ~300 Zeilen Dispatcher — steht in keinem Verhältnis |

**Empfehlung: `markdown.nvim`.** Dort liegen Link-Erkennung und
Ziel-Auflösung bereits vor; alles andere wird delegiert. `mdview.nvim`
bekommt dabei eine klar definierte Rolle: **Eskalationsziel** — der Hover
zeigt die Kurzvorschau, ein Tastendruck öffnet die volle
Browser-Preview in mdview. Das nutzt beide Plugins für genau das, wofür
sie gebaut sind, statt eines von beiden umzubauen.

> Falls es dir trotzdem lieber in `mdview.nvim` liegt: dann sollte der
> Dispatcher `markdown.nvim`s `link_scan` als harte Dependency nutzen und
> die Erkennung **nicht** nachbauen — sonst entsteht die zweite
> Link-Parser-Implementierung, und das ist genau das Muster, das schon bei
> Test-Harness (16×) und `await`/`run_async` (2×) teuer war.

## 4. Architektur

```
markdown.nvim/lua/markdown/
├── core/link_scan.lua        -- vorhanden: Link unter Cursor
├── core/link_diagnostics.lua -- vorhanden: existiert das Ziel?
└── hover/
    ├── init.lua              -- Trigger (CursorHold + Maus), Debounce, Cache
    ├── classify.lua          -- Ziel -> Typ
    ├── float.lua             -- Darstellung (lib.nvim.window)
    └── preview/
        ├── image.lua         -- -> images.nvim M.show
        ├── pdf.lua           -- -> pdfport.render_page -> images.nvim
        ├── markdown.lua      -- Kopfzeilen + erste Absätze, gerendert
        ├── file.lua          -- erste N Zeilen + Sprache/Größe
        ├── url.lua           -- -> lib.nvim.net.curl (Titel/Description)
        └── anchor.lua        -- #heading im selben Dokument
```

### Klassifikation

| Ziel | Erkennung | Previewer |
|---|---|---|
| Bild | Endung (`png/jpg/gif/webp/svg/…`) | `images.nvim` |
| PDF | `.pdf` | `pdfport.render_page(path, 1)` → PNG → `images.nvim` |
| Markdown | `.md`/`.markdown` | Erste Überschriften + Absätze im Float |
| Anker | beginnt mit `#` | Zielabschnitt im selben Puffer |
| Sonstige Datei | existiert lokal | Erste N Zeilen, Treesitter-Highlighting |
| Web-URL | `https?://` | `<title>`/`<meta description>` via curl |
| Kaputt | `link_diagnostics` sagt "fehlt" | Fehler-Float mit Grund |

Der letzte Fall ist unterschätzt: **ein Hover, der sofort zeigt „dieses
Ziel existiert nicht"**, ist im Alltag oft nützlicher als jede
Inhaltsvorschau — und `link_diagnostics` liefert die Information bereits.

## 5. Trigger & Verhalten

```lua
require("markdown").setup({
  hover = {
    enabled = true,
    trigger = { "CursorHold", "mouse" },  -- Maus braucht `set mousemoveevent`
    delay_ms = 250,                        -- lib.nvim.debounce
    max_lines = 20,
    url = { fetch = true, timeout_ms = 2000 },  -- Netz nur wenn erlaubt
    escalate_key = "<CR>",                 -- -> mdview / images.zen / open.nvim
  },
})
```

Wichtige Verhaltensregeln:

- **Entprellt** über `lib.nvim.debounce` — bei Mausbewegung Pflicht, sonst
  feuert es pro Pixel.
- **Netzugriff nur opt-in.** Ein Hover, der ungefragt HTTP-Requests
  auslöst, ist ein Privacy-Problem (und in einem Dokument mit 50 Links ein
  Request-Sturm). Default: nur lokale Ziele; URLs zeigen erst auf
  Anforderung Inhalt, vorher nur die geparste URL.
- **Cache je Ziel** (`lib.lua.memo.lru`), damit Zurückwandern nicht neu
  lädt.
- **Abbruch bei Cursorbewegung** — `pdfport.render_page` und curl sind
  asynchron; verlässt der Cursor den Link vor dem Ergebnis, wird verworfen
  (`lib.nvim.async` bzw. die vorhandenen Cancel-Pfade).
- **Kein Float im Insert-Mode**, kein Fokusklau (`close_on_focus_lost`).

## 6. Aufwandsschätzung

| Teil | Aufwand |
|---|---|
| Dispatcher + Klassifikation | klein — Endungs-Mapping über vorhandene Scan-Daten |
| Float-Darstellung | klein — `lib.nvim.window` |
| Bild-/PDF-Previewer | **sehr klein** — beides einzeilige Delegationen |
| Markdown-/Datei-Previewer | klein — lesen + kürzen (`lib.nvim.fs.read`, `strings.width.truncate`) |
| URL-Previewer | mittel — HTML-`<title>`/`<meta>` robust parsen |
| Trigger/Debounce/Cache/Cancel | mittel — die Zustandslogik ist der eigentliche Aufwand, nicht die Vorschauen |

Grob: ein solider Tag für Bild/PDF/Markdown/Datei/Anker, ein weiterer für
URL + Zustandsfeinschliff.

## 7. Reihenfolge

1. Dispatcher + Float + **Bild & PDF** (fast reine Delegation, sofort sichtbarer Nutzen)
2. **Kaputte Links** (nutzt `link_diagnostics`, hoher Alltagswert, minimaler Aufwand)
3. Markdown + sonstige Dateien
4. Anker im selben Dokument
5. URL-Preview (opt-in, mit Cache)
6. Eskalation nach `mdview` / `images.zen` / `open.nvim`

## 8. Offene Fragen

- **Maus-Trigger** braucht `mousemoveevent`; das ist eine globale
  Nutzereinstellung. Opt-in lassen und im README erklären, nicht still
  setzen.
- **Terminal-Bilder im Float** — `images.nvim` weiß, welche Backends
  (kitty/ueberzug/sixel) in einem Float verlässlich zeichnen. Vor Schritt 1
  dort verifizieren; im Zweifel Bild in eigenem Split statt Float.
- **Doppelter Hover** — `images.nvim.hover()` existiert bereits. Entweder
  ruft der neue Dispatcher es intern auf (empfohlen) oder es wird als
  eigenständiger Befehl deprecated. Nicht beides nebeneinander laufen
  lassen.
- **LSP-Hover-Konflikt:** In Markdown-Puffern mit aktivem LSP konkurriert
  `CursorHold` mit `vim.lsp.buf.hover`. Klärung nötig, wer gewinnt —
  vermutlich: Link-Hover nur, wenn tatsächlich ein Link unter dem Cursor
  liegt, sonst durchreichen.
