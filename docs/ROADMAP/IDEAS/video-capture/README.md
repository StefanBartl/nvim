# Video-Capture (Idee)

Ein Werkzeug, das Videos aus offenen Browser-Tabs erkennt und als Datei sichert:
Download, Mitschnitt „was ich sehe“, oder bit-genauer Hintergrund-Mitschnitt über einen
Hook auf `SourceBuffer.appendBuffer()` (Media Source Extensions). Gilt für alles ohne DRM;
DRM-Inhalte werden erkannt und nicht angefasst.

Angelegt: 2026-10-30 · Status: Spike 1 und 2 umgesetzt. Am 2026-10-31 im echten Chrome
auf der ARD-Mediathek bestätigt: Hook, Sink und Mux ergeben eine abspielbare MP4.
Repo: `github.com/WKDSteve/streamtap` (privat), lokal `$REPOS_DIR/streamtap`.
Plan, Tasks und Gate-Stand: `$REPOS_DIR/tasks-vault/streamtap/`.

## Dateien

| Datei | Inhalt |
|---|---|
| [01-konzept-video-capture.md](01-konzept-video-capture.md) | Zielbild, Architektur (Extension + Native Messaging/WebSocket + Tauri-Desktop-App), die Aufnahme-Modi A–E, Muxing von fMP4/WebM, Erkennung, Seiten-Spezifika, Tech-Stack, Risiken, Phasenplan, Rechtliches in Kürze, offene Spikes. |
| [02-drm-cdm-grundlagen.md](02-drm-cdm-grundlagen.md) | Lernunterlage zu DRM im Browser: warum es DRM gibt, Bedrohungsmodell, CENC, EME-Ablauf, CDM-Architektur, Lizenzserver/Policy, Widevine L1/L3 und PlayReady SL2000/SL3000, Secure Video Path/HDCP, Whitebox-Krypto, dokumentierte Brüche, Angriffsflächen konzeptionell, Rechtslage AT/DE/EU/US, legaler Hands-on-Lernpfad mit ClearKey, Glossar, Quellen. |

## Kürzeste Zusammenfassung

- TLS schützt nur den Transport; im Browser liegt das Video als Klartext-Segmente in MSE.
  Dort ansetzen → Extension mit Main-World-Hook, Daten binär an eine Desktop-App, die
  speichert und muxt.
- Empfohlener Einstieg: Spike 1 (Hook loggt Segmente auf einer Mediathek), Spike 2
  (Segmente auf Platte, `ffmpeg -c copy`, Datei spielt in mpv).
- DRM (Widevine/PlayReady/FairPlay) ist eine andere Welt: Schlüssel und Klartext bleiben
  im CDM bzw. in der Hardware, das Umgehen ist in AT (§ 90c UrhG) und DE (§ 95a UrhG)
  verboten. Das Tool zeigt DRM an und hört auf.
