# Video-Capture: Browser-Extension mit MSE-Hook + Desktop-App

Stand: 2026-10-30 · Status: Idee / Konzept, noch kein Code

## Inhalt

- [Zielbild](#zielbild)
- [Abgrenzung: was das Tool nicht macht](#abgrenzung-was-das-tool-nicht-macht)
- [Grundlagen: wie Video heute im Browser ankommt](#grundlagen-wie-video-heute-im-browser-ankommt)
- [Architektur-Überblick](#architektur-überblick)
- [Komponente 1: Browser-Extension](#komponente-1-browser-extension)
- [Komponente 2: Transport Extension → Desktop](#komponente-2-transport-extension--desktop)
- [Komponente 3: Desktop-App](#komponente-3-desktop-app)
- [Die Aufnahme-Modi im Detail](#die-aufnahme-modi-im-detail)
- [Muxing: aus Segmenten wieder eine Datei machen](#muxing-aus-segmenten-wieder-eine-datei-machen)
- [Erkennung: welche Videos laufen gerade?](#erkennung-welche-videos-laufen-gerade)
- [Seiten-Spezifika](#seiten-spezifika)
- [Tech-Stack-Empfehlung](#tech-stack-empfehlung)
- [Risiken und bekannte Stolpersteine](#risiken-und-bekannte-stolpersteine)
- [Umsetzungsplan in Phasen](#umsetzungsplan-in-phasen)
- [Rechtliches in Kürze](#rechtliches-in-kürze)
- [Offene Fragen / Spikes](#offene-fragen--spikes)

---

## Zielbild

Der Wunsch-Ablauf aus Nutzersicht:

1. Browser ist offen, in ein paar Tabs laufen Videos (Mediathek, YouTube, Twitch, eine
   News-Seite, ein Vortrag).
2. Ich starte meine Desktop-App. Sie zeigt sofort eine Liste aller Videos, die gerade in
   irgendeinem Tab geladen sind oder gelaufen sind: Tab-Titel, Seite, Dauer, Auflösung,
   Format, ob DRM im Spiel ist.
3. Pro Video wähle ich einen Modus:
   - **Download**: das komplette Video in bester Qualität als Datei, ohne es anschauen zu
     müssen.
   - **Mitschneiden, was ich sehe**: wie eine Kamera, die auf den Tab gerichtet ist. Nimmt
     Bild und Ton auf, so wie sie gerade ablaufen (inkl. Pausen, Spulen, Overlays).
   - **Im Hintergrund mitschneiden**: das Video läuft in einem separaten, stummen Tab von
     vorne bis hinten durch, und jedes Segment, das der Player lädt, wird bit-genau
     abgegriffen. Ich kann derweil anderes tun.
   - **Live-Puffer** (für Streams): die letzten N Minuten werden rollierend vorgehalten,
     ein Knopf „letzte 10 Minuten speichern“.
4. Fertige Dateien landen in einem Ordner meiner Wahl, als MP4/MKV/WebM, abspielbar in
   VLC/mpv, mit sinnvollem Dateinamen (Seite, Titel, Datum).

Die Kernidee: **Transportverschlüsselung (TLS) ist im Browser bereits aufgelöst.** Der Player
übergibt das Video als Klartext-Segmente an die Media Source Extensions (MSE). Genau dort
hängen wir uns ein. Alles, was keinen echten Kopierschutz (DRM/EME) hat, ist damit erreichbar.

---

## Abgrenzung: was das Tool nicht macht

- **Kein DRM-Umgehen.** Sobald eine Seite `navigator.requestMediaKeySystemAccess` ruft
  (Widevine, PlayReady, FairPlay), markiert das Tool das Video als „DRM-geschützt“ und bietet
  keinen Modus an außer der reinen Anzeige. Warum das technisch sowieso kaum geht und
  rechtlich verboten ist, steht ausführlich in
  [02-drm-cdm-grundlagen.md](02-drm-cdm-grundlagen.md).
- **Kein Umgehen von Paywalls, Logins oder Geoblocking.** Das Tool sieht nur, was der
  Browser mit meiner Session ohnehin sieht.
- **Keine Weiterverbreitung.** Es ist ein Werkzeug für die persönliche Kopie
  (Zeitversetztes Ansehen, Archivieren von Vorträgen, Offline-Verfügbarkeit).

---

## Grundlagen: wie Video heute im Browser ankommt

Damit klar ist, an welchen Stellen man eingreifen kann, hier die Varianten, die man in freier
Wildbahn antrifft:

| Variante | Wie es technisch läuft | Wo man abgreifen kann |
|---|---|---|
| **Progressives MP4/WebM** | `<video src="https://…/film.mp4">`. Browser lädt mit Range-Requests. | URL direkt herunterladen (mit Cookies/Headers). Kein MSE-Hook nötig. |
| **HLS** (`.m3u8`) | Playlist mit Liste von `.ts`- oder `fMP4`-Segmenten, mehrere Qualitätsstufen. In Chrome/Firefox per JS-Player (hls.js) über MSE; in Safari nativ. | MSE-Hook (Chrome/Firefox) oder Manifest + Segmente selbst laden. |
| **DASH** (`.mpd`) | XML-Manifest, fMP4-Segmente, oft getrennte Audio-/Video-Spuren. Immer per JS-Player (dash.js, Shaka) über MSE. | MSE-Hook oder Manifest-Replay. |
| **Proprietäre Streaming-Protokolle** | YouTube (SABR/UMP: binäres Protokoll, Server bestimmt Bitrate), Twitch (HLS mit Erweiterungen). Am Ende landen trotzdem fMP4/WebM-Segmente in MSE. | MSE-Hook. Manifest-Replay ist hier mühsam bis unmöglich. |
| **WebRTC** (Jitsi, Discord, manche Live-Streams mit niedriger Latenz) | Kein MSE. Medien kommen als `MediaStreamTrack` an und werden direkt gerendert. | `RTCPeerConnection`-Hook + `MediaRecorder` (Re-Encode) oder Tab-Capture. |
| **Blob-URLs** | `<video src="blob:…">` ist fast immer das Anzeichen für MSE: der Player hat `URL.createObjectURL(mediaSource)` gemacht. | Der Hook auf `createObjectURL` verknüpft `MediaSource` ↔ `<video>`. |
| **EME/DRM** | Zusätzlich zu HLS/DASH: Segmente sind mit CENC verschlüsselt; Entschlüsselung im CDM. | **Nicht** (siehe Abgrenzung). Der MSE-Hook sieht nur Chiffrat. |
| **HLS mit AES-128** (`#EXT-X-KEY:METHOD=AES-128`) | Segmente AES-verschlüsselt, Schlüssel liegt als URL in der Playlist; der JS-Player entschlüsselt selbst, bevor er an MSE übergibt. | Der MSE-Hook sieht Klartext. Rechtlich eine Grauzone (siehe unten); Manifest-Replay soll hier nicht aktiv Schlüssel holen. |

**Das Entscheidende an MSE:** Der Player ruft für jedes Segment
`sourceBuffer.appendBuffer(arrayBuffer)`. Der Inhalt dieses `ArrayBuffer` ist genau das, was
auch in einer fertigen Datei stehen würde: ein Stück fragmentiertes MP4 oder ein Stück WebM.
Es gibt keine weitere Verschlüsselung, keine Umwandlung. Wenn wir alle Puffer in der
richtigen Reihenfolge aneinanderhängen, haben wir die Datei.

---

## Architektur-Überblick

```
┌──────────────────────────── Browser ──────────────────────────────┐
│                                                                   │
│  Tab 1 (ard.de)          Tab 2 (youtube.com)       Tab n …        │
│  ┌─────────────────┐     ┌─────────────────┐                      │
│  │ Seite + Player  │     │ Seite + Player  │                      │
│  │   │ appendBuffer│     │   │ appendBuffer│                      │
│  │   ▼             │     │   ▼             │                      │
│  │ [Main-World-Hook]     │ [Main-World-Hook]                      │
│  │   │ postMessage │     │   │             │                      │
│  │   ▼             │     │   ▼             │                      │
│  │ [Content Script]│     │ [Content Script]│                      │
│  └────┬────────────┘     └────┬────────────┘                      │
│       │ Binärdaten (WebSocket)│                                    │
│       │ Metadaten (runtime.Port)                                   │
│       ▼                       ▼                                    │
│  ┌────────────────────────────────────┐                            │
│  │ Service Worker (Tab-Registry,      │                            │
│  │ webRequest-Beobachtung, tabCapture)│                            │
│  └────────────────┬───────────────────┘                            │
└───────────────────┼────────────────────────────────────────────────┘
                    │ Native Messaging (Steuerung) + lokaler WebSocket (Daten)
                    ▼
┌──────────────────────────── Desktop-App ──────────────────────────┐
│  Video-Liste  │  Modus-Wahl  │  Segment-Store  │  Muxer (ffmpeg)  │
│  Live-Puffer  │  Downloader (yt-dlp / eigener Manifest-Replay)    │
│  Einstellungen│  Ausgabeordner, Benennung, Benachrichtigungen     │
└───────────────────────────────────────────────────────────────────┘
```

Drei Komponenten, drei Verantwortungen:

1. **Extension (im Browser)**: sieht Videos, greift Segmente ab, startet Tab-Captures.
   Hält selbst möglichst keine Daten (Speicher!), sondern reicht alles sofort weiter.
2. **Transport**: Steuerkanal (klein, JSON) und Datenkanal (groß, binär) getrennt.
3. **Desktop-App**: UI, Dateien, Muxing, Downloads. Alles, was Festplatte, ffmpeg oder
   lange Laufzeit braucht, gehört hierher.

Warum nicht alles in der Extension? Weil Extensions keinen freien Dateisystem-Zugriff haben,
der MV3-Service-Worker nach 30 s Leerlauf abgeschossen wird, kein ffmpeg zur Verfügung steht
und große Puffer im Browser-Speicher den Tab in die Knie zwingen.

Warum nicht alles in der Desktop-App (z. B. per Chrome DevTools Protocol)? Ginge im Prinzip
(`chrome --remote-debugging-port`, dann `Network.getResponseBody`), ist aber fragil: der
Browser muss speziell gestartet werden, Response-Bodies größer als ein Limit werden
verworfen, und man sieht Netzwerk-Antworten, nicht das, was der Player wirklich an MSE gibt
(bei YouTube SABR ein Unterschied). Die Extension sitzt an der richtigen Stelle.

---

## Komponente 1: Browser-Extension

Manifest V3, Ziel-Browser zuerst Chromium (Chrome, Edge, Brave), dann Firefox (unterstützt
`world: "MAIN"` seit Version 128).

### 1a. Main-World-Script (der eigentliche Hook)

Content Scripts laufen normalerweise in einer „Isolated World“: gleiches DOM, aber eigene
JS-Globals. Dort kann man `SourceBuffer.prototype` zwar überschreiben, aber der Player der
Seite sieht die Änderung nicht. Der Hook muss deshalb in der **Main World** der Seite
laufen. In MV3 geht das deklarativ (`"world": "MAIN"` in `content_scripts`) oder per
`chrome.scripting.registerContentScripts`. Wichtig: `run_at: "document_start"`, bevor der
Player initialisiert.

Was gehookt wird (alles per Monkey-Patching der Prototypen):

| Funktion | Zweck |
|---|---|
| `MediaSource.prototype.addSourceBuffer(mimeType)` | Erfährt, welche Spuren es gibt (`video/mp4; codecs="avc1.64001f"`, `audio/mp4; codecs="mp4a.40.2"`, `video/webm; codecs="vp9"`). Vergibt pro SourceBuffer eine ID. |
| `SourceBuffer.prototype.appendBuffer(data)` | **Das Herzstück.** Kopiert `data` (ArrayBuffer oder TypedArray) und reicht die Kopie weiter. Dann Original aufrufen. |
| `SourceBuffer.prototype.appendBufferAsync` | Firefox-Variante, gleiches Spiel. |
| `SourceBuffer.prototype.changeType(mimeType)` | Qualitäts-/Codec-Wechsel. Wichtig fürs Muxing (neues Init-Segment folgt). |
| `SourceBuffer.prototype.remove(start, end)` | Nur protokollieren; wir löschen nichts. |
| `SourceBuffer.timestampOffset` (Setter) | Für korrekte Zeitachse beim Zusammensetzen. |
| `MediaSource.prototype.endOfStream()` | Signal: Video komplett durchgelaufen → Muxing kann abschließen. |
| `URL.createObjectURL(obj)` | Wenn `obj instanceof MediaSource`: merkt sich URL ↔ MediaSource. Später beim `<video>` mit dieser `src` ist die Zuordnung klar. |
| `HTMLMediaElement.prototype.src` (Setter) / `srcObject` | Zuordnung Video-Element ↔ Quelle; bei `http(s)`-URL: progressiver Download möglich. |
| `navigator.requestMediaKeySystemAccess`, `HTMLMediaElement.prototype.setMediaKeys` | **DRM-Detektor.** Wird nur beobachtet, nicht verändert. Markiert das Video als geschützt. |
| `RTCPeerConnection.prototype.addTransceiver` / `ontrack` | Optional: WebRTC-Erkennung. |

Pro Tab entsteht so ein Modell: `MediaSource` → `SourceBuffer[]` → Folge von Segmenten mit
Zeitstempel, Größe, MIME, und ob es ein Init-Segment war (erkennbar an `ftyp`/`moov`-Box bzw.
WebM-`EBML`-Header am Anfang).

Datenübergabe zum Content Script: `window.postMessage` mit **Transferable**. Vorsicht: der
Player braucht den Puffer selbst noch, also erst `data.slice()` (eine Kopie), dann die Kopie
transferieren (dadurch keine zweite Kopie).

### 1b. Content Script (Isolated World)

- Empfängt Segmente + Metadaten vom Main-World-Script.
- Hält eine Verbindung zum Datenkanal (siehe Transport) und schiebt Binärdaten sofort weiter.
- Beobachtet das DOM: `MutationObserver` auf `<video>`/`<audio>`, liest `videoWidth`,
  `videoHeight`, `duration`, `currentTime`, `paused`, Poster, und sucht den Titel (Seite,
  `og:title`, JSON-LD `VideoObject`).
- Läuft mit `all_frames: true`, weil viele Player in Cross-Origin-iframes sitzen (eingebettete
  Vimeo/YouTube-Player, Mediathek-Embeds).

### 1c. Service Worker (Background)

- **Tab-Registry**: Welche Tabs haben welche Videos in welchem Zustand. Quelle für die Liste
  in der Desktop-App.
- **`webRequest`-Beobachtung** (nur lesend): erkennt Manifeste (`.m3u8`, `.mpd`,
  Content-Types `application/vnd.apple.mpegurl`, `application/dash+xml`) und merkt sich
  Request-Header (Cookies, `Authorization`, `Referer`, `User-Agent`). Nötig für den
  Download-Modus (Manifest-Replay).
- **`chrome.tabCapture`** für den Modus „was ich sehe“.
- **Keep-Alive**: ein offener `runtime.Port` zum Content Script oder ein Offscreen-Document
  hält den Worker am Leben, solange eine Aufnahme läuft.
- **Native-Messaging-Host** zur Desktop-App (Steuerkanal).

### 1d. Popup / Badge

Minimal: Badge mit Anzahl erkannter Videos im aktuellen Tab, Klick öffnet die Desktop-App
(bzw. startet sie über Native Messaging). Die eigentliche UI liegt in der Desktop-App.

---

## Komponente 2: Transport Extension → Desktop

Zwei Kanäle, weil die Anforderungen gegensätzlich sind:

### Steuerkanal: Native Messaging

- Standard-Mechanismus für Extension ↔ natives Programm. Browser startet das registrierte
  Programm (Windows: Registry-Eintrag unter `HKCU\Software\Google\Chrome\NativeMessagingHosts\…`
  mit Pfad zu einer JSON-Manifestdatei) und spricht über stdin/stdout.
- Nachrichten sind JSON, **maximal 1 MB** pro Nachricht Richtung Host, 64 MB zurück.
- Ideal für: „Tab 5 hat neues Video“, „starte Aufnahme Modus C für Video X“, „Fortschritt
  42 %“, „fertig: Datei Y“.
- **Nicht** geeignet für Segmente (Base64-Overhead 33 %, 1-MB-Limit, JSON-Parsing).
- Bonus: Native Messaging kann die Desktop-App starten, wenn sie nicht läuft.

### Datenkanal: lokaler WebSocket-Server in der Desktop-App

- Desktop-App lauscht auf `127.0.0.1:<port>` (Port wird über den Steuerkanal mitgeteilt,
  zusammen mit einem Einmal-Token, damit keine andere lokale Seite/App sich verbinden kann).
- Content Script (oder Service Worker) verbindet sich per `WebSocket`, schickt pro Segment
  einen binären Frame mit kleinem Header (Tab-ID, SourceBuffer-ID, Sequenznummer, Flags) und
  den Rohdaten.
- Binär, kein Base64, kein Limit, Backpressure über `bufferedAmount`.
- Zu prüfen (Spike): ob die Seiten-CSP (`connect-src`) WebSocket-Verbindungen aus dem
  Content Script blockt. In Chromium gilt für Content Scripts die Extension-CSP, nicht die
  der Seite, mit Host-Permission `ws://127.0.0.1/*` sollte es gehen. Fallback: Daten per
  `runtime.Port` an den Service Worker und von dort per WebSocket (eine Kopie mehr, aber
  robust) oder ein Offscreen-Document als Relais.

### Alternative: alles über Native Messaging mit Chunking

Für einen ersten Spike reicht Base64 + 900-kB-Chunks über Native Messaging. Für 1080p
(~5–8 Mbit/s = ~1 MB/s) tragbar, für 4K nicht. Als Fallback behalten.

---

## Komponente 3: Desktop-App

### Aufgaben

- **Video-Liste**: live aktualisiert aus der Tab-Registry. Spalten: Tab/Seite, Titel,
  Dauer, Auflösung(en) gesehen, Format (fMP4/WebM/TS/progressiv), Status (spielt, pausiert,
  beendet), DRM-Flag, bereits mitgeschnittene Sekunden.
- **Modus-Wahl** pro Video mit Vorschau der Konsequenzen („Modus C: Qualität wie geladen,
  Video muss bis zum Ende laufen“).
- **Segment-Store**: Segmente werden sofort auf Platte gestreamt (eine Datei pro
  SourceBuffer, plus Index-Datei mit Offsets, Zeitstempeln, Init-Segment-Markern). Nie im
  RAM sammeln.
- **Muxer**: aus Segment-Store eine abspielbare Datei bauen (siehe nächster Abschnitt).
- **Downloader**: für Modus A und D (`yt-dlp` als Sidecar für bekannte Seiten, eigener
  Manifest-Replay für den Rest).
- **Live-Puffer**: Ringpuffer pro Video auf Platte, Größe konfigurierbar.
- **Einstellungen**: Ausgabeordner, Namensschema, Containerformat, Benachrichtigung bei
  Fertigstellung, maximale Parallelität, Qualitätsvorgabe für Hintergrund-Tabs.

### Benennung der Ausgabedatei

`{site}/{YYYY-MM-DD} {title} [{height}p].{ext}`, Titel bereinigt (Windows-verbotene Zeichen,
Länge). Metadaten (Quelle-URL, Datum, Seite) als Container-Tags (`-metadata comment=…`) und
zusätzlich als `.json`-Sidecar.

---

## Die Aufnahme-Modi im Detail

### Modus A: Download (ohne Ansehen)

Für Seiten, die `yt-dlp` kennt (YouTube, Vimeo, Twitch, ARD/ZDF, ORF, …), ist das der
schnellste und beste Weg. Die Extension liefert dazu nur die Seiten-URL und auf Wunsch die
Cookies (für eingeloggte Inhalte, `--cookies-from-browser` oder exportierte Cookie-Datei).

- Vorteile: beste Qualität, kein Abspielen nötig, bewährte Seitenlogik.
- Nachteile: abhängig von `yt-dlp`-Updates; unbekannte Seiten → Modus D.

### Modus B: Mitschneiden, was ich sehe (Tab-Capture)

Zwei Wege:

1. **In der Extension**: `chrome.tabCapture.capture()` liefert einen `MediaStream` von Bild
   und Ton des Tabs, `MediaRecorder` macht daraus WebM (VP8/VP9/AV1 + Opus). Die Datei
   wird in Chunks an die Desktop-App gestreamt. Funktioniert auch, wenn der Tab im
   Hintergrund ist (muss aber geöffnet bleiben; Chrome drosselt Hintergrund-Tabs beim
   Rendern, deshalb Auflösung/FPS fixieren).
2. **In der Desktop-App**: Fensterbereich per Windows Graphics Capture API + Audio per
   WASAPI-Loopback. Unabhängig vom Browser, fängt aber auch Mauszeiger, Overlays und
   Benachrichtigungen ein, und nur das, was sichtbar ist.

Weg 1 ist für dieses Projekt der bessere: sauberes Signal, Audio exakt dem Tab zugeordnet.

- Vorteile: funktioniert bei **allem**, was nicht DRM ist, auch WebRTC, Canvas, Flash-Nachfolger,
  egal wie exotisch der Player.
- Nachteile: **Re-Encode** (Qualitätsverlust, CPU-Last), Echtzeit (90 Minuten Film = 90
  Minuten Aufnahme), Pausen und Spulen landen in der Aufnahme.

### Modus C: Hintergrund-Mitschnitt (MSE-Hook)

Der eigentliche Grund für das Projekt.

1. Desktop-App bittet die Extension, die Video-URL in einem neuen Tab zu öffnen (optional in
   einem eigenen Browser-Fenster, minimiert, oder per `chrome.tabs.create({active: false})`).
2. Content Script setzt den Player auf: stumm (`video.muted = true`, nicht `volume = 0`, weil
   manche Player dann Audio-Segmente nicht laden), höchste verfügbare Qualität (seiten-
   spezifisch, siehe unten), Autoplay.
3. Jedes `appendBuffer` wird mitgeschnitten und sofort zur Desktop-App gestreamt.
4. Bei `endOfStream` oder `video.ended` → Muxer schließt ab, Tab wird geschlossen.

Beschleunigung: `video.playbackRate = 2…16` lässt den Player schneller Segmente nachladen
(der Puffer leert sich schneller). Viele Player erlauben bis 16×, manche kappen bei 2×.
Audio-Segmente werden dann trotzdem geladen (Player muss ja synchron bleiben). Alternative:
`currentTime` schrittweise vorspulen, sobald der Puffer voll ist (gezielt die nächste noch
nicht gepufferte Stelle anspringen). Beides führt zu Lücken, wenn man zu aggressiv ist →
Segment-Index prüfen und Lücken durch gezieltes Zurückspulen nachladen.

- Vorteile: **bit-exakte Qualität** (kein Re-Encode), läuft im Hintergrund, funktioniert bei
  allen MSE-Playern inklusive proprietärer Protokolle (YouTube SABR).
- Nachteile: Qualität ist die, die der Player geladen hat (ABR kann mitten im Video
  umschalten → Teile in anderer Auflösung); Video muss einmal „durchlaufen“; Werbung
  (SSAI, serverseitig eingefügt) landet im Stream.

### Modus D: Manifest-Replay (Download für unbekannte Seiten)

Hybrid aus A und C: Die Extension hat über `webRequest` das Manifest (HLS/DASH) und alle
Header gesehen. Die Desktop-App lädt daraus selbst alle Segmente der höchsten Qualität,
ohne dass etwas abgespielt wird.

- Benötigt: Manifest-URL, Cookies/Headers, ggf. signierte Segment-URLs mit Ablaufzeit (dann
  rechtzeitig laden oder Manifest neu holen).
- Praktisch das, was `yt-dlp`/`ffmpeg -i playlist.m3u8 -c copy out.mp4` tun, nur mit der
  echten Browser-Session.
- **Nicht** für Manifeste mit `#EXT-X-KEY` (außer `METHOD=NONE`) oder DASH
  `ContentProtection`-Elementen: dort bricht der Modus mit Hinweis ab (siehe Rechtliches).
- Funktioniert nicht bei proprietären Protokollen ohne Manifest (YouTube SABR) → dort Modus
  A oder C.

### Modus E: Live-Puffer (Rolling DVR)

Für Live-Streams (Twitch, Nachrichtensender, Konferenz-Streams): sobald ein Tab ein Live-Video
hat, hält die Desktop-App die letzten N Minuten Segmente auf Platte (Ringpuffer). Knopf
„letzte 10 Minuten sichern“ muxt den Ring in eine Datei. Fließt natürlich aus Modus C.

### Matrix: welcher Modus wofür

| Situation | Empfehlung |
|---|---|
| YouTube, Vimeo, Twitch-VOD, ARD/ZDF/ORF | A (yt-dlp) |
| Unbekannte Seite, HLS/DASH ohne Schlüssel | D, Fallback C |
| Proprietäres Protokoll, unbekannt | C |
| WebRTC, Canvas, Exoten | B |
| Live-Stream, „das war gerade gut“ | E |
| Vortrag mit Folien, nur ein Ausschnitt | B (mit Start/Stopp) |
| DRM (EME aktiv) | keiner, Anzeige „DRM“ |

---

## Muxing: aus Segmenten wieder eine Datei machen

### Fragmentiertes MP4 (der häufigste Fall)

Ein MSE-Stream aus fMP4 besteht aus:

- **Init-Segment**: `ftyp` + `moov` (Codec-Konfiguration, Track-Infos, keine Samples).
- **Media-Segmente**: je `moof` (Fragment-Header mit Zeitstempel `tfdt`, Sample-Tabelle `trun`)
  + `mdat` (die eigentlichen Frames).

Init-Segment gefolgt von allen Media-Segmenten in Reihenfolge ist bereits eine gültige
fMP4-Datei, die VLC/mpv/ffmpeg abspielen. Für maximale Kompatibilität (z. B. Windows-Player,
Schnittprogramme) danach einmal `ffmpeg -i in.mp4 -c copy -movflags +faststart out.mp4`:
das verlustfreie „Flachklopfen“ in ein normales MP4 mit einer Sample-Tabelle.

### Getrennte Spuren

DASH und YouTube liefern Audio und Video als getrennte SourceBuffer. Beide getrennt sammeln,
am Ende `ffmpeg -i video.mp4 -i audio.m4a -c copy out.mp4`. Zeitversatz über `tfdt` bzw.
`timestampOffset` ausgleichen (`-itsoffset`), falls nötig.

### WebM

Init-Segment = EBML-Header + `Segment`-Kopf + `Tracks`; Media-Segmente = `Cluster`. Gleiche
Logik: aneinanderhängen, dann `ffmpeg -c copy` für korrekte `Cues` (Suchindex) und Dauer.

### MPEG-TS (altes HLS)

`.ts`-Segmente sind selbst-beschreibend: einfach konkatenieren, danach
`ffmpeg -i all.ts -c copy out.mp4`. Bei Hooks sieht man TS allerdings selten direkt, weil
hls.js die TS-Segmente vor `appendBuffer` nach fMP4 transmuxt (also wieder Fall 1).

### Stolpersteine

- **Qualitätswechsel (ABR)**: Neues Init-Segment mitten im Stream (oft nach `changeType`).
  Zwei Strategien: (a) Datei in Teile splitten, jeder mit eigenem Init, dann mit ffmpeg
  `concat`-Demuxer zusammenfügen (geht ohne Re-Encode nur bei gleichem Codec-Profil;
  Auflösungswechsel innerhalb einer MP4-Spur tolerieren Player unterschiedlich gut); (b)
  Re-Encode auf einheitliche Auflösung (nur als Option). Besser vermeiden: in Modus C
  Qualität im Player fixieren.
- **Doppelte Segmente** (nach Spulen lädt der Player Bereiche erneut): Dedupe über
  `tfdt`-Zeitstempel bzw. Sequenznummer (`mfhd`), nicht über Byte-Gleichheit.
- **Lücken** (Spulen über nicht gepufferte Bereiche): Index zeigt die Lücke; in Modus C
  gezielt nachladen; sonst beim Muxen melden.
- **Diskontinuitäten durch Werbung (SSAI)**: Zeitstempel springen, oft eigenes Init-Segment.
  Erkennbar, optional ausschneiden.
- **`remove()`-Aufrufe** sagen nichts über Lücken aus (Player räumt nur Speicher), ignorieren.
- **Sehr lange Aufnahmen**: 64-Bit-Offsets in `tfdt` sind normal, nichts Besonderes, aber
  der Muxer darf nicht alles in den Speicher laden.

---

## Erkennung: welche Videos laufen gerade?

Mehrstufig, von sicher zu heuristisch:

1. **MSE-Hook hat Segmente gesehen** → sicher ein Video, Format bekannt.
2. **`<video>` mit `http(s)`-`src`** → progressives Video, URL bekannt.
3. **`webRequest` hat ein Manifest gesehen** → Video wird gleich geladen, auch wenn noch kein
   `<video>` existiert.
4. **`<video>`-Element ohne Quelle** oder mit `srcObject` (WebRTC) → als „Stream“ anzeigen,
   nur Modus B.
5. **EME-Aufrufe** → DRM-Flag, überschreibt alles.

Metadaten-Quellen für Titel/Dauer: `document.title`, `og:title`, `og:video`,
JSON-LD `VideoObject` (sehr verbreitet bei Mediatheken und News-Seiten), `video.duration`,
Player-spezifische DOM-Elemente (YouTube `ytd-watch-metadata h1`).

Safari-Sonderfall: Safari spielt HLS nativ, ohne MSE → der Hook sieht nichts, nur
`webRequest` sieht die Playlist. Für dieses Projekt erst mal außen vor (Windows-Fokus).

---

## Seiten-Spezifika

| Seite | Technik | Bemerkungen |
|---|---|---|
| **YouTube** | MSE, DASH-artig, zunehmend SABR/UMP (binäres Serverprotokoll). Audio/Video getrennt. WebM (VP9/AV1/Opus) oder MP4 (AVC/AAC). | Modus A (`yt-dlp`) ist hier deutlich einfacher. Modus C funktioniert, Qualitätsfixierung über Player-Menü oder URL-Parameter. Gekaufte/gemietete Filme sowie manche Musik-Inhalte sind DRM (Widevine). |
| **Twitch** | HLS (fMP4 oder TS), Live mit Low-Latency-Erweiterungen. | Modus E (Live-Puffer) ideal. VOD per A. |
| **Vimeo** | DASH (eigene JSON-Playlist), getrennte Spuren. | A oder C. Private Embeds brauchen Referer. |
| **ARD/ZDF/ORF/3sat/arte** | HLS, meist unverschlüsselt, mehrere Qualitäten, oft auch direkte MP4-Links. | A oder D. Geoblocking nur serverseitig. |
| **News-Seiten, Blogs** | Meist eingebettete Player (JW Player, Brightcove, Vimeo, YouTube) in iframes; HLS. | `all_frames`, dann D oder C. |
| **Vortrags-/Konferenz-Plattformen** | Bunt gemischt; oft progressiv oder HLS; manche WebRTC. | C/D, Fallback B. |
| **Netflix, Prime, Disney+, Sky, DAZN, Apple TV+** | DASH + CENC + Widevine/PlayReady/FairPlay. | **DRM, nicht unterstützt.** Siehe Bericht. |
| **Spotify, Deezer (Video/Audio)** | Widevine. | DRM. |

---

## Tech-Stack-Empfehlung

Passend zu den vorhandenen Stacks (Rust, Tauri, TypeScript):

- **Extension**: TypeScript, MV3, Build mit Vite/esbuild. Ein Paket für Chromium, eines für
  Firefox (Manifest-Unterschiede: `background.scripts` vs. `service_worker`,
  `browser_specific_settings`). Installation als „entpackte Erweiterung“ im Entwicklermodus
  reicht für den Eigenbedarf (Chrome blendet dann beim Start einen Hinweis ein; Firefox
  braucht Developer Edition/Nightly oder eine selbst signierte Version via AMO
  „unlisted“).
- **Desktop-App**: **Tauri 2** mit Rust-Backend. Rust-Seite: WebSocket-Server
  (`tokio-tungstenite`), Native-Messaging-Host (stdin/stdout, 4-Byte-Länge + JSON), Segment-
  Store, Prozess-Steuerung von ffmpeg/yt-dlp. Frontend: schlank, Tabelle + Buttons.
- **Muxing**: ffmpeg als Sidecar-Binary (Tauri `externalBin`). Später optional ein reiner
  Rust-Remuxer für fMP4 (Konkatenation + `tfdt`-Dedupe braucht kein ffmpeg, nur Box-Parsing;
  die `mp4`-Crate reicht dafür).
- **Downloads**: `yt-dlp` als Sidecar (automatisches Self-Update per `yt-dlp -U`), eigener
  HLS/DASH-Downloader in Rust für Modus D (`reqwest`, Manifest-Parser: `m3u8-rs`,
  `dash-mpd`).
- **Native-Messaging-Registrierung**: Installer/erster Start schreibt die Manifest-JSON und
  den Registry-Key (HKCU, kein Admin nötig). Extension-ID muss darin eingetragen sein (bei
  entpackten Extensions ist die ID vom Pfad abhängig → im Manifest einen festen `key` setzen,
  damit die ID stabil bleibt).

Alternativen, bewusst nicht gewählt: Electron (zu schwer für ein Hintergrund-Tool), reine
Extension mit `File System Access API` (kein ffmpeg, SW-Lebensdauer, kein Hintergrundbetrieb
ohne Browser), reines Desktop-Tool über CDP (siehe oben).

---

## Risiken und bekannte Stolpersteine

- **Service-Worker-Lebensdauer (MV3)**: Nach 30 s ohne Ereignis wird der Worker beendet,
  Verbindungen gehen verloren. Lösung: offener Port vom Content Script, Offscreen-Document
  mit Keep-Alive, oder möglichst wenig Zustand im Worker (Zustand in der Desktop-App).
- **Durchsatz und Kopien**: Pro Segment gibt es mindestens eine Kopie (`slice`), danach nur
  noch Transfers. 4K-Streams mit 20–40 Mbit/s sind machbar, wenn der Datenkanal binär ist.
- **Speicher im Tab**: Niemals Segmente im Content Script puffern; wenn die Desktop-App nicht
  erreichbar ist, Aufnahme sofort als „unterbrochen“ markieren statt zu sammeln.
- **Player, die den Hook bemerken**: Manche Player prüfen `appendBuffer.toString()` oder
  vergleichen Prototyp-Funktionen. Selten, bei unseren Zielseiten nicht bekannt. Falls es
  vorkommt: akzeptieren und Modus B nehmen; wir bauen keine Tarnung.
- **Hintergrund-Tab-Drosselung**: Chrome drosselt Timer in Hintergrund-Tabs (1/s), manche
  Player laden dann langsamer nach. Eigenes minimiertes Fenster statt Hintergrund-Tab hilft;
  `chrome.windows.create({focused: false, state: "minimized"})`.
- **Autoplay-Policy**: Ein neuer Tab ohne Nutzerinteraktion darf nicht mit Ton abspielen;
  stumm geht. Da wir Audio aus den Segmenten (nicht vom Lautsprecher) holen, ist das kein
  Problem.
- **Signierte, ablaufende Segment-URLs** (Modus D): Token-Lebensdauer beachten, Manifest
  rechtzeitig neu holen.
- **Werbung**: Clientseitige Werbung (eigener Player-Zustand) landet gar nicht im Stream;
  serverseitig eingefügte (SSAI) schon → Diskontinuitäten markieren, optional schneiden.
- **Browser-Updates**: Die gehookten APIs sind seit Jahren stabil (MSE ist W3C-Standard);
  das Risiko liegt eher bei Manifest-V3-Politik (z. B. Einschränkung von `webRequest`,
  bislang nur das blockierende, nicht das beobachtende).
- **Firefox**: `world: "MAIN"` ab 128, `tabCapture` fehlt (Modus B dort über
  `getDisplayMedia`), Native Messaging über eigenes Manifest-Verzeichnis.

---

## Umsetzungsplan in Phasen

### Spike 1: Beweis, dass der Hook funktioniert (1 Abend)

- Minimale MV3-Extension, Main-World-Script hookt `appendBuffer` und loggt pro Aufruf:
  MIME, Größe, erste 8 Bytes (Box-Typ), `tfdt`-Zeit.
- Test auf ARD-Mediathek (HLS via hls.js → fMP4) und YouTube (WebM, getrennte Spuren).
- Erfolg: Log zeigt Init-Segment gefolgt von Media-Segmenten mit monotonen Zeitstempeln.

### Spike 2: Segmente auf Platte, Datei abspielbar (1 Wochenende)

- Kleiner Rust-WebSocket-Server, der Frames in Dateien pro SourceBuffer schreibt.
- Content Script schiebt Segmente binär rüber.
- Nach `endOfStream`: `ffmpeg -c copy` → MP4. In mpv öffnen.
- Erfolg: komplettes Mediathek-Video in Originalqualität als Datei, Audio synchron.

### MVP: Modus C + Liste (2–3 Wochenenden)

- Tauri-App mit Video-Liste (aus Tab-Registry), Button „Hintergrund-Mitschnitt“.
- Native Messaging für Steuerung, WebSocket für Daten.
- Dedupe, Lückenerkennung, Qualitätsfixierung für 2–3 Seiten.
- DRM-Erkennung mit Anzeige.
- Dateibenennung, Ausgabeordner, Fertig-Benachrichtigung.

### v2: Download-Modi und Tab-Capture

- Modus A über `yt-dlp`-Sidecar mit Cookie-Übergabe.
- Modus D: Manifest-Replay für HLS/DASH ohne Schlüssel.
- Modus B über `tabCapture` + `MediaRecorder`.
- Modus E: Live-Ringpuffer.

### v3: Feinschliff

- Firefox-Unterstützung.
- Reiner Rust-Remuxer für fMP4 (ffmpeg nur noch für Flatten/Mux getrennter Spuren).
- ABR-Teile zusammenfügen, SSAI-Schnitt.
- Installer, der Extension-Hinweise und Native-Messaging-Registrierung erledigt.

---

## Rechtliches in Kürze

Hinweis: keine Rechtsberatung, nur Orientierung zum Weiterlesen.

- **Privatkopie**: Österreich § 42 UrhG, Deutschland § 53 UrhG. Kopien zum privaten Gebrauch
  sind grundsätzlich erlaubt, solange die Vorlage nicht offensichtlich rechtswidrig
  hergestellt oder öffentlich zugänglich gemacht wurde. Ein öffentlich-rechtlicher Mediathek-
  Stream oder ein frei abrufbares YouTube-Video ist eine legale Vorlage.
- **Technische Schutzmaßnahmen**: Österreich § 90c UrhG, Deutschland § 95a UrhG (beide aus
  der EU-Richtlinie 2001/29/EG Art. 6). Das Umgehen „wirksamer technischer Maßnahmen“ ist
  verboten, **auch für die Privatkopie**, und bereits das Herstellen/Verbreiten von
  Umgehungswerkzeugen ist untersagt. DRM (Widevine & Co.) fällt eindeutig darunter.
- **Grauzone**: HLS mit AES-128 und offen abrufbarem Schlüssel. Technisch trivial, aber
  Gerichte legen „wirksam“ großzügig aus (eine Maßnahme muss nicht unknackbar sein). Das
  Konzept zieht die Grenze konservativ: Modus D fasst verschlüsselte Manifeste nicht an.
  Modus C sieht den Klartext zwar passiv (der Player hat entschlüsselt), aber ob das
  „Umgehung“ ist, ist unklar → im Zweifel ebenfalls nicht speichern, mindestens aber als
  Option mit Warnhinweis ausgestalten.
- **Nutzungsbedingungen** (YouTube ToS verbietet Downloads außer über eigene Funktionen):
  Vertragsrecht, kein Strafrecht; Konsequenz wäre schlimmstenfalls Kontosperre. Für ein
  privates Werkzeug ohne Verbreitung ein überschaubares Risiko, aber bewusst sein.
- **Live-Mitschnitt vs. Download**: Rechtlich kein Unterschied (beides Vervielfältigung).

---

## Offene Fragen / Spikes

- [ ] WebSocket aus Content Script zu `127.0.0.1` trotz Seiten-CSP möglich? (Chromium und
      Firefox getrennt testen.)
- [ ] Wie verhält sich YouTube SABR im Hook: kommen saubere fMP4/WebM-Segmente in
      `appendBuffer` an, oder zerlegt der Player UMP-Pakete in Teilstücke? (Vermutlich
      sauber, aber messen.)
- [ ] `playbackRate`-Maximum pro Zielseite und ob Audio-Segmente dabei vollständig geladen
      werden.
- [ ] Qualitätsfixierung ohne UI-Klicks: YouTube (`yt.player`-API / localStorage-Key
      `yt-player-quality`), hls.js (`hls.currentLevel`, erreichbar über das Player-Objekt
      der Seite?), dash.js (`setQualityFor`).
- [ ] Minimiertes Fenster vs. Hintergrund-Tab: Ladegeschwindigkeit messen.
- [ ] Bento4 `mp4fragment`/`mp4split` oder reines Rust für den Remux?
- [ ] Wie groß darf der Live-Ringpuffer sinnvoll sein (Platte vs. Komfort)?
