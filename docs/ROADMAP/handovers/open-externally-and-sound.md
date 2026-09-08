# Zwei offene Punkte aus dem Video-Hover-Umfeld (plus einer, erledigt)

**Stand 2026-09-08, zweite Fassung.** Beim Bauen des Video-Hovers gefunden
bzw. gewünscht, gehören nicht dorthin und stehen deshalb hier.

Punkt 3 ist inzwischen **erledigt** und steht unten samt der Ursache — die
war eine andere als vermutet, und das ist der lesenswerte Teil. Offen sind
Punkt 1 (Bug mit bekannter Ursache, gopath.nvim) und Punkt 2 (Feature mit
fertigem Entwurf, Ton im Video-Hover).

Kontext: [video-hover-playback.md](./video-hover-playback.md).

---

## 1. `jobstart(..., { detach = true })` in gopath.nvim

**Symptom.** `gF` auf einem Videopfad meldet
`[gopath] Opening externally: RickBeato_1080p.mp4` — und es passiert nichts.

**Fundstelle.** `gopath.nvim/lua/gopath/external/helpers/opener.lua`, im
minimalen Fallback-Opener:

```lua
local job_id = vim.fn.jobstart(cmd, { detach = true })
if job_id > 0 then
  LOG.info(string.format("Opening externally: %s", ...))
  return true
end
```

**Warum das falsch ist.** Auf Windows startet `jobstart` mit `detach = true`
ein **Konsolen**-Programm gar nicht erst: libuv setzt `DETACHED_PROCESS`,
das Kind bekommt keine Standard-Handles, und ein Interpreter beendet sich
vor seiner ersten Anweisung. `jobstart` liefert trotzdem eine gültige
Job-ID — der Erfolgstest `job_id > 0` ist also erfüllt, und die Erfolgs-
meldung wird ausgegeben, obwohl nichts läuft.

Das ist exakt der Fall, den `media.nvim/lua/media/core/play.lua` in seinem
Modulkopf beschreibt und vermeidet; dort steht die Begründung ausformuliert.
Die dort verwendete Form ist:

```lua
vim.system(argv, {})   -- nicht erwartet; funktioniert für Konsolen- und GUI-Programme
```

**Zu tun.** In `opener.lua` den Fallback auf `vim.system` umstellen und die
Erfolgsmeldung an etwas hängen, das Erfolg tatsächlich belegt (der Prozess
läuft noch / hat 0 zurückgegeben), nicht an eine Job-ID. Klein, eine Datei.

**Nebenbei, inzwischen beantwortet:** der Hauptpfad geht über `lib.nvim`s
`cross.open_default`. Der hatte tatsächlich einen eigenen Fehler (relative
Pfade an `explorer.exe`), behoben in `lib.nvim@bc18ceb` — siehe Punkt 3.
Das ist aber ein *anderer* Fehler als dieser hier; `opener.lua`s Fallback
bleibt unabhängig davon falsch.

## 2. Ton im Video-Hover — und warum es kein eigenes Binary braucht

**Gewünscht.** Stumm starten bleibt richtig; abspielbar *mit* Ton wäre das
Ziel. Aufgeworfen wurde, ob ein Rust/C/Go-Prozess oder FFI die gemeinsame
Zeitbasis liefern müsste.

**Antwort: nein — und das macht die Aufgabe kleiner.** Es gibt bereits einen
Prozess mit einer perfekten Uhr, nämlich den Audio-Player. Eine Soundkarte
spielt Samples in genau einem Tempo ab; das ist die verlässlichste Zeitquelle
im System, verlässlicher als jeder Timer in Neovim.

**Der Entwurf ist deshalb eine Umkehrung.** Nicht das Bild führt und der Ton
folgt, sondern der Ton führt und das Bild folgt:

```
mpv --no-video --input-ipc-server=<pipe> --start=<offset> <datei>
```

Der Zeichentimer fragt beim Aufwachen `time-pos` über den Socket ab und malt
den Frame, der zu dieser Position gehört, statt hochzuzählen. Dann darf das
Bild ruckeln, ohne je *auseinanderzulaufen* — genau das, was ein Videoplayer
tut.

`ffplay` kann das nicht: es meldet seine Position nicht. mpv ist hier das
richtige Werkzeug, und `media.play` kennt es ohnehin schon als
`player`-Option.

**FFI wäre der falsche Weg.** LuaJIT kann es, aber im Editor-Prozess zu
dekodieren blockiert die Ereignisschleife — dieselbe Falle, aus der
`media.nvim` mit `vim.system` heraus gebaut ist. Ein eigenes Binary lohnt
erst, wenn man Dekodieren *und* Zeichnen selbst macht; dann ist man aber bei
„ein Videoplayer, der ins Terminal malt", und das ist `mpv --vo=tct` oder
`chafa`, kein Plugin.

**Was dann noch zu lösen bleibt** — nicht mehr die Drift, sondern:

- **Start.** Wie lange, bis Ton und Bild beide stehen; und was die Leiste in
  der Zwischenzeit sagt.
- **Fehlt mpv**, wird stumm abgespielt wie heute — nie ein Fehler.
- **Pause/Resume** muss beide anhalten, und `.`/`,` (Frame-Step) muss den Ton
  anhalten, nicht springen lassen.
- **Wer besitzt den Prozess.** Ein mpv, das den Hover überlebt, ist genauso
  falsch wie ein Timer, der ihn überlebt — dieselbe `on_close`-Kette.

## 3. Die Standard-App wird nicht benutzt (Windows) — ERLEDIGT 2026-09-08

**Symptom.** `:Hover open` auf `[Rick Beato](./RickBeato_1080p.mp4)` öffnete
den **Datei-Explorer**, obwohl für `.mp4` der VLC als Standard-App
hinterlegt ist.

**Die vermutete Ursache war real, aber nicht die Ursache.** Vermutet worden
war der relative Pfad. Der war tatsächlich kaputt und ist behoben; er war
hier nur nicht schuld.

**Zwei Fehler, übereinander:**

1. **`lib.nvim.cross.open_default` reichte relative Pfade durch.**
   `expand_path("./clip.mp4")` liefert `./clip.mp4` zurück, und
   `explorer.exe` meldet für etwas, das es nicht zu einer Datei auflösen
   kann, keinen Fehler — es öffnet ein **Ordnerfenster**. Behoben in
   `lib.nvim@bc18ceb`: absolut über `:p`, und auf Backslashes normalisiert.
   URLs bleiben unangetastet, `:p` würde sie zerstören.

2. **Und das war gar nicht der Weg, den `:Hover open` nimmt.** hover.nvim
   rief `open.open(nil, "path=…")` auf. `nil` heißt bei open.nvim
   *kontextabhängig wählen*, und dessen Antwort auf einen Pfad ist per
   Voreinstellung der **Dateimanager** (`default_target` →
   `default_filemanager`). Das ist eine gute Antwort auf die Frage „was
   will jemand meist mit dem Ding unter dem Cursor" und die falsche auf
   „öffne, was dieses Float gerade zeigt". Betraf **jeden** Dateityp, nicht
   nur Video — beim PDF fiel es nur weniger auf.

   Behoben in `hover.nvim@cbe990b`: ein Pfad fragt jetzt ausdrücklich nach
   `"default"`, also nach dem, was ein Doppelklick tut. Eine URL behält die
   kontextabhängige Wahl, weil deren Antwort dort der Browser-Handler ist —
   und der kann auf einen *benannten* Browser zeigen, was die System-
   Standardwahl nicht kann. Ist `default` nicht registriert (die Handler-
   Liste gehört dem Nutzer), fällt es auf die alte Wahl zurück: open.nvim
   beantwortet einen unbekannten Handler mit einer Meldung und ohne Tat,
   was `pcall` als Erfolg meldet — das Float hätte sich über nichts
   geschlossen.

**Belegt, nicht vermutet.** Mit abgefangenem `run_detached`:

```
open.open(nil,       "path=./RickBeato_1080p.mp4")  →  [open.filemanager]
open.open("default", "path=./RickBeato_1080p.mp4")  →  explorer.exe C:\…\RickBeato_1080p.mp4
```

**Die Lehre, die im Code steht.** Ein `nil`, das „wähl du" heißt, beantwortet
die Frage des Aufrufers nur, solange beide dieselbe Frage stellen. hover.nvim
und open.nvim stellten zwei verschiedene, und keine der beiden war falsch.

---

## Was in derselben Runde noch fiel

Kein eigener Punkt, aber hier notiert, weil es aus demselben Faden kam:

- **`:Hover dashboard` schaltete laut.** Jede Zeile meldete sich beim
  Umschalten, mit angehängtem Rat zu einem Abschnitt, der zwei Zeilen tiefer
  auf demselben Schirm stand. Das Board schreibt jetzt still — das Glyph ist
  der Bericht — und zeichnet den einen Satz, den ein Glyph nicht tragen kann
  (Schalter an, `auto_hover`-Typ aus), in die Zeilenerklärung und in eine
  Fußzeile.
- **`:Hover all` / die `everything`-Zeile.** Alles an oder alles aus in einer
  Taste, oben auf dem Board; die Zustandsspalte zählt (`8/25`), weil zwei
  Glyphen „die meisten" nicht sagen können. `on` heißt auch Modus `auto`.
- **`switches.status()` gab nie ein `desc` zurück.** Dabei aufgefallen: die
  Drei-Sekunden-Erklärung auf dem Board hat seit ihrem Bau auf jeder
  Schalterzeile stillschweigend abgelehnt, weil `nil` genau die Form von
  „diese Zeile hat nichts zu erklären" ist. Behoben.
