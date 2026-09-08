# Zwei offene Punkte aus dem Video-Hover-Umfeld

**Stand 2026-09-08.** Beide beim Bauen des Video-Hovers gefunden bzw.
gewünscht, beide gehören nicht dorthin und stehen deshalb hier. Der erste
ist ein Bug mit bekannter Ursache, der zweite ein Feature mit fertigem
Entwurf.

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

**Nebenbei zu prüfen:** der Hauptpfad geht über `lib.nvim`s
`cross.open_default`. Wenn auch der auf Windows nur den Explorer öffnet
statt der Standard-App (siehe Punkt 3 unten), liegt dort dieselbe Frage.

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

## 3. Die Standard-App wird nicht benutzt (Windows)

**Symptom.** `:Hover open` auf `[Rick Beato](./RickBeato_1080p.mp4)` öffnet
den **Datei-Explorer**, obwohl für `.mp4` der VLC als Standard-App
hinterlegt ist. Bei einem PDF dasselbe.

**Vermutete Ursache, noch nicht bewiesen:** der Pfad wird so weitergereicht,
wie er im Dokument steht — `./RickBeato_1080p.mp4`, relativ und mit
Vorwärts-Schrägstrichen. `explorer.exe` versteht das nicht als Datei und
öffnet stattdessen ein Ordnerfenster. Ein absoluter, auf Backslashes
normalisierter Pfad wäre der Test.

Betrifft `hover.open` bzw. das, was es aufruft (open.nvim,
`lib.nvim.cross.open_default`) — also möglicherweise dieselbe Stelle wie
Punkt 1.
