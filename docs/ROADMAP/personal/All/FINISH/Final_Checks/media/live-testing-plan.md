# Live-Testing-Plan: `media.nvim` (2026-09-14)

> **Zweck:** ein abhakbarer Plan, um jedes Feature dieses Plugins live zu
> testen — gegen echte Dateien, im echten Terminal. Alle Angaben hier sind
> gegen den echten Code geprüft (nicht angenommen), Stand 2026-09-14
> (`media.nvim@e946b77`). Wo etwas nicht live verifiziert werden konnte (kein
> `whisper.cpp` auf der Entwicklungsmaschine), steht das explizit dabei —
> genau dafür ist dieses Dokument da.

---

## Table of content

  - [0. Voraussetzungen](#0-voraussetzungen)
  - [1. Test-Matrix](#1-test-matrix)
  - [2. Ein Testfile](#2-ein-testfile)
  - [3. Die Basics: probe, frame, sheet](#3-die-basics-probe-frame-sheet)
  - [4. Waveform / Spectrogram](#4-waveform--spectrogram)
  - [5. Standbild-Scrub (Paging-Keys)](#5-standbild-scrub-paging-keys)
  - [6. Playback — Fenster (mpv, Standard)](#6-playback--fenster-mpv-standard)
  - [7. Playback — inline (Blockgrafik)](#7-playback--inline-blockgrafik)
  - [8. Ton-Sync (mpv-IPC)](#8-ton-sync-mpv-ipc)
  - [9. Transkription — der ungeprüfte Teil](#9-transkription--der-ungeprüfte-teil)
  - [10. Bekannte, nicht-blockierende Eigenheiten](#10-bekannte-nicht-blockierende-eigenheiten)
  - [Checkliste zum Abhaken](#checkliste-zum-abhaken)

---

## 0. Voraussetzungen

| Was | Pflicht? | Wofür |
| --- | --- | --- |
| `ffmpeg` + `ffprobe` | Ja | alles außer `:Media play`/`window` |
| `lib.nvim` | Empfohlen | `:Media`-Tab-Completion, Scratch-Fenster, Keymap-Registry |
| `images.nvim` + ImageMagick | Für die *inline*-Playback-Route (Abschnitt 7) | Blockgrafik-Sampling |
| `mpv` | Für Fenster-Playback (Standard, Abschnitt 6) und Ton (Abschnitt 8) | echtes Fenster, Ton-Clock |
| `whisper-cli` (whisper.cpp) + ein GGML-Modell | Nur für Abschnitt 9 | Transkription |

```bash
:checkhealth media
:checkhealth hover
:checkhealth images
```

Alle drei einmal laufen lassen, bevor du unten irgendwas testest — sonst
testest du einen alten Stand oder jagst einen Fehler, der eigentlich "Tool
fehlt" heißt.

---

## 1. Test-Matrix

| Feature | Grundfunktion | Fehlerpfad | Live verifiziert (diese Sitzung)? |
| --- | --- | --- | --- |
| `:Media probe` | ☐ | — | ✅ (bestehender Code, ungeändert) |
| `:Media frame` | ☐ | ☐ (kaputte Datei) | ✅ |
| `:Media sheet` | ☐ | ☐ (Datei ohne Dauer) | ✅ |
| `:Media waveform` | ☐ | ☐ (Datei ohne Ton) | ✅ 2026-09-14 (echtes ffmpeg) |
| `:Media spectrogram` | ☐ | ☐ | ✅ 2026-09-14 (echtes ffmpeg) |
| Standbild-Scrub (`gO`/Paging) | ☐ | — | Unverändert, nicht neu getestet |
| Playback-Fenster (`<CR>`, mpv) | ☐ | ☐ (kein mpv) | Unverändert, nicht neu getestet |
| Playback inline (Blockgrafik) | ☐ | ☐ (kein ImageMagick) | Unverändert, nicht neu getestet |
| Ton-Sync | ☐ | ☐ (mpv fehlt) | Unverändert, nicht neu getestet |
| `:Media transcribe` | ☐ | ☐ (kein whisper-cli) | ⚠️ **nur die Pipeline** (Fake-Engine) — die echte `whisper.cpp`-JSON-Verarbeitung **nicht** |
| `:Media engines` | ☐ | — | ✅ 2026-09-14 |

---

## 2. Ein Testfile

Video mit Ton, ohne Fremdmaterial (aus `NOTES/HANDOVER.md`, Abschnitt 6):

```bash
ffmpeg -y -f lavfi -i "testsrc=size=640x360:rate=25:duration=12" \
       -f lavfi -i "sine=frequency=440:duration=12" \
       -c:v libx264 -pix_fmt yuv420p -c:a aac -shortest test.mp4
```

Für Waveform/Spectrogram reicht das mit — ein Sinuston zeigt beide Bilder
klar (eine flache Linie bzw. ein einzelnes Frequenzband). **Für eine
sinnvolle Transkription (Abschnitt 9) taugt das nicht** — ein Sinuston hat
keine Sprache. Nimm dafür eine echte Sprachaufnahme (eine kurze
Sprachmemo-Datei, ein Podcast-Ausschnitt, oder nimm dich selbst kurz auf).

---

## 3. Die Basics: probe, frame, sheet

Unverändert in dieser Sitzung — kurz gegentesten, damit die Baseline steht,
bevor du die neuen Features darüber prüfst.

1. `:Media probe test.mp4` — Scratch-Fenster mit Dauer, Auflösung, Codecs.
2. `:Media frame test.mp4` — ein Standbild bei 10 %, gezeigt (über
   `images.nvim` oder den System-Viewer).
3. `:Media sheet test.mp4` — ein 3×4-Raster über die ganze Laufzeit.
4. **Fehlerpfad**: `:Media frame nicht_da.mp4` — lesbare Fehlermeldung, kein
   Absturz.

---

## 4. Waveform / Spectrogram

**Neu, gebaut und real getestet in dieser Sitzung** (`media.nvim@c416315`) —
hier nochmal von Hand gegenprüfen, live im Editor statt headless.

1. `:Media waveform test.mp4` — ein Bild öffnet sich: eine flache, farbige
   Linie (Sinuston bei konstanter Amplitude). Standardfarbe `#9cdcfe`.
2. `:Media spectrogram test.mp4` — ein Bild öffnet sich: ein einzelnes
   horizontales Frequenzband nahe 440 Hz, über die ganze Laufzeit.
3. **Fehlerpfad**: eine Videodatei **ohne** Tonspur (z. B. `ffmpeg -f lavfi
   -i "testsrc=duration=3" -an notone.mp4`) → `:Media waveform notone.mp4`
   sollte "no audio stream in this file" melden, kein Absturz, kein leeres
   Bild.
4. `width=`/`height=` als kv-Argumente testen: `:Media waveform test.mp4
   width=600 height=150` — kleineres Bild.

---

## 5. Standbild-Scrub (Paging-Keys)

**Nicht Teil dieser Sitzung** — unverändert, aber gehört in die volle
Abdeckung.

1. Cursor auf `test.mp4`, `:Hover show`.
2. Die konfigurierten Paging-Keys (Standard: die von `hover.nvim`s
   `scroll_keys` — siehe `:Hover` bzw. `?` im Hover-Float) mehrfach drücken:
   das Bild wandert durch die Datei, `video.step` (Default `"10%"`) pro
   Druck.
3. Zurück über den Anfang hinaus sollte **nicht** wickeln — bei 0 % stehen
   bleiben.
4. **Bekannt offen** (siehe Abschnitt 10): kein Prefetch — ein Druck fühlt
   sich wie ein Sprung an, nicht wie ein weicher Übergang. Kein Bug, nur
   ungebaut.

---

## 6. Playback — Fenster (mpv, Standard)

**Nicht Teil dieser Sitzung** — unverändert.

1. Cursor auf `test.mp4`, `:Hover show`, `<CR>`.
2. **Standardmäßig** (`video.playback = "window"`) öffnet das ein echtes
   mpv-Fenster — Bild und Ton laufen dort, unabhängig vom Terminal.
3. `<CR>` noch einmal, oder die Hover irgendwie schließen (Cursor bewegen,
   `q`, `:qa`) — das Fenster muss sich wieder schließen.
4. **Fehlerpfad**: kein mpv installiert → `<CR>` fällt auf `media.play()`
   zurück (Systemstandard-Player), keine Fehlermeldung, kein totes `<CR>`.

---

## 7. Playback — inline (Blockgrafik)

**Nicht Teil dieser Sitzung** — unverändert.

1. `:lua vim.g.hover_disable = false; require("hover").setup({ video = {
   playback = "inline" } })` (oder die entsprechende Zeile in deiner eigenen
   `setup()`).
2. Wie in Abschnitt 6, aber `<CR>` startet jetzt die Blockgrafik-Wiedergabe
   direkt im Float.
3. Die Uhr muss bei **0:00** anfangen, die Leiste muss über 0:02 hinauslaufen
   und sich **nicht** zurücksetzen (das war der 2026-09-08-Bug, siehe
   `NOTES/HANDOVER.md` Abschnitt 0).
4. `,` muss über die 2-Sekunden-Fenstergrenze zurückkommen.
5. `:qa` — der Ton muss aufhören.
6. Zeichnet das Terminal die Sextanten nicht: `:checkhealth images` zeigt
   pro Geometrie eine Vergleichszeile; `display.ascii_fallback.cells =
   "quadrant"` ist die Rückfallebene.

**Ruckelt es, nicht raten — messen** (siehe `NOTES/HANDOVER.md` Abschnitt 6
für die beiden Diagnose-Skripte in `hover.nvim/scripts/`).

---

## 8. Ton-Sync (mpv-IPC)

**Nicht Teil dieser Sitzung** — unverändert.

1. Playback starten (Fenster oder inline, mit Ton).
2. Ton und Bild sollten synchron laufen, auch nach ein paar Sekunden — das
   Bild folgt mpvs eigener Uhr (`time-pos`), nicht einem Lua-Timer.
3. Und wenn nicht:
   ```powershell
   Get-CimInstance Win32_Process -Filter "Name like '%mpv%'" |
     Select-Object ProcessId,ParentProcessId,Name
   ```
   Zwei Zeilen mit Eltern-Kind-Beziehung heißen: der `mpv.COM`-Wrapper ist
   wieder im Spiel (`NOTES/HANDOVER.md` Abschnitt 2.1).

---

## 9. Transkription — der ungeprüfte Teil

**Neu gebaut in dieser Sitzung** (`media.nvim@e946b77`), aber **die
`whisper.cpp`-JSON-Verarbeitung selbst wurde nie gegen einen echten Lauf
geprüft** — auf der Entwicklungsmaschine ist kein `whisper.cpp` installiert.
Alles andere in der Pipeline (WAV-Extraktion, Cache, Sidecar-Schreiben,
Fehlerpfad ohne Engine) **ist** real getestet. Das hier ist also der
wichtigste Abschnitt in diesem Dokument.

### 9.1 Setup

```bash
# Bauen (kein Paketmanager-Install auf irgendeiner Plattform):
git clone https://github.com/ggml-org/whisper.cpp
cd whisper.cpp
cmake -B build
cmake --build build -j --config Release
```

Der fertige Binary-Name ist `whisper-cli` (in `build/bin/` oder ähnlich, je
nach Version — `whisper-cli --help` zum Gegenprüfen). Falls dein Build den
älteren Namen `main` erzeugt: `media.nvim` sucht explizit nach
`whisper-cli`, nicht nach `main` — mit `require("media").setup({ bin = {
["whisper-cli"] = "…" } })` einen Symlink/Kopie-Pfad oder den echten Pfad
eintragen, falls dein Build anders heißt.

Ein Modell laden (klein und schnell zum Testen: `base.en`, falls die
Aufnahme englisch ist, sonst `base` für Mehrsprachigkeit):

```bash
# innerhalb des whisper.cpp-Repos, falls vorhanden:
bash ./models/download-ggml-model.sh base.en
# oder von Hand von https://huggingface.co/ggerganov/whisper.cpp/tree/main
```

### 9.2 Konfiguration

```lua
require("media").setup({
  transcribe = {
    whisper_cpp = {
      model = "/absoluter/pfad/zu/ggml-base.en.bin",
    },
  },
})
```

`bin["whisper-cli"]` nur setzen, falls der Binary nicht auf PATH liegt.

### 9.3 Health-Check

```
:checkhealth media
```

→ Abschnitt `media.nvim: transcription` sollte jetzt `whisper-cli found: …`
und `whisper.cpp model: …` zeigen (beide grün/`h_ok`). Falls nicht: genau
hier ansetzen, bevor irgendwas anderes unten getestet wird.

### 9.4 Der eigentliche Test

1. Eine **echte Sprachaufnahme** (nicht den Sinuston-Testfile von oben —
   siehe Abschnitt 2) als `speech.m4a`/`.wav`/`.mp3` bereitlegen.
2. `:Media engines` → sollte `whisper_cpp     available` zeigen.
3. `:Media transcribe speech.m4a` (Default-Output: `buffer`) → ein
   Scratch-Fenster mit dem transkribierten Text sollte sich öffnen.
   **Worauf achten:**
   - Kommt überhaupt Text, oder bleibt das Fenster leer? Ein leeres Ergebnis
     bei vorhandener Sprache ist der wahrscheinlichste Fehlerort — entweder
     stimmt die angenommene JSON-Form
     (`lua/media/engines/whisper_cpp.lua`, `M.from_json`) nicht mit dem
     tatsächlichen `-oj`-Output deiner `whisper.cpp`-Version überein, oder
     `whisper-cli` schreibt die JSON-Datei an eine andere Stelle als
     `<wav-ohne-endung>.json` erwartet.
   - Stimmt der erkannte Text grob mit dem Gesagten überein? (Erkennungsfehler
     sind normal und kein Bug.)
4. `:Media transcribe speech.m4a out=sidecar` → `speech.m4a.transcript.md`
   sollte neben der Quelldatei liegen, mit Titel, Datum, Engine/Modell-Zeile
   und dem Text.
5. **Cache-Check**: `:Media transcribe speech.m4a` ein zweites Mal — sollte
   spürbar sofort antworten (Cache-Treffer), nicht wieder minutenlang
   laufen. Ein `stat`, kein zweiter `whisper-cli`-Lauf.
6. **`lang=`/`task=` testen**: `:Media transcribe speech.m4a lang=en` (oder
   die tatsächliche Sprache der Aufnahme) — sollte die Erkennung
   beschleunigen/verbessern gegenüber Auto-Detect.
7. **`task=translate`** (nur sinnvoll bei einer nicht-englischen Aufnahme):
   `:Media transcribe speech.m4a task=translate` — der Text sollte auf
   Englisch herauskommen, unabhängig von der Quellsprache.
8. **Fehlerpfad, Modell falsch**: `transcribe.whisper_cpp.model` kurz auf
   einen nicht existierenden Pfad setzen → `:Media transcribe speech.m4a`
   sollte "whisper.cpp model not found: …" melden, kein Absturz, kein
   Hänger.
9. **Fehlerpfad, kein whisper-cli**: `bin["whisper-cli"]` kurz auf einen
   nicht existierenden Pfad setzen → lesbare Fehlermeldung
   ("whisper-cli not found — …"), kein Hänger.
10. **Cancel** (falls die Aufnahme lang genug ist, um es zu erwischen): mitten
    im Lauf `:Media health` oder eine andere Aktion auslösen, die eine
    zweite `:Media transcribe`-Anfrage auf derselben Datei triggert — laut
    Code-Kommentar in `core/dispatcher.lua` wird das **nicht** dedupliziert
    (bekannte Phase-0-Einschränkung, kein Bug). Interessanter Test: die
    Hover/den Buffer schließen, während transkribiert wird — sollte den
    Prozess nicht zum Absturz bringen, auch wenn nichts ihn tatsächlich
    abbricht ohne expliziten `cancel()`-Aufruf durch den Aufrufer.

### 9.5 Was danach zu tun ist

Wenn Schritt 4.3 (leeres oder falsch geparstes Ergebnis) auftritt: die
tatsächliche `<wav>.json`-Datei von Hand ansehen (whisper-cli mit `-of` auf
einen bekannten Pfad zeigen, ohne den Rest der Pipeline), mit der in
`lua/media/engines/whisper_cpp.lua`s `from_json`-Kommentar angenommenen Form
vergleichen (`transcription[].offsets.{from,to}` in Millisekunden,
`transcription[].text`, `result.language`), und `TESTS/whisper_cpp_spec.lua`
mit der echten Form aktualisieren.

---

## 10. Bekannte, nicht-blockierende Eigenheiten

Diese Dinge sind **bekannt** und **kein neuer Bug** — beim Testen nicht
verwirren lassen:

- **Kein Prefetch beim Standbild-Scrub** (Abschnitt 5) — jeder Druck decodiert
  neu, fühlt sich wie ein Sprung an. Die Playback-Route (Abschnitt 6/7) hat
  das bereits; der Stepping-Pfad nie bekommen. `ROADMAP.md`, "Frame
  stepping".
- **Auflösung nicht an die tatsächliche Float-Größe gekoppelt, nur an
  `max_width`** — ungemessen, ob das in der Praxis auffällt.
- **`levels` (Farbquantisierung) nicht nach Material unterschieden** —
  Video und Standbild nutzen denselben Wert; ob ein Standbild mehr verträgt,
  ist ungemessen.
- **Kein Sekunden-Spulen** — `.`/`,` sind Frame-Step (mpv-Konvention), keine
  Tasten für Sprünge in Sekunden.
- **VLC ohne mpv**: der Alignment-/Zentrierungs-Pfad (Abschnitt 6,
  `video.experimental.system_player_*`) ist auf dieser Maschine nicht
  prüfbar (kein VLC installiert) — falls du VLC hast, das ist der Pfad zum
  Gegenprüfen.
- **Kein SRT/VTT-Export, keine Fallback-Chain für Transkription** (Abschnitt
  9) — Phase 1 der Roadmap, noch nicht gebaut.
- **Zwei gleichzeitige `:Media transcribe`-Anfragen auf derselben Datei
  werden nicht zusammengeführt** — bewusste Phase-0-Vereinfachung, siehe
  `core/dispatcher.lua`s Moduldoc.

---

## Checkliste zum Abhaken

- [ ] `:checkhealth media` / `:checkhealth hover` / `:checkhealth images`
      sauber (oder die Lücken sind bekannt und erwartet)
- [ ] `:Media probe`/`frame`/`sheet` — Grundfunktion + ein Fehlerpfad
- [ ] `:Media waveform`/`spectrogram` — Bild korrekt, Fehlerpfad ohne Ton
- [ ] Standbild-Scrub über mehrere Seiten, kein Wickeln am Anfang
- [ ] Playback-Fenster: öffnet, schließt sauber, Ton läuft
- [ ] Playback inline: Uhr bei 0:00, Leiste läuft über 0:02 hinaus, kein Reset
- [ ] Ton-Sync bleibt über mehrere Sekunden synchron
- [ ] `whisper.cpp` gebaut, Modell geladen, `:checkhealth media` grün
- [ ] `:Media transcribe` gegen eine echte Sprachaufnahme — Text kommt,
      stimmt grob
- [ ] `:Media transcribe out=sidecar` — `.transcript.md` korrekt geschrieben
- [ ] Cache-Treffer beim zweiten Aufruf spürbar sofort
- [ ] `lang=`/`task=translate` einmal getestet
- [ ] Beide Fehlerpfade (fehlendes Modell, fehlender Binary) — lesbare
      Meldung, kein Hänger
- [ ] Notiert, welche der "bekannten Eigenheiten" (Abschnitt 10) in der
      Praxis tatsächlich störend auffallen (Grundlage für die Priorisierung
      der nächsten Runde)
