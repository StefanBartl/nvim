# Handovers

Übergabe-Notizen zu laufender Arbeit an dieser Config und an den Plugins.

## Wo eine Handover-Datei hingehört

**Betrifft sie ein Plugin, gehört sie ins Buch, nicht hierher:**
`$REPOS_DIR/WKDBooks/Development/wkdbook-myplugins/<plugin>.nvim/NOTES/`.
Das Plugin-Repo selbst bekommt sie ebenfalls nicht — was *gebaut ist*, steht im
Repo; was *geplant, verworfen oder gemessen wurde*, steht im Buch.

Hier bleiben nur Handovers, deren Gegenstand diese Config selbst ist.

## Umgezogen

| War hier | Liegt jetzt |
| --- | --- |
| `media-nvim-and-hover-video.md`, `video-hover-playback.md`, `open-externally-and-sound.md` | `wkdbook-myplugins/media.nvim/NOTES/HANDOVER.md` — zu einem Dokument zusammengeführt (2026-09-08) |
| `media.nvim.md` | `wkdbook-myplugins/media.nvim/NOTES/HANDOVER.md` — war nach dem Zusammenführen oben erneut hier angelegt worden, jetzt eingearbeitet (2026-09-12) |
| `lsp-headless-root-detection-single-file-mode.md` | `wkdbook-myplugins/lsp.nvim/NOTES/HANDOVER-headless-root-detection.md` — Ursache gefunden und behoben, Notiz zog mit der Lösung um statt offen zu bleiben (2026-09-13) |

Die Roadmap von `media.nvim` ist bei derselben Gelegenheit aus dem Repo nach
`wkdbook-myplugins/media.nvim/ROADMAP/ROADMAP.md` gezogen — bewusste Abweichung
von `NEW-14`.
