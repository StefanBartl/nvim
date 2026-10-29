# github_stats.nvim — Traffic-Digest-Kette, Live-Check (Stand 2026-10-29)

Die Digest-Integration (Plugin `github_stats.nvim`, App `docmap-desktop`, Browser-Modus in
`docmap.nvim`) lief noch nie gegen einen echten `:GithubStats fetch` auf deinen Maschinen. Dieser
Abschnitt deckt die **Plugin-Seite** der Kette ab: den Digest nach einem echten Fetch, seine
Auffindung durch die beiden Leser und das Zwei-Maschinen-Verhalten. Das Durchklicken der App-Oberfläche
steht im Abschnitt A3 von `docmap-desktop-live-tests-2026-10-02.md` und in dessen Block „Neue
Live-Checks (Stand 2026-10-29)“ und wird hier nicht wiederholt. **Beides in einer Sitzung mit
demselben Fetch.**

Task `github_stats.nvim/traffic-digest-e2e-check`. Code: `lua/github_stats/digest.lua`,
`background.lua` (ruft `digest.refresh_if_stale()` zu Beginn jedes Zyklus). Doku:
`docs/FEATURES/DIGEST.md`. Haken können hier und im A3-Block der docmap-desktop-Datei gesetzt werden
(dort steht dieselbe Siebener-Liste).

**Vorher:**

- Maschine A (mit Token) und, für Punkt 1, Maschine B mit synchronisiertem Datenordner.
- `github_stats.nvim` aktuell (Commit: ______), `docmap-desktop` installiert (Build: ______),
  `docmap.nvim` aktuell.
- `:checkhealth github_stats` ohne Fehler; `:GithubStats debug` für den Zustand.
- Ort der Dateien (laut `DIGEST.md`): `<default>/github_stats.nvim/root.json` mit `<default>` =
  `stdpath("data")`, die Digests als `<digest_dir>/digest/<owner_repo>.json`.

Erst einmal ein echter Fetch, damit überhaupt ein Digest existiert:

```vim
:GithubStats fetch
:GithubStats digest
```

- [ ] `<stdpath("data")>/github_stats.nvim/root.json` existiert, die Digest-Dateien liegen unter
      `digest/`, eine je Repo mit Daten

---

## Die sieben Punkte der Ende-zu-Ende-Prüfung

- [ ] **Zwei Maschinen.** Fetch auf A, Datenordner synchronisieren, Neovim auf B öffnen: der Digest
      von B wird beim Start neu aufgebaut (nicht veraltet), und B fetcht im Intervall nicht noch
      einmal (`:GithubStats debug` bzw. Zeitstempel der Dateien)
- [ ] **Plugin fehlt.** `github_stats.nvim` deaktivieren (Spec auskommentieren, Neovim neu): App und
      `docmap.nvim` verhalten sich wie vorher, kein Fehler, nichts leer gerendert
- [ ] **`ui.nvim` fehlt, Plugin da.** `ui.nvim` deaktivieren: die Sonde findet trotzdem
      `github_stats.digest`
- [ ] **Lazy-geladenes Plugin.** Plugin lazy konfiguriert, noch nicht geladen: `soft_require.probe`
      lädt es, kein User-Command nötig
- [ ] **Überschriebenes `digest_dir`.** In `setup()` (`opts.digest_dir`) einen anderen Ort setzen,
      `:GithubStats digest`: `root.json` am Standardort verweist darauf; App und Plugin finden den
      Digest ohne weitere Einstellung. (Laut `DIGEST.md` besser in `setup()` als in der
      synchronisierten `config.json`.)
- [ ] **Feindlicher Digest.** Fixture unter `digest/` mit `<img onerror=...>` als Referrer,
      `../../etc/passwd` und `C:\Windows` als Pfaden, einer 3-MiB-Datei und `schema: 99`: der Text ist
      inert, nichts außerhalb der Projektwurzel bekommt einen Link, die Datei wird mit Meldung
      abgelehnt. Fixture danach wieder löschen.
- [ ] **Privates Repo und Opt-out.** Ein in der App ausgeschlossenes Projekt zeigt nichts, und in
      **keinem exportierten Artefakt** (z. B. generierte Seite, `docs/map`, JSON) steht etwas davon
      (grep nach dem Repo-Namen und den Zahlen)

Offene Fragen: Die Task nennt für „Zwei Maschinen“ und „Feindlicher Digest“ keine genauen Befehle oder
Fixture-Dateien; wo die Fixture für den feindlichen Digest herkommt (liegt im Repo unter `TESTS/`?),
konnte ich aus der Task nicht ablesen. Den Pfad bitte ergänzen oder die Fixture selbst bauen.

## Falls rot

- [ ] Punkt, Befehl, Ausgabe von `:GithubStats debug`, Dateiname und Inhalt der betroffenen Datei
      (ohne Token) festhalten; `kind: bug` in der betroffenen Area (`github_stats.nvim`,
      `docmap-desktop` oder `docmap.nvim`) mit `refs:` auf die Zeile

## Danach

- [ ] Task `traffic-digest-e2e-check` mit `done` schließen; Ergebnis je Punkt in die Task-Notizen
- [ ] laut Task: die Handover-Datei `ALL/Backlog/FEATURES/github-stats-traffic-integration-handover.md`
      und die Statuszeile von `ROADMAP/IDEAS/GITHUB_STATS_CONCEPT.md` ein letztes Mal aktualisieren
      (das ist Dokumentationsarbeit nach dem Check, nicht Teil des Live-Checks)
