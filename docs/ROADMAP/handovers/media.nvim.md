# media.nvim handover


## zuerste checken


**Punkt 3** — genau dein Vorschlag umgesetzt: neue Einstellung `video.system_player_prefer_classic` (Default `true`, wirkt nur wenn `system_player_align = true`). Bevor `preview.external` die System-Standard-App nimmt, probiert es jetzt eine kurze Liste bekannter, skriptbarer Player durch — aktuell nur `vlc --no-fullscreen`. Findet es VLC im PATH, startet es das direkt (kein Vollbild), sonst wie bisher der Systemstandard. Zusätzlich, unabhängig davon: das Ausrichtungs-Skript stellt ein maximiertes Fenster jetzt vor dem Verschieben zurück (`ShowWindow(SW_RESTORE)`) — vorher war das ein stiller Nichts-Tuer gegen ein maximiertes Fenster.

**Ehrliche Einschränkung:** Ich habe kein VLC auf dieser Maschine, konnte den eigentlichen Fix also nicht Ende-zu-Ende nachstellen — nur die Entscheidungslogik ist getestet (14 neue Tests, alle grün), nicht der echte VLC-Start. Bitte bei dir nochmal testen: mit `system_player_align=true` und `system_player_prefer_classic=true` (Default) sollte jetzt entweder VLC nicht-fullscreen + zentriert erscheinen, oder — falls `vlc` nicht im PATH ist — der bisherige Vollbild-Fallback.




---

## Letzte message von claude

```markdown
Drei Punkte, der Reihe nach. Erst schaue ich mir dein aktuelles Config-Layout an für Punkt 2.

Verstanden — drei Dinge: 1) Config-Struktur klarer machen (mach ich als letztes zusammen mit Punkt 3), 2) das eigentliche Problem: VLC startet im Vollbildmodus, Neupositionierung greift dann nicht. Ich baue die vorgeschlagene Zusatzschicht (bekannten Win32-Player direkt starten, ohne Vollbild) plus einen Fix im bestehenden Ausrichtungs-Skript (maximiertes/Vollbild-Fenster erst zurücksetzen, bevor verschoben wird).

Jetzt umbauen — bekannter Player zuerst (wenn Alignment gewünscht), sonst wie bisher:

Jetzt `M.open` selbst umbauen:

Jetzt `@types/init.lua` und `config/init.lua`:

Jetzt `config/init.lua`:

Jetzt align_win.lua fixen — Fenster vor dem Verschieben aus Maximiert/Fullscreen-Zustand zurückholen:

Jetzt Docs aktualisieren, dann deine Config sauber umstrukturieren (Punkt 2).

Jetzt deine Config aktualisieren — Punkt 2 (klare Gruppierung) und die neue Einstellung.

Jetzt committen und pushen.

Jetzt noch das WKDBooks-Handover aktualisieren.

Alle drei Repos sauber, gepusht. Zusammenfassung:

**Punkt 1** — `use_mpv = false` bestätigt funktionierend, nichts zu tun.

**Punkt 2** — Config umstrukturiert: `system_player_align` und die neue Einstellung stehen jetzt unter einem deutlich abgesetzten `-- EXPERIMENTAL --`-Block im `video`-Key, mit Kommentar, dass beide erst greifen, wenn kein mpv-Fenster läuft.

**Punkt 3** — genau dein Vorschlag umgesetzt: neue Einstellung `video.system_player_prefer_classic` (Default `true`, wirkt nur wenn `system_player_align = true`). Bevor `preview.external` die System-Standard-App nimmt, probiert es jetzt eine kurze Liste bekannter, skriptbarer Player durch — aktuell nur `vlc --no-fullscreen`. Findet es VLC im PATH, startet es das direkt (kein Vollbild), sonst wie bisher der Systemstandard. Zusätzlich, unabhängig davon: das Ausrichtungs-Skript stellt ein maximiertes Fenster jetzt vor dem Verschieben zurück (`ShowWindow(SW_RESTORE)`) — vorher war das ein stiller Nichts-Tuer gegen ein maximiertes Fenster.

**Ehrliche Einschränkung:** Ich habe kein VLC auf dieser Maschine, konnte den eigentlichen Fix also nicht Ende-zu-Ende nachstellen — nur die Entscheidungslogik ist getestet (14 neue Tests, alle grün), nicht der echte VLC-Start. Bitte bei dir nochmal testen: mit `system_player_align=true` und `system_player_prefer_classic=true` (Default) sollte jetzt entweder VLC nicht-fullscreen + zentriert erscheinen, oder — falls `vlc` nicht im PATH ist — der bisherige Vollbild-Fallback.

Alle Tests grün, Lint sauber, Config syntaktisch geprüft.
```

## Mein feedback

```
nicht so;
video = {
          use_mpv = false,
          system_player_align = true,
          system_player_prefer_classic = true,
        },

sondern so:

        video = {
          use_mpv = false,
          experimental = {
            system_player_align = true,
            system_player_prefer_classic = true,
          },
        },
```
