# Video im Hover abspielen — mit Transportsteuerung

**Stand 2026-09-08.** Schritt 1 von 3 ist gebaut und gepusht
(`images.nvim@cd2f9e4`), Schritt 2 und 3 sind geplant und gemessen, aber
nicht gebaut. Beteiligt: `media.nvim`, `images.nvim`, `hover.nvim`.

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

## 7. Was hier gerade blockiert

**`ffmpeg` ist auf dieser Maschine nicht installiert** (`ffprobe` ebenso
wenig; `magick` ist da) — geprüft über die `PATH`-Sicht von Neovim selbst.
Das heißt: `media.nvim` kann hier nichts rendern, auch der bestehende
Standbild-Hover nicht, und Schritt 2 lässt sich zwar bauen, aber nicht
verifizieren. Schritt 1 war ohne ffmpeg vollständig testbar (ImageMagick
genügt), Schritt 2 ist es nicht.

Vor Schritt 2 also: ffmpeg installieren (`winget install Gyan.FFmpeg` oder
`scoop install ffmpeg`), oder bewusst entscheiden, dass der Code ungetestet
geschrieben und später verifiziert wird.

## 8. Reihenfolge

1. ~~`images.blocks`~~ — erledigt.
2. `media.frames()` + Abbruch-Handle. **Braucht ffmpeg zum Verifizieren.**
3. `hover`: Transportzustand, Tasten, Leiste, Timer.
4. Erst danach die Feinheiten: rollendes Fenster, Prefetch, Auflösung an die
   Float-Größe koppeln, `levels` je nach Material.
