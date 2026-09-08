# Video im Hover abspielen — mit Transportsteuerung

**Stand 2026-09-08. Alle drei Schritte gebaut, gepusht und gegen eine echte
Datei verifiziert** — `images.nvim@cd2f9e4`, `media.nvim@25222b4`,
`hover.nvim@200ddff`. ffmpeg 9.0.1 ist inzwischen installiert.

Anforderung, wie gestellt: ein Hover über einem Videopfad soll das Video
abspielen können — **nicht automatisch**. Es braucht Play/Pause und die
üblichen Transporttasten.

---

## 1. Der Ausgangspunkt

`hover.nvim` zeigt für ein Video heute ein **Standbild** aus der Datei
(`preview/video.lua`, `hover@263a0b7`): `media.frame` seekt mit ffmpeg,
`images.nvim` zeichnet das PNG, und die Paging-Tasten des Readers scrubben
durch die Offsets — `content.scroll = { page = n }`, Seite *n* ist die Stelle
`at + (n-1) * step`. Das ist bereits ein Scrub, nur eben ohne Zeitachse.

`media.nvim` sagt in seinem Modulkopf ausdrücklich, dass es **nicht** abspielt,
und `media.play` reicht die Datei an einen echten Player weiter. Das bleibt
richtig für „im Systemplayer öffnen". Was hier dazukommt, ist die zweite,
ehrliche Antwort: Blockgrafik im Puffer.

## 2. Warum Blockgrafik und nicht „das Bild schneller zeichnen"

Der Weg, der echte Bilder in den Terminal bringt, ist OSC 1337 — ein ganzer
Base64-Payload pro Write, ohne Frame- oder Platzierungsbegriff, und Neovim
malt über alles, was zwischen seinen eigenen Redraws gezeichnet wird. Das
Kitty-Protokoll hätte Animationsframes, rendert aber aus Neovim heraus unter
Windows/WezTerm überhaupt nicht (gemessen 2026-08-05, steht in
`media.nvim/docs/ROADMAP.md`).

Blockgrafik ist **Text**: ein `█` pro Zelle mit eigenem Highlight. Sie
kollidiert mit keinem Grafikprotokoll und überlebt jeden Redraw.

## 3. Was am 2026-09-08 gemessen wurde

Alles auf dieser Maschine, 24 Frames, 80x36 Zellen:

| | |
|---|---|
| ImageMagick, **ein** Aufruf für alle 24 | **186 ms** |
| ImageMagick, ein Aufruf **pro** Datei | **1593 ms** (8,5×) |
| Zeichnen eines Frames, Worst Case (jede Zelle andere Farbe) | **6,3 ms** |
| Zeichnen, flaches Material (Runs zusammengefasst) | **0,13 ms** |
| Highlight-Gruppen bis `E849` | **19 602**, je ~0,08 ms |

Daraus die drei Entwurfsentscheidungen:

1. **Frames werden im Voraus in einem Prozess dekodiert.** Der Schleifen-Weg
   ist keine langsamere Wiedergabe, er ist der Grund, dass es keine gäbe.
2. **Zeichnen ist billig.** 6,3 ms von 83 ms (12 fps) sind 7,5 % — die teure
   Hälfte war nie das Malen.
3. **Farben müssen quantisiert werden.** Ohne Deckel erzeugt jede Zelle eine
   Highlight-Gruppe; sieben verrauschte Frames verbrauchen die Session, und
   Gruppen lassen sich nicht freigeben. Das ist erledigt (Schritt 1).

## 4. Schritt 1 — erledigt

`images.blocks` (`images.nvim@cd2f9e4`): `sample`/`sample_async` (ein
`magick`-Prozess für beliebig viele Bilder), `canvas_lines`, `paint` (ändert
nur Highlights, nie den Puffertext; fasst gleichfarbige Nachbarn zusammen),
`levels`-Quantisierung mit Deckel `levels³`, Default 16 → 4096.

`images.ascii` läuft jetzt darüber und ist damit den latenten `E849` los, den
es seit seiner ersten Fassung hatte.

## 5. Schritt 2 — `media.frames()` in `media.nvim`

Eine Verb-Ergänzung in der Form, die dort schon steht (`frame`, `sheet`):

```lua
media.frames(path, {
  from = 0,          -- Sekunden oder "10%"
  count = 24,        -- wie viele Frames
  fps = 12,          -- Abstand zwischen ihnen
  width = 320,       -- Pixelbreite vor dem Zellen-Sampling
}, function(pngs, err) end)   -- pngs: string[] in Reihenfolge
```

Ein `ffmpeg`-Lauf, `-ss` als Input-Option (Keyframe-Seek, wie `frame` es
schon macht), `-vf fps=N`, `-frames:v count`, Ziel `…/%03d.png` im
bestehenden Cache-Verzeichnis, Key wie gehabt aus Pfad + mtime + Parametern.
Das ist `frame.lua` mit einer anderen Filterkette und einem Verzeichnis statt
einer Datei — die ROADMAP dort nennt genau das („extracting a WAV is the same
`vim.system` shape").

Zwei Punkte, die beim Bauen zu entscheiden sind:

- **Nachladen statt alles-auf-einmal.** 24 Frames sind 2 Sekunden bei 12 fps.
  Ein Film braucht ein rollendes Fenster: während Fenster *n* spielt, wird
  *n+1* dekodiert. Der Zustand („welches Fenster läuft") gehört dem
  Konsumenten, nicht diesem Plugin — dieselbe Trennung, die die ROADMAP für
  das Frame-Stepping schon getroffen hat.
- **Abbrechen.** `vim.system` gibt ein Handle mit `kill`; ein Hover, der
  verschwindet, während ffmpeg läuft, muss den Prozess beenden können.
  `media.frame` braucht das heute nicht, `frames` schon.

## 6. Schritt 3 — Transport im Hover

### Der Zustand

`hover.nvim` hält den Playback-Zustand, so wie es heute `_open.page` hält:
`{ status = "paused"|"playing", frame = n, window = { from, pngs, raw } }`.
**Startzustand ist `paused`** — ein Hover, der von selbst losläuft, sobald
der Cursor einen Pfad streift, ist genau das, was hier nicht gewollt ist.

### Die Tasten

Neu in `bindings/keymaps.lua`, als eigene Borrow-Bedingung neben
`content.scroll` und `content.canvas` — vorgeschlagen `content.transport`:

| Taste | Wirkung |
|---|---|
| `<Space>` | Play / Pause |
| `]` / `[` | ein Frame vor / zurück (pausiert) — deckt sich mit dem heutigen Scrub |
| `0` | zurück an den Anfang des Fensters |

Die Bedingung ist eng zu halten, nach dem Argument, das dort schon steht:
gebunden nur, solange ein *abspielbarer* Hover oben ist. `<Space>` ist in
Normal Mode `l` — für die Dauer eines Floats vertretbar, aber es gehört in
`hover.config` als konfigurierbare `transport_keys`, wie jede andere
geborgte Taste auch.

### Die Steuerleiste

Eine Zeile unter dem Bild, im selben Puffer:

```
▶  00:07 / 04:32  ▮▮▮▮▮▯▯▯▯▯▯▯▯▯   ␣ play/pause   ] [ frame
```

Sie ist Text, also kostet sie nichts und überlebt jeden Redraw. Der Zeitcode
kommt aus `media.ui.duration`, damit Hover und `:Media probe` dieselbe Sprache
sprechen.

### Der Timer

`vim.uv.new_timer()` mit `1000/fps`, der `blocks.paint(buf, ns, raw, frame, …)`
aufruft und den Frame hochzählt. Zu beachten:

- Der Timer muss an **den Fenstertod** gebunden werden (`WinClosed`), sonst
  malt er in einen Puffer, den niemand mehr sieht — und `hover.nvim` schließt
  seine Floats bei `CursorMoved`.
- Solange pausiert wird, läuft **kein** Timer; Pause ist `timer:stop()`, nicht
  ein Timer, der nichts tut.
- Am Ende des Fensters: entweder das nächste Fenster ist schon dekodiert
  (weiterspielen) oder es wird angehalten und dekodiert — sichtbar in der
  Leiste, nicht als Ruckler ohne Erklärung.

### Degradation

Jede Stufe fällt auf die vorige zurück, keine ist ein Fehler: kein ffmpeg →
Badge (heute schon); kein ImageMagick → Standbild statt Playback; Terminal
ohne OSC 1337 → Blockgrafik ist ohnehin der Weg; `inline_images = false` →
Badge.

## 7. Wie es sich bedient

Hover über einen Videopfad → Standbild wie bisher. `<Space>` → der Run wird
dekodiert und läuft. Nochmal `<Space>` → Pause. `]` / `[` → ein Frame vor
oder zurück, pausiert. `q`/`<Esc>`/Cursorbewegung → Float weg, Timer aus.

Gemessen am echten Clip (640x360, 80x36 Zellen): 325 ms von der Taste bis
zum ersten Frame, danach 4,6 ms pro Frame. Die Leiste unter dem Bild zeigt
`▶ 0:01 / 0:12` plus Fortschrittsbalken, in der Zeitachse der *Quelle*.

## 8. Der frühere Blocker — erledigt

ffmpeg fehlte und ist installiert (`winget install Gyan.FFmpeg`, Version
9.0.1). **Achtung, eine Stolperstelle:** winget legt die Aliase im
User-`PATH` an, den eine bereits laufende Shell nicht mehr sieht — und die
`WinGet\Links`-Aliase für ffmpeg fehlten hier auch nach dem Neustart.
Wenn `ffmpeg` nicht gefunden wird, liegt die Binärdatei unter
`%LOCALAPPDATA%\Microsoft\WinGet\Packages\Gyan.FFmpeg_*fmpeg-9.0.1-full_buildin`;
entweder diesen Ordner in den `PATH` oder in `media.setup{ bin = { ffmpeg
= "…" } }` eintragen. `:checkhealth media` sagt, welche der beiden Binaries
fehlt.

## 9. Was gebaut wurde

1. **`images.blocks`** (`images.nvim@cd2f9e4`) — Sampling in einem Prozess,
   Malen nur über Highlights, Farbdeckel gegen `E849`.
2. **`media.frames()`** (`media.nvim@25222b4`) — ein ffmpeg-Lauf pro Run,
   abbrechbar, gecacht. 24 Stills in 168 ms, 3 ms beim Cache-Treffer,
   Teilergebnis am Dateiende, `cancel()` verhindert den Callback.
3. **`hover.preview.playback` + `transport_keys`** (`hover.nvim@200ddff`) —
   Zustand, Timer, Steuerleiste, Tasten. Startet **pausiert**.

## 10. Runde 2 — Rückmeldung aus dem echten Betrieb (2026-09-08)

Zwei echte Fehler und eine Qualitätsschwäche, alle drei behoben.

**Die Transporttasten waren der Leader und zwei Präfixe.** `<Space>` ist
`mapleader`; sie zu borgen verdrängt nicht eine Motion, sondern *jedes*
Leader-Mapping — und gegen which-key wird der Trigger auf derselben Taste
erneut betreten, worauf das Plugin „Recursion detected" meldet und der
Leader kaputt bleibt. `]` und `[` sind Präfixe, genau wie das `z`, das
`zen_keys` aus demselben Grund ablehnt: `]d`, `[q` und jede andere
Klammer-Motion existieren nicht mehr, solange ein Float oben ist, und ein
kaputtes Präfix meldet sich nicht. Beides stand als Regel schon in
`config/DEFAULTS.lua`, zwei Einträge über den neuen Tasten.

Jetzt: **`<CR>`** (Play/Pause), **`.`** und **`,`** (Frame vor/zurück —
mpvs eigene Tasten). `hover.nvim@8ccdd23`.

**Verpixelt, und vertikal gestaucht.** Beides kam daher, dass eine Zelle
*ein* Pixel trug. `▀` trägt im oberen Halbblock die Vordergrund- und im
unteren die Hintergrundfarbe: eine Textzeile zeigt **zwei** Pixelzeilen.
Gleiche Zellenzahl, doppelte vertikale Auflösung — und nebenbei das richtige
Seitenverhältnis, denn zwei gestapelte Pixel in einer Zelle sind quadratisch,
eines ist es nicht. `images.scale.fit_cells` korrigiert für die Zellform und
halbierte damit jedes Video in der Höhe; `blocks.fit_cells` ist der passende
Fit. `images.nvim@beb4051`.

Gemessen, bevor es gebaut wurde: 24 Frames Vollrauschen bei 60x24 Zellen
kosten **811 Highlight-Gruppen und 5,4 ms pro Frame**. Die Alternative — ein
fester Pool von Gruppen, pro Frame per `nvim_set_hl` neu definiert — kostet
**134 ms pro Frame** und ist verworfen.

## 11. Offen — die Feinheiten

- **Rollendes Fenster.** Ein Run ist zwei Sekunden. Danach hält es an; für
  längeres Abspielen muss Run *n+1* dekodiert werden, während *n* läuft.
  Das ist der nächste sinnvolle Schritt und der einzige, der noch fehlt,
  damit „abspielen" wirklich abspielen heißt.
- **Auflösung an die Float-Größe koppeln**, statt an `max_width` minus
  Rand — heute wird der Run mit einer festen Pixelbreite dekodiert und erst
  beim Sampeln an die Zellen angepasst.
- **`levels` je nach Material.** 16 Stufen sind für Video reichlich; ein
  Standbild könnte mehr vertragen, solange der Deckel gilt.
- **Ton — als Aufgabe notiert, ausdrücklich gewünscht.** Stumm starten bleibt
  richtig; abspielbar *mit* Ton wäre das Ziel.

  Der Weg wäre `ffplay -nodisp -autoexit -ss <from> <datei>` als zweiter
  Prozess, gestartet und gestoppt vom selben Transport wie das Bild.
  `media.core.play` hat die Prozess-Mechanik dafür bereits (kein `detach`,
  `vim.system` ohne Warten — die Windows-Fallstricke stehen dort auskommentiert),
  und `media.frames`' `cancel()` zeigt die Abbruchform.

  **Das offene Problem ist die Uhr.** Das Bild läuft auf einem Lua-Timer, der
  Ton in einem fremden Prozess; ohne gemeinsame Zeitbasis driften die zwei,
  und die Drift wächst mit jedem Frame, den der Timer wegen einer Redraw-Pause
  zu spät zeichnet. Zwei Auswege, beide zu prüfen: (a) die Bildrate an die
  vergangene *Wanduhr*-Zeit koppeln statt an die Tickzahl — Frames überspringen
  statt hinterherzuhinken; (b) den Ton bei jedem Pause/Resume neu bei
  `-ss <aktueller Offset>` starten, damit die Drift höchstens so lange lebt wie
  ein Abspielabschnitt. Vermutlich braucht es beides.

  Zweitens: `ffplay` gehört nicht zu jedem ffmpeg-Paket (bei Gyan ist es dabei,
  bei einigen minimalen Builds nicht) — also eine eigene Verfügbarkeitsprüfung
  und stummes Abspielen als Rückfall, nie ein Fehler.
- **Datei in der System-App öffnen — erledigt, war schon da.** `open_keys`
  (`gf`) im Hover öffnet das Ziel seit jeher über open.nvim bzw. `vim.ui.open`.
  Seit `hover.nvim@e4e8bf4` geht ein Medium zuerst durch `media.play`, damit
  der in media.nvim konfigurierte `player` (z. B. mpv mit eigenen Flags)
  gewinnt — die generischen Opener können davon nichts wissen.
- **Broken-Link-Benachrichtigung.** Wunsch aus der Rückmeldung: wenn ein Link
  ins Leere zeigt, standardmäßig eine Notify statt nur des Markers. Der
  Schalter `paths missing` ist heute schon an, aber er *markiert* nur.
  Eigener, kleiner Punkt — gehört zu `hover.nvim`s Link-Auflösung, nicht zum
  Video.
- **Float-Größe beim Start.** Die Playback-Ansicht nutzt die konfigurierte
  Hover-Box; ein größeres Fenster wäre für Video sinnvoll. `+`/`-` skalieren
  bereits, ein eigener Default für die Playback-Ansicht wäre der nächste
  Schritt.
