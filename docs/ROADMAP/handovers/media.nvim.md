# media.nvim handover

## Offene Tests (musst du selbst machen)

Diese Liste ist die Übersicht: alles, was hier steht, konnte ich nicht
End-to-End auf dieser Maschine nachstellen (fehlende Software, fehlendes
Gerät o.ä.) und braucht deine Bestätigung. Erledigte Punkte bleiben
durchgestrichen stehen, damit die Historie nachvollziehbar bleibt — neue
Punkte kommen oben dazu.

- [ ] **VLC, `system_player_align` + `system_player_search_installs`**
  (Stand 2026-09-12): Mit
  ```lua
  video = {
    use_mpv = false,
    experimental = {
      system_player_align = true,
      system_player_prefer_classic = true,
      system_player_search_installs = true,
    },
  },
  ```
  sollte VLC jetzt (a) auch gefunden werden, wenn es nicht auf PATH liegt
  (Suche über `%ProgramFiles%\VideoLAN\VLC\vlc.exe` / `(x86)`-Pendant),
  (b) mit `--no-fullscreen` starten und (c) zentriert erscheinen. Liegt dein
  VLC an einem dritten Pfad, kurz Bescheid geben — dann wird die Pfadliste
  erweitert.

## Stand 2026-09-12

Alle drei offenen Punkte aus der vorigen Runde sind erledigt, committet und
gepusht (hover.nvim `69ede1f`, nvim-config `e62ceb2f`):

- **Config-Struktur** — genau wie im Feedback gewünscht: `system_player_align`
  und `system_player_prefer_classic` stehen jetzt nicht mehr flach in `video`,
  sondern unter `video.experimental` (echter Config-Key, nicht nur ein
  Kommentarblock). hover.nvim selbst wurde entsprechend umgebaut (DEFAULTS,
  Types, `config.preview_opts()`).

- **Neuer Bug, gemeldet während der Umstrukturierung:** mit
  `use_mpv = false` und `system_player_align = true` öffnete sich VLC trotzdem
  im Vollbildmodus — exakt das gleiche Verhalten wie `system_player_align =
  false`. Ursache: die Known-Player-Suche prüfte `vlc` nur über PATH
  (`vim.fn.executable("vlc")`), der Windows-VLC-Installer erweitert PATH aber
  nicht. Damit fiel die Suche immer durch und landete beim System-Handler mit
  seinem gemerkten Vollbild-Zustand.

  Fix: neue Einstellung `video.experimental.system_player_search_installs`
  (Default `true`, wirkt nur wenn `system_player_align = true`, analog zu
  `system_player_prefer_classic`). Wenn ein bekannter Player über PATH nicht
  gefunden wird, probiert `preview.external` jetzt zusätzlich die bekannten
  Windows-Installationspfade (`%ProgramFiles%\VideoLAN\VLC\vlc.exe` und das
  `(x86)`-Pendant) — genau das Muster, das `preview.shot` für die
  Browser-Suche schon verwendet.

Aktuelle Config (`lua/plugins/personal/init.lua`):

```lua
video = {
  use_mpv = false,
  experimental = {
    system_player_align = true,
    system_player_prefer_classic = true,
    system_player_search_installs = true,
  },
},
```

**Bitte nochmal testen:** Mit dieser Config sollte VLC jetzt (a) über den
Installationspfad gefunden werden, falls es nicht auf PATH liegt, (b) mit
`--no-fullscreen` starten und (c) zentriert erscheinen. 16 Tests in
`TESTS/external_spec.lua` sind grün (inkl. 2 neue für den Installationspfad-
Fund), Rest der Suite unverändert grün bis auf zwei vorbestehende,
umgebungsbedingte Fehlschläge in `zoom_spec.lua` (ImageMagick-Blob-Problem,
nichts mit dieser Änderung zu tun). Lint (luacheck + stylua) sauber in allen
drei Repos.

## Verlauf (vorige Runden, zur Referenz)

Drei Punkte waren offen: 1) Config-Struktur klarer machen, 2) das eigentliche
Problem — VLC startet im Vollbildmodus, Neupositionierung greift dann nicht,
3) `system_player_prefer_classic` als Fix dafür (bekannten, skriptbaren
Player zuerst versuchen, ohne Vollbild-Flag).

Zusätzlich wurde `align_win.lua` gefixt: ein maximiertes Fenster wird jetzt
vor dem Verschieben zurückgesetzt (`ShowWindow(SW_RESTORE)`) — vorher ein
stiller Nichts-Tuer gegen ein maximiertes Fenster.

Feedback zur Config-Struktur (umgesetzt, siehe oben):

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
